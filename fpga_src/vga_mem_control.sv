module vga_mem_control(
					sysclk,
					reset,
					//
					ppu_v_blank,
					ppu_ram_select,
					vga_addr,
					//
					dma_rdaddr,
					dma_rddata0,
					dma_rddata1,
					//
					dma_wraddr,
					dma_wren,
					dma_wrdata
				  );
					
input		sysclk;
input		reset;
//
input		ppu_v_blank;
output	ppu_ram_select;
input		[3:0]vga_addr;
//
output	[15:0]dma_rdaddr;
input		[7:0]dma_rddata0;
input		[7:0]dma_rddata1;
//
output	[15:0]dma_wraddr;
output	dma_wren;
output	[7:0]dma_wrdata;	
	
assign	dma_wren 	= |dma_rdaddr;
assign	dma_wrdata	= dma_ram_select ? dma_rddata1 : dma_rddata0;
			
reg		[1:0]dma_st;
always@(posedge sysclk)	dma_st<={dma_st[0],&vga_addr};				
			
reg		[15:0]dma_rdaddr;				
always@(posedge sysclk or negedge reset)begin
	if(!reset)dma_rdaddr<=0;
	else if((~dma_st[1] && dma_st[0]) || |dma_rdaddr)dma_rdaddr<=dma_rdaddr+1'd1;
end

reg		[15:0]dma_wraddr;
always@(posedge sysclk or negedge reset)begin
	if(!reset)dma_wraddr<=0;
	else if(|dma_rdaddr)dma_wraddr<=dma_wraddr+1'd1;
	else dma_wraddr<=0;
end
	
reg		dma_ram_select;
always@(posedge sysclk)begin
	if(~dma_st[1] && dma_st[0])dma_ram_select<=~ppu_ram_select;
end

reg		ppu_ram_select;
always@(posedge sysclk or negedge reset)begin
	if(!reset)ppu_ram_select<=1'b0;
	else if(ppu_v_blank)ppu_ram_select<=~ppu_ram_select;
end

endmodule