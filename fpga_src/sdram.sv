module sdram(
					sysclk,			//100MHz
					delay_clock,	//1MHz
					reset,	
					//request fifo
					rq_fifo_empty,
					rq_fifo_rdreq,
					rq_fifo_q,
					//answer fifo
					an_fifo_data,
					an_fifo_wrreq,
					//sdram_interface
					sdram_addr,
					sdram_dq,
					sdram_ba,
					sdram_ldqm,
					sdram_udqm,
					sdram_ras_n,
					sdram_cas_n,
					sdram_cke,
					sdram_we_n,
					sdram_cs_n
             );
				 
input 	sysclk;
input		delay_clock;
input 	reset;
//request fifo
input		rq_fifo_empty;
output	rq_fifo_rdreq;
input		[35:0]rq_fifo_q;
//answer fifo
output	[8:0]an_fifo_data;
output	an_fifo_wrreq;
//sdram_interface
output 	[12:0]sdram_addr;
inout  	[15:0]sdram_dq;
output 	[1:0]sdram_ba;
output 	sdram_ldqm;
output 	sdram_udqm;
output 	sdram_ras_n;
output 	sdram_cas_n;
output 	sdram_cke;
output 	sdram_we_n;
output 	sdram_cs_n;


assign	an_fifo_data 	=  sv_select_lh ? {1'b1,sdram_dq[15:8]} : {1'b0,sdram_dq[7:0]};
reg		an_fifo_wrreq;
always@(negedge sysclk)an_fifo_wrreq<=~|tcas_cnt;

wire		[15:0]dq_wr;
assign	dq_wr				=	sv_select_lh ? {port_data,8'h00} : {8'h00,port_data};
assign	sdram_dq 		= 	(sm == SM_WRITE) ?  dq_wr :	16'hZZZZ;

assign	{sdram_udqm,sdram_ldqm}	=	{~sv_select_lh,sv_select_lh};
assign	sdram_cke		=	1'b1;
assign	sdram_cs_n		=	1'b0;


parameter Tref       	= 6'd55;
parameter Tpowerup   	= 8'd200;
parameter Trp        	= 2'd2;
parameter Trc        	= 4'd8;
parameter Trcd				= 3'd4;
parameter Tmrd      	 	= 2'd2;
parameter Tcas       	= 2'd2;
parameter Tdpl       	= 2'd2;
//----------------------------------------------------------------------------
wire		select_lh		   =	rq_fifo_q[35];					   //select low or hight of 16 bit data
wire		[1:0]port_cmd		=	rq_fifo_q[34:33];					//00 - refresh,01 - read,02 - write
wire		[24:0]port_addr	=	rq_fifo_q[32:8];
wire		[7:0]port_data	   =	rq_fifo_q[7:0];

wire 		[9:0]col_addr 		= port_addr[9:0];
wire 		[12:0]row_addr 	= port_addr[22:10];
wire 		[1:0]bank_addr 	= port_addr[24:23];

reg		sv_select_lh;
always@(negedge sysclk)if(sm == SM_ACTION)sv_select_lh<=select_lh;


