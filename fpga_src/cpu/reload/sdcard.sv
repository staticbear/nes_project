
module	sdcard(
				sysclk,			//100MHz
				reset,
				//status
				busy,
				error,
				//parameters & command
				rw_addr,
				read_pulse,
				write_pulse,
				//sync fifo 
				data,
				wrreq,
				//sync fifo
				rdreq,
				q,
				//physical
				cs,
				sclk,
				mosi,
				miso
				);
				
input		sysclk;
input		reset;
//status
output	busy;
output	error;
//parameters & command
input		[31:0]rw_addr;
input		read_pulse;
input		write_pulse;
//sync fifo 
output	[7:0]data;
output	wrreq;
//sync fifo
output	rdreq;
input		[7:0]q;
//physical
output	cs;
output	sclk;		//100kHz
output	mosi;
input		miso;

//------------------------------------------------------------------------------
assign	cs 		= ( sm == SM_SET_SPI_MODE || sm	==	SM_ERROR	||	sm == SM_WTACTION ) ? 1'b1 : 1'b0;
							
assign	mosi		= ( sm == SM_WRITE_TOKEN || sm == SM_WRITE_DATA ) ?  spi_wr_data[8] : spi_reg_cmd[48];


assign	error		=	(sm == SM_ERROR);
assign	busy		=	(sm != SM_WTACTION);

assign	rdreq		=	(sm == SM_WRITE_DATA && ~|spi_rbit_cnt);
//------------------------------------------------------------------------------
parameter	div_size = 8;
parameter	div_val  = 250;


//spi clock
reg	[div_size:0]div_spi;
always@(posedge sysclk)begin
	if(~|div_spi)	div_spi<=div_val;
	else				div_spi<=div_spi-1'd1;
end

wire		base_clock;
assign	base_clock 	= ~|div_spi;				//pulse
wire		chg_clock;
assign	chg_clock	=	base_clock && sclk;  //negedge
wire		act_clock;
assign	act_clock	=	base_clock && ~sclk;	//posedge


reg		sclk;
always@(posedge sysclk)begin
	if(cs && sm != SM_SET_SPI_MODE)sclk<=0;
	else if(~|div_spi)sclk<=~sclk;
end
//------------------------------------------------------------------------------
parameter 	SM_SET_SPI_MODE	=	4'd0;	
parameter 	SM_RESET_REQ		=	4'd1;
parameter 	SM_RESET_ANS		=	4'd2;
parameter 	SM_INIT_REQ			=	4'd3;
parameter 	SM_INIT_ANS			=	4'd4;
parameter	SM_ERROR				=	4'd5;
parameter	SM_WTACTION			=	4'd6;
parameter	SM_READ_REQ			=	4'd7;
parameter	SM_READ_ANS			=	4'd8;
parameter	SM_READ_TOKEN		=	4'd9;
parameter	SM_READ_DATA		=	4'd10;
parameter	SM_WRITE_REQ		=	4'd11;
parameter	SM_WRITE_ANS		=	4'd12;
parameter	SM_WRITE_TOKEN		=	4'd13;
parameter	SM_WRITE_DATA		=	4'd14;
parameter	SM_WRITE_CHECK		=	4'd15;

