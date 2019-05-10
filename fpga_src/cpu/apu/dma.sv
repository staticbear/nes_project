module dma(
			sysclk,
			cpu_clock,
			reset,
			dma_cs, 
			ioreg_addr,
			ioreg_datain,
			ioreg_wr,
			addr_bus,
			data_in,
			data_out,
			data_wr,
			rdy
			);

input 	sysclk;
input		cpu_clock;
input		reset;
input		dma_cs;
input		[4:0]ioreg_addr;
input		[7:0]ioreg_datain;
input		ioreg_wr;

output	[15:0]addr_bus;
output	[7:0]data_out;
input		[7:0]data_in;
output	data_wr;
output	rdy;


wire [15:0]scr_addr;
assign scr_addr = {hold_src_addr,dma_cnt};
assign addr_bus = data_wr ? 16'h2004 : scr_addr;
assign data_out = hold_data;
assign rdy = ~flag_rdy;
//--------------------------------------------------------------------------------	
reg 	flag_rdy;
always@(posedge sysclk or negedge reset)begin
	if( !reset )							flag_rdy<=0;
	else if( cpu_clock )begin
		if(!flag_rdy)						flag_rdy<=(dma_cs && ioreg_addr == 5'h14 && ioreg_wr);
		else if(&dma_cnt && data_wr)	flag_rdy<=0;
	end
end	
//--------------------------------------------------------------------------------
reg 	[7:0]dma_cnt;
always@(posedge sysclk or negedge reset)begin
	if( !reset )							dma_cnt<=0;
	else if( cpu_clock && data_wr )	dma_cnt<=dma_cnt+1'd1;
end
//--------------------------------------------------------------------------------
reg 	[7:0]hold_src_addr;
always@(posedge sysclk)if( dma_cs && ioreg_addr == 5'h14 && ioreg_wr && cpu_clock )hold_src_addr<=ioreg_datain;
//--------------------------------------------------------------------------------
reg 	[7:0]hold_data;
always@(posedge sysclk)if(cpu_clock)hold_data<=data_in;
//--------------------------------------------------------------------------------
reg 	data_wr;
always@(posedge sysclk)begin
	if( cpu_clock )begin
		if(!flag_rdy)		data_wr<=0;
		else if(!data_wr)	data_wr<=1;
		else 					data_wr<=0;
	end
end

endmodule