assign	rq_fifo_rdreq = ~rq_fifo_empty && (sm == SM_READ && tcas_cnt==Tcas) || 
														 (sm == SM_WRITE && twr_cnt==(Tdpl+Trp)-1'd1) || 
														 (sm == SM_AUTOREFRESH && ~|st_refr_cnt && trc_cnt==Trc-3'd5);

//----------------------------------------------------------------------------
parameter SM_POWERON			  = 3'd0;
parameter SM_PRECHARGE       = 3'd1;
parameter SM_LOADMODE        = 3'd2;
parameter SM_AUTOREFRESH	  = 3'd3;
parameter SM_ACTION          = 3'd4;
parameter SM_WRITE           = 3'd5;
parameter SM_READ            = 3'd6;

reg [2:0]sm;
always@(negedge sysclk or negedge reset)begin
	if(!reset)sm<=SM_POWERON;
	else begin
		case(sm)
			SM_POWERON:			if(~|pw_up_delay)	sm<=SM_PRECHARGE;
			SM_PRECHARGE:		if(~|trp_cnt)		sm<=SM_LOADMODE;
			SM_LOADMODE:		if(~|tmrd_cnt)		sm<=SM_AUTOREFRESH;
			SM_AUTOREFRESH:begin
				if(~|trc_cnt && ~|st_refr_cnt)	sm<=SM_ACTION;
			end
			SM_ACTION:begin
				if(~|trcd_cnt)begin
					if(port_cmd[1])				   sm<=SM_WRITE;
					else 									sm<=SM_READ;
				end
			end
			SM_WRITE:begin
				if(~|twr_cnt)begin
					if(~|port_cmd)						sm<=SM_AUTOREFRESH;
					else 									sm<=SM_ACTION;
				end
			end
			SM_READ:begin
				if(~|tcas_cnt)begin
					if(~|port_cmd)						sm<=SM_AUTOREFRESH;
					else 									sm<=SM_ACTION;
				end
			end
		endcase
	end
end
//----------------------------------------------------------------------------
reg		[7:0]pw_up_delay;
always@(negedge sysclk or negedge reset)begin
	if(!reset)pw_up_delay<=Tpowerup-1'd1;
	else if(delay_clock)pw_up_delay<=pw_up_delay-1'd1;
end
//----------------------------------------------------------------------------
reg 		[1:0]trp_cnt;
always@(negedge sysclk)begin
   if(sm == SM_PRECHARGE)trp_cnt<=trp_cnt-1'd1;
   else trp_cnt<=Trp-1'd1;
end
//----------------------------------------------------------------------------
reg 		[1:0]tmrd_cnt;
always@(negedge sysclk)begin
   if(sm == SM_LOADMODE)tmrd_cnt<=tmrd_cnt-1'd1;
   else tmrd_cnt<=Tmrd-1'd1;
end
//----------------------------------------------------------------------------
reg 		[3:0]trc_cnt;
always@(negedge sysclk)begin
   if(sm == SM_AUTOREFRESH)trc_cnt<=trc_cnt-1'd1;
   else trc_cnt<=Trc-1'd1;
end
//----------------------------------------------------------------------------
reg 		[2:0]st_refr_cnt;										
always@(negedge sysclk or negedge reset)begin
	if(!reset)st_refr_cnt<=3'd7;
   else if(~|trc_cnt && |st_refr_cnt)st_refr_cnt<=st_refr_cnt-1'd1;
end
//----------------------------------------------------------------------------
reg 		[2:0]trcd_cnt;
always@(negedge sysclk)begin
	if(sm == SM_ACTION)trcd_cnt<=trcd_cnt-1'd1;
   else trcd_cnt<=Trcd-1'd1;
end

//----------------------------------------------------------------------------
reg 		[2:0]twr_cnt;
always@(negedge sysclk)begin
	if(sm == SM_WRITE)twr_cnt<=twr_cnt-1'd1;
   else twr_cnt<=(Tdpl+Trp)-1'd1;
end

//----------------------------------------------------------------------------
reg 		[1:0]tcas_cnt;
always@(negedge sysclk)begin
	if(sm == SM_READ)tcas_cnt<=tcas_cnt-1'd1;
   else tcas_cnt<=Tcas;
end
//----------------------------------------------------------------------------
										//   ras/cas/we
parameter	CMD_PRECHARGE		=	3'b010;
parameter	CMD_AUTOREFRESH	=	3'b001;
parameter   CMD_LOADMODE		=	3'b000;
parameter   CMD_ACTION			=	3'b011;
parameter   CMD_READ				=	3'b101;
parameter   CMD_WRITE			=	3'b100;
parameter   CMD_NOP				=	3'b111;


assign	{sdram_ras_n,sdram_cas_n,sdram_we_n}  =   (sm == SM_PRECHARGE && trp_cnt==Trp-1'd1) ? CMD_PRECHARGE :
																	(sm == SM_AUTOREFRESH && trc_cnt==Trc-1'd1) ? CMD_AUTOREFRESH :
																	(sm == SM_LOADMODE && tmrd_cnt==Tmrd-1'd1) ? CMD_LOADMODE :
																	(sm == SM_ACTION && trcd_cnt==Trcd-1'd1) ? CMD_ACTION :
																	(sm == SM_READ && tcas_cnt==Tcas) ? CMD_READ :
																	(sm == SM_WRITE && twr_cnt==(Tdpl+Trp)-1'd1) ? CMD_WRITE : CMD_NOP;
																	
assign	sdram_ba 			= 	(sm == SM_LOADMODE)	? 2'b00 : bank_addr;

assign	sdram_addr[10]		=	(sm == SM_ACTION)		? row_addr[10] : 
										(sm == SM_LOADMODE) 	? 1'b0 : 1'b1;

assign	sdram_addr[12:11]	=  (sm == SM_ACTION)	   ? row_addr[12:11] : 2'b00;
	
assign	sdram_addr[9:0]	=	(sm == SM_LOADMODE)	? 10'b1000100000 : 
										(sm == SM_ACTION)		? row_addr[9:0] : col_addr;

endmodule
