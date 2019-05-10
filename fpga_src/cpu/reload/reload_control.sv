module reload_control(
								sysclk,
								cpu_clock,
								reset,
								//
								rld_cs, 
								ioreg_addr,
								ioreg_datain,
								ioreg_wr,
								//
								reload,
								load_dump,
								mapper_type,
								solder_mirror,
								dump_offset,
								dump_prg_len,
								dump_chr_len
							);
							
input		sysclk;
input		cpu_clock;
input		reset;
//
input		rld_cs; 
input		[4:0]ioreg_addr;
input		[7:0]ioreg_datain;
input		ioreg_wr;
//
input		reload;
output	load_dump;
output	[3:0]mapper_type;
output	solder_mirror;
output	[31:0]dump_offset;
output	[15:0]dump_prg_len;
output	[15:0]dump_chr_len;

assign	solder_mirror	=	dump_info[4];
assign	mapper_type		=	dump_info[3:0];

reg		load_dump;
always@(posedge sysclk)load_dump<=(~param_cnt[3] && old_param) || reload;
//--------------------------------------------------------------------------------
reg		old_param;
always@(posedge sysclk)old_param<=param_cnt[3];
//--------------------------------------------------------------------------------
reg		[3:0]param_cnt;
always@(posedge sysclk or negedge reset)begin
	if(!reset)param_cnt<=0;
	else if(cpu_clock && rld_cs && ioreg_addr == 5'h18 && ioreg_wr)begin
		if(param_cnt[3])param_cnt<=0;
		else param_cnt<=param_cnt+1'd1;
	end
	else if(reload)param_cnt<=0;
end
//--------------------------------------------------------------------------------
reg		[4:0]dump_info;
always@(posedge sysclk or negedge reset)begin
	if(!reset)
		dump_info<=0;
	else if(cpu_clock && rld_cs && ioreg_addr == 5'h18 && ioreg_wr && param_cnt == 4'd0)
		dump_info<=ioreg_datain[4:0];
	else if(reload)
		dump_info<=0;
end
//--------------------------------------------------------------------------------
reg		[31:0]dump_offset;
always@(posedge sysclk or negedge reset)begin
	if(!reset)dump_offset<=0;
	else if(cpu_clock && rld_cs && ioreg_addr == 5'h18 && ioreg_wr)begin
		case(param_cnt)
			4'd1:dump_offset[7:0]<=ioreg_datain;
			4'd2:dump_offset[15:8]<=ioreg_datain;
			4'd3:dump_offset[23:16]<=ioreg_datain;
			4'd4:dump_offset[31:24]<=ioreg_datain;
		endcase
	end
	else if(reload)dump_offset<=0;
end
//--------------------------------------------------------------------------------
reg		[15:0]dump_prg_len;
always@(posedge sysclk or negedge reset)begin
	if(!reset)dump_prg_len<=16'd64;
	else if(cpu_clock && rld_cs && ioreg_addr == 5'h18 && ioreg_wr)begin
		case(param_cnt)
			4'd5:dump_prg_len[7:0]<=ioreg_datain;
			4'd6:dump_prg_len[15:8]<=ioreg_datain;
		endcase
	end
	else if(reload)dump_prg_len<=16'd64;//32768 = 64 * 512
end
//--------------------------------------------------------------------------------
reg		[15:0]dump_chr_len;
always@(posedge sysclk or negedge reset)begin
	if(!reset)dump_chr_len<=16'd16;
	else if(cpu_clock && rld_cs && ioreg_addr == 5'h18 && ioreg_wr)begin
		case(param_cnt)
			4'd7:dump_chr_len[7:0]<=ioreg_datain;
			4'd8:dump_chr_len[15:8]<=ioreg_datain;
		endcase
	end
	else if(reload)dump_chr_len<=16'd16;//8192 = 16 * 512
end

endmodule
