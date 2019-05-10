module dump_loader(
							sysclk,
							delay_clock,
							reset,
							//
							gen_reset,
							//
							load_dump,
							dump_offset,
							dump_prg_len,
							dump_chr_len,
							//sdcard control
							busy,
							error,
							rw_addr,
							read_pulse,
							empty,
							rdreq,
							q,
							//sdram manager
							ldr_req,
							ldr_ack,
							ldr_lh,
							ldr_addr,
							ldr_data
						);
						
input		sysclk;
input		delay_clock;
input		reset;
//
output	gen_reset;
//
input		load_dump;
input		[31:0]dump_offset;
input		[15:0]dump_prg_len;
input		[15:0]dump_chr_len;
//sdcard control
input		busy;
input		error;
output	[31:0]rw_addr;
output	read_pulse;
input		empty;
output	rdreq;
input		[7:0]q;
//sdram manager
output	ldr_req;
input		ldr_ack;
output	ldr_lh;
output	[24:0]ldr_addr;
output	[7:0]ldr_data;


assign	read_pulse	=	(sm == SM_PRG_RDPULSE || sm == SM_CHR_RDPULSE);
assign	gen_reset	=	(sm == SM_IDLE);
assign	rdreq			=	(sm == SM_LDR_DTREQ);
assign	ldr_req		=	(sm == SM_LDR_REQ);
assign	ldr_data		=	q;

parameter	SM_LOGO_DELAY 		= 4'd0;

parameter	SM_CHECK_PRGLEN 	= 4'd1;
parameter	SM_PRG_RDPULSE		= 4'd2;	//read from sdcard
parameter	SM_PRG_RDWAIT		= 4'd3;

parameter	SM_CHECK_CHRLEN 	= 4'd4;
parameter	SM_CHR_RDPULSE		= 4'd5;	//read from sdcard
parameter	SM_CHR_RDWAIT		= 4'd6;

parameter	SM_LDR_CHECK		= 4'd7;
parameter	SM_LDR_DTREQ		= 4'd8;
parameter	SM_LDR_REQ			= 4'd9;	//wrire into sdram
parameter	SM_IDLE				= 4'd10;
parameter	SM_ERROR				= 4'd11;
reg		[3:0]sm;
always@(posedge sysclk or negedge reset)begin
	if(!reset)sm<=SM_LOGO_DELAY;
	else begin
		case(sm)
			SM_LOGO_DELAY:begin
				if(~|dump_prg_len )						sm<=SM_ERROR;
				else if(~|logo_delay)					sm<=SM_CHECK_PRGLEN;
			end
			SM_CHECK_PRGLEN:begin
				if(~|prg_len)								sm<=SM_CHECK_CHRLEN;
				else 											sm<=SM_PRG_RDPULSE;
			end
			SM_PRG_RDPULSE:								sm<=SM_PRG_RDWAIT;
			SM_PRG_RDWAIT:begin
				if(error)									sm<=SM_ERROR;
				else if(~busy && old_busy)				sm<=SM_LDR_CHECK;
			end
			//
			SM_LDR_CHECK:begin
				if(empty)begin
					if(~ldr_lh)								sm<=SM_CHECK_PRGLEN;
					else 										sm<=SM_CHECK_CHRLEN;
				end
				else 											sm<=SM_LDR_DTREQ;
			end
			SM_LDR_DTREQ:									sm<=SM_LDR_REQ;
			SM_LDR_REQ:begin
				if(ldr_ack)									sm<=SM_LDR_CHECK;
			end
			//
			SM_CHECK_CHRLEN:begin
				if(~|chr_len)								sm<=SM_IDLE;
				else 											sm<=SM_CHR_RDPULSE;
			end
			SM_CHR_RDPULSE:								sm<=SM_CHR_RDWAIT;
			SM_CHR_RDWAIT:begin
				if(error)									sm<=SM_ERROR;
				else if(~busy && old_busy)				sm<=SM_LDR_CHECK;
			end
			SM_IDLE:if(load_dump)						sm<=SM_CHECK_PRGLEN;
		endcase
	end
end
//--------------------------------------------------------------------------------
reg		[22:0]logo_delay;
always@(posedge sysclk or negedge reset)begin
	if(!reset)logo_delay<=23'd5000000;				//5sec
	else if(delay_clock && |logo_delay)logo_delay<=logo_delay-1'd1;
end
//--------------------------------------------------------------------------------
reg		[15:0]prg_len;
always@(posedge sysclk)begin
	if(sm == SM_LOGO_DELAY || sm == SM_IDLE)prg_len<=dump_prg_len;
	else if(sm == SM_PRG_RDPULSE)prg_len<=prg_len-1'd1;
end
//--------------------------------------------------------------------------------
reg		[15:0]chr_len;
always@(posedge sysclk)begin
	if(sm == SM_LOGO_DELAY || sm == SM_IDLE)chr_len<=dump_chr_len;
	else if(sm == SM_CHR_RDPULSE)chr_len<=chr_len-1'd1;
end
//--------------------------------------------------------------------------------
reg		old_busy;
always@(posedge sysclk)begin
	old_busy<=busy;
end
//--------------------------------------------------------------------------------
reg		[31:0]rw_addr;//addr for sdcard
always@(posedge sysclk)begin
	if(sm == SM_LOGO_DELAY || sm == SM_IDLE)rw_addr<=dump_offset;
	else if(~busy && old_busy)rw_addr<=rw_addr+32'h200;
end
//--------------------------------------------------------------------------------
reg		ldr_lh;
always@(posedge sysclk)begin
	if(sm == SM_PRG_RDPULSE)ldr_lh<=0;
	else if(sm == SM_CHR_RDPULSE)ldr_lh<=1'b1;
end
//--------------------------------------------------------------------------------
reg		[24:0]ldr_addr;//addr for sdram
always@(posedge sysclk)begin
	if((sm == SM_LOGO_DELAY || sm == SM_IDLE) ||
		(sm == SM_CHR_RDPULSE && ~ldr_lh))
		ldr_addr<=0;
	else if(ldr_ack)
		ldr_addr<=ldr_addr+1'd1;
end

endmodule