reg		[3:0]sm;
always@(posedge sysclk or negedge reset)begin
	if(!reset)sm<=SM_SET_SPI_MODE;
	else begin
		case(sm)
			SM_SET_SPI_MODE:	if(~|spi_set_cnt)	sm<=SM_RESET_REQ;
			SM_RESET_REQ:								sm<=SM_RESET_ANS;
			SM_RESET_ANS:begin
				if(~spi_rd_data[7])begin
					if(|spi_rd_data[6:1])			sm<=SM_ERROR;
					else 									sm<=SM_INIT_REQ;
				end
			end
			SM_INIT_REQ:if(&spi_rd_data)			sm<=SM_INIT_ANS;
			SM_INIT_ANS:begin
				if(~spi_rd_data[7])begin
					if(~spi_rd_data[0] || spi_rd_data[2])sm<=SM_WTACTION;
					else 											 sm<=SM_INIT_REQ;
				end
			end
			SM_WTACTION:begin
				if(read_pulse)							sm<=SM_READ_REQ;
				else if(write_pulse)					sm<=SM_WRITE_REQ;
			end
			SM_READ_REQ:if(&spi_rd_data)			sm<=SM_READ_ANS;
			SM_READ_ANS:begin
				if(~spi_rd_data[7])begin
					if(|spi_rd_data[6:0])			sm<=SM_ERROR;
					else 									sm<=SM_READ_TOKEN;
				end
			end
			SM_READ_TOKEN:begin
				if(spi_rd_data == 8'b11111110)	sm<=SM_READ_DATA;
			end
			SM_READ_DATA:begin	
				if(spi_rbyte_cnt[9] && spi_rbyte_cnt[1])sm<=SM_WTACTION;
			end
			SM_WRITE_REQ:if(&spi_rd_data)			sm<=SM_WRITE_ANS;
			SM_WRITE_ANS:begin
				if(~spi_rd_data[7])begin
					if(|spi_rd_data[6:0])			sm<=SM_ERROR;
					else 									sm<=SM_WRITE_TOKEN;
				end
			end
			SM_WRITE_TOKEN:							sm<=SM_WRITE_DATA;
			SM_WRITE_DATA:begin
				if(spi_rbyte_cnt[9] && spi_rbyte_cnt[1])sm<=SM_WRITE_CHECK;
			end
			SM_WRITE_CHECK:begin
				if(~spi_rd_data[4])begin
					if(spi_rd_data[3:0] == 4'b0101)	sm<=SM_WTACTION;
					else 										sm<=SM_ERROR;
				end
			end
		endcase
	end
end
//------------------------------------------------------------------------------
reg	[9:0]pup_cnt;
always@(posedge sysclk or negedge reset)begin
	if(!reset)pup_cnt<=10'd1000;
	else if(base_clock && |pup_cnt)pup_cnt<=pup_cnt-1'd1;
end
//------------------------------------------------------------------------------
reg	[6:0]spi_set_cnt;
always@(posedge sysclk or negedge reset)begin
	if(!reset)spi_set_cnt<=7'd127;
	else if(act_clock)begin
		if(sm == SM_SET_SPI_MODE && ~|pup_cnt)spi_set_cnt<=spi_set_cnt-1'd1;
	end
end
//------------------------------------------------------------------------------
reg	[48:0]spi_reg_cmd;
always@(posedge sysclk or negedge reset)begin
	if(!reset)spi_reg_cmd<=49'h1FFFFFFFFFFFF;
	else begin
		if(sm == SM_RESET_REQ)								spi_reg_cmd<=49'h1_40_00000000_95;
		else if(sm == SM_INIT_REQ)							spi_reg_cmd<=49'h1_41_00000000_00;
		else if(sm == SM_READ_REQ)							spi_reg_cmd<={9'h1_51,rw_addr,8'h00};//49'h1_51_00000000_00;
		else if(sm == SM_WRITE_REQ)						spi_reg_cmd<={9'h1_58,rw_addr,8'h00};//49'h1_58_00000000_00;
		else if(chg_clock)									spi_reg_cmd<={spi_reg_cmd[47:0],1'b1};
	end
end

reg	[8:0]spi_wr_data;
always@(posedge sysclk or negedge reset)begin
	if(!reset)spi_wr_data<=9'h1FF;
	else begin
		if(sm == SM_WRITE_TOKEN)							spi_wr_data<=9'h1FE;
		else if(chg_clock)begin
			if(&spi_rbit_cnt)									spi_wr_data<={spi_wr_data[7],q};
			else													spi_wr_data<={spi_wr_data[7:0],1'b1};
		end
	end
end
//------------------------------------------------------------------------------
reg		[7:0]spi_rd_data;
always@(posedge sysclk)begin
	if(act_clock)spi_rd_data<={spi_rd_data[6:0],miso};
end
//------------------------------------------------------------------------------
reg		[2:0]spi_rbit_cnt;
always@(posedge sysclk)begin
	if(act_clock)begin
		if(sm!=SM_READ_DATA && sm != SM_WRITE_TOKEN && sm != SM_WRITE_DATA)spi_rbit_cnt<=0;
		else spi_rbit_cnt<=spi_rbit_cnt+1'd1;
	end
end
//------------------------------------------------------------------------------
reg		[9:0]spi_rbyte_cnt;
always@(posedge sysclk)begin
	if(act_clock)begin
		if(sm!=SM_READ_DATA && sm != SM_WRITE_TOKEN && sm != SM_WRITE_DATA)spi_rbyte_cnt<=0;
		else if(&spi_rbit_cnt)spi_rbyte_cnt<=spi_rbyte_cnt+1'd1;
	end
end
//------------------------------------------------------------------------------
assign	data = spi_rd_data;
reg		wrreq;
always@(posedge sysclk)wrreq<=(act_clock && sm==SM_READ_DATA && &spi_rbit_cnt && ~spi_rbyte_cnt[9]);

endmodule

