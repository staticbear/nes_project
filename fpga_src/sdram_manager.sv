module sdram_manager(
							sysclk,			
							reset,
							//
							ldr_req,
							ldr_ack,
							ldr_lh, 		//0 -low/1 - hight
							ldr_addr,
							ldr_data_in,
							//
							cpu_addr,
							cpu_data_in,
							cpu_data_out,
							cpu_wr,
							//
							ppu_addr,
							ppu_data_in,
							ppu_data_out,
							ppu_wr,
							//request fifo
							rq_fifo_empty,
							rq_fifo_data,
							rq_fifo_wrreq,
							//answer fifo
							an_fifo_empty,
							an_fifo_rdreq,
							an_fifo_q
							);
input		sysclk;			
input		reset;
//
input		ldr_req;
output	ldr_ack;
input    ldr_lh;
input		[24:0]ldr_addr;
input		[7:0]ldr_data_in;
//
input		[24:0]cpu_addr;
input		[7:0]cpu_data_in;
output	[7:0]cpu_data_out;
input		cpu_wr;
//
input		[24:0]ppu_addr;
input		[7:0]ppu_data_in;
output	[7:0]ppu_data_out;
input		ppu_wr;
//request fifo
input		rq_fifo_empty;
output	[35:0]rq_fifo_data;
output	rq_fifo_wrreq;
//answer fifo
input		an_fifo_empty;
output	an_fifo_rdreq;
input		[8:0]an_fifo_q;

assign	ldr_ack	=	(sm == SM_LDR_REQ);

//--------------------------------------------------------------------------------latch cpu data
reg		[24:0]sv_cpu_addr;
always@(posedge sysclk)sv_cpu_addr<=cpu_addr;

reg		[7:0]sv_cpu_data_in;
always@(posedge sysclk)sv_cpu_data_in<=cpu_data_in;

reg		sv_cpu_wr;
always@(posedge sysclk)sv_cpu_wr<=cpu_wr;

//--------------------------------------------------------------------------------latch ppu data
reg		[24:0]sv_ppu_addr;
always@(posedge sysclk)sv_ppu_addr<=ppu_addr;

reg		[7:0]sv_ppu_data_in;
always@(posedge sysclk)sv_ppu_data_in<=ppu_data_in;

reg		sv_ppu_wr;
always@(posedge sysclk)sv_ppu_wr<=ppu_wr;

//--------------------------------------------------------------------------------
parameter	SM_WTFREE_A	=	3'd0;
parameter	SM_PPU_REQ	=	3'd1;
parameter	SM_WTFREE_B	=	3'd2;
parameter	SM_RFR_REQ	=	3'd3;
parameter	SM_CPU_REQ	=	3'd4;
parameter	SM_LDR_REQ	=	3'd5;
reg		[2:0]sm;
always@(posedge sysclk or negedge reset)begin
	if(!reset)sm<=SM_WTFREE_A;
	else begin
		case(sm)
			SM_WTFREE_A:if(rq_fifo_empty)	sm<=SM_PPU_REQ;
			SM_PPU_REQ:							sm<=SM_WTFREE_B;
			SM_WTFREE_B:begin
				if(rq_fifo_empty)begin
					if(refr_select)			sm<=SM_RFR_REQ;
					else if(ldr_req)			sm<=SM_LDR_REQ;
					else							sm<=SM_CPU_REQ;
				end
			end
			SM_RFR_REQ,	
			SM_CPU_REQ,
			SM_LDR_REQ:							sm<=SM_WTFREE_A;
		endcase
	end
end

//--------------------------------------------------------------------------------
reg	refr_select;
always@(posedge sysclk)begin
	if(sm == SM_RFR_REQ || sm == SM_CPU_REQ || sm == SM_LDR_REQ)refr_select<=~refr_select;
end

//--------------------------------------------------------------------------------
//make request
//cmd explanation : 00 - refresh,01 - read,02 - write		
wire		[1:0]ppu_rw;
wire		[1:0]cpu_rw;

assign	ppu_rw			=	(sv_ppu_wr) ? 2'd02 : 2'd01;
assign	cpu_rw			=	(sv_cpu_wr) ? 2'd02 : 2'd01;

//																 mask          cmd		addr				data
assign	rq_fifo_data	=	(sm == SM_PPU_REQ) ? {1'b1 	  , ppu_rw , sv_ppu_addr , sv_ppu_data_in} :
									(sm == SM_CPU_REQ) ? {1'b0 	  , cpu_rw , sv_cpu_addr , sv_cpu_data_in} :
									(sm == SM_LDR_REQ) ? {ldr_lh 	  , 2'd02  , ldr_addr 	 , ldr_data_in} :
																{1'b0 	  , 2'd00  , 25'h0 		 , 8'h0};       //refresh
																													  
assign	rq_fifo_wrreq	=	( sm == SM_PPU_REQ || sm == SM_CPU_REQ || sm == SM_LDR_REQ || sm == SM_RFR_REQ );

//--------------------------------------------------------------------------------
//treatment answer	
assign		an_fifo_rdreq	= ~an_fifo_empty;

reg	[7:0]cpu_data_out;
always@(posedge sysclk)if(~an_fifo_q[8])cpu_data_out<=an_fifo_q[7:0];		

reg	[7:0]ppu_data_out;
always@(posedge sysclk)if(an_fifo_q[8])ppu_data_out<=an_fifo_q[7:0];	
					  
endmodule