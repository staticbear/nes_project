module ppu(	
				sysclk,
				cpu_clock,
				ppu_clock,
				reset,
				//
				ppu_cs,
				//
				ioreg_addr,
				ioreg_datain,
				ioreg_dataout,
				ioreg_wr,
				//
				ppu_addr_bus,
				ppu_data_in,
				ppu_data_out,
				ppu_wr,
				//
				oam_addrout,
				oam_datain,
				oam_dataout,
				oam_wr,
				//
				ppu_nmi,
				v_blank,
				//
				color_addr,
				color_data,
				color_wren
			  );
			  
input		sysclk;
input		cpu_clock;
input		ppu_clock;
input		reset;
//
input		ppu_cs;
//
input		[2:0]ioreg_addr;
input		[7:0]ioreg_datain;
output	[7:0]ioreg_dataout;
input		ioreg_wr;
//
output 	[13:0]ppu_addr_bus;
input		[7:0]ppu_data_in;
output	[7:0]ppu_data_out;
output	ppu_wr;
//
output	[7:0]oam_addrout;
input		[7:0]oam_datain;
output	[7:0]oam_dataout;
output	oam_wr;
//
output	ppu_nmi;
output	v_blank;
//
output	[15:0]color_addr;
output	[7:0]color_data;
output	color_wren;


assign	ppu_nmi 			= ~(~nmi_gen[1] & nmi_gen[0]);
assign	v_blank			=	(~v_blank_gen[1] & v_blank_gen[0]);
//-------------------------------------------------------------------------
assign	ppu_addr_bus	= (reg_vertical_blank || ~(reg_show_sprite | reg_show_background)) ? reg_vram_addrout : rendr_vram_addrout;
assign	ppu_data_out	=	reg_vram_dataout;
assign	ppu_wr			=	reg_vram_wr;
//-------------------------------------------------------------------------
assign	oam_addrout		= (reg_vertical_blank || ~(reg_show_sprite | reg_show_background)) ? reg_oam_addrout : rendr_oam_addrout;
assign	oam_dataout		=	reg_oam_dataout;
assign	oam_wr			=	reg_oam_wr;
//-------------------------------------------------------------------------
reg		[7:0]color_palette[31:0];
wire		[4:0]palette_index = ppu_addr_bus[4:0];
wire		palette_wren;
assign	palette_wren			= (&ppu_addr_bus[13:8] && (~|ppu_addr_bus[7:5])) ? ppu_wr : 1'b0;
always@(posedge sysclk)begin
	if(palette_wren)begin
		if(|palette_index[1:0])color_palette[palette_index]<=ppu_data_out;
		else if(~|palette_index[3:2])begin
			color_palette[5'h00]<=ppu_data_out;
			color_palette[5'h04]<=ppu_data_out;
			color_palette[5'h08]<=ppu_data_out;
			color_palette[5'h0C]<=ppu_data_out;
			color_palette[5'h10]<=ppu_data_out;
			color_palette[5'h14]<=ppu_data_out;
			color_palette[5'h18]<=ppu_data_out;
			color_palette[5'h1C]<=ppu_data_out;
		end	
	end
end
//-------------------------------------------------------------------------
wire		reg_show_sprite;
wire		reg_show_background;
wire		reg_show_sprite_left;
wire		reg_show_background_left;

wire		reg_sprite_size;				
wire		reg_bg_ptable_addr;		
wire		reg_sp_ptable_addr;

wire		reg_load_v;
wire		[14:0]reg_vram_tmp;
wire		[2:0]reg_fine_x_tmp;

wire		reg_vertical_blank;
wire		reg_status_vb;

wire		[13:0]reg_vram_addrout;
wire		[7:0]reg_vram_datain;

assign	reg_vram_datain	= (&ppu_addr_bus[13:8] && (~|ppu_addr_bus[7:5])) ? color_palette[palette_index] : ppu_data_in;

wire		[7:0]reg_vram_dataout;
wire		reg_vram_wr;

wire		[7:0]reg_oam_addrout;
wire		[7:0]reg_oam_datain = oam_datain;
wire		[7:0]reg_oam_dataout;
wire		reg_oam_wr;

wire		reg_nmi_enable;
ppu_registers m_ppu_registers(
						.sysclk(sysclk),
						.cpu_clock(cpu_clock),
						.ppu_clock(ppu_clock),
						.reset(reset),
						//
						.ppu_cs(ppu_cs),
						//
						.ioreg_addr(ioreg_addr),
						.ioreg_datain(ioreg_datain),
						.ioreg_dataout(ioreg_dataout),
						.ioreg_wr(ioreg_wr),
						//
						.dot_number(rendr_dot_number),
						.line_number(rendr_line_number),
						//REG2000
						.sprite_hit(rendr_sprite_hit),
						.sprite_overflow(rendr_sprite_overflow),
						//REG2004
						.show_sprite(reg_show_sprite),
						.show_background(reg_show_background),
						.show_sprite_left(reg_show_sprite_left),
						.show_background_left(reg_show_background_left),
						//REG2000	
						.nmi_enable(reg_nmi_enable),
						.sprite_size(reg_sprite_size),				
						.bg_ptable_addr(reg_bg_ptable_addr),			
						.sp_ptable_addr(reg_sp_ptable_addr),							
						//
						.oam_addrout(reg_oam_addrout),
						.oam_datain(reg_oam_datain),
						.oam_dataout(reg_oam_dataout),
						.oam_wr(reg_oam_wr),
						//
						.load_v(reg_load_v),
						.vram_tmp(reg_vram_tmp),
						.fine_x_tmp(reg_fine_x_tmp),
						//
						.vertical_blank(reg_vertical_blank),
						.status_vb(reg_status_vb),
						//
						.vram_addrout(reg_vram_addrout),
						.vram_datain(reg_vram_datain),
						.vram_dataout(reg_vram_dataout),
						.vram_wr(reg_vram_wr)
					);

reg	[1:0]nmi_gen;
always@(posedge sysclk or negedge reset)begin
	if(!reset)	nmi_gen<=2'b00;
	else if(reg_nmi_enable)nmi_gen<={nmi_gen[0],(reg_vertical_blank & reg_status_vb)};
	//else nmi_gen<=2'b00;
end
					
reg	[1:0]v_blank_gen;
always@(posedge sysclk or negedge reset)begin
	if(!reset)	v_blank_gen<=2'b00;
	else 			v_blank_gen<={v_blank_gen[0],reg_vertical_blank};
end
//-------------------------------------------------------------------------					
wire		[8:0]rendr_dot_number;
wire		[8:0]rendr_line_number;

wire		rendr_sprite_hit;
wire		rendr_sprite_overflow;

wire		[13:0]rendr_vram_addrout;
wire		[7:0]rendr_vram_datain; 

assign	rendr_vram_datain	= (&ppu_addr_bus[13:8] && (~|ppu_addr_bus[7:5])) ? color_palette[palette_index] : ppu_data_in;

wire		[7:0]rendr_oam_addrout;
wire		[7:0]rendr_oam_datain = oam_datain;
			
wire		[4:0]rendr_color_index;		

wire		rendr_dot_visible;
wire		rendr_line_visible;
ppu_render m_ppu_render(
						.sysclk(sysclk),
						.ppu_clock(ppu_clock),
						.reset(reset),
						//
						.load_v(reg_load_v),
						.vram_tmp(reg_vram_tmp),
						.fine_x_tmp(reg_fine_x_tmp),
						//
						.vram_addrout(rendr_vram_addrout),
						.vram_datain(rendr_vram_datain),
						//
						.oam_addrout(rendr_oam_addrout),
						.oam_datain(rendr_oam_datain),
						//REG2002
						.sprite_hit(rendr_sprite_hit),
						.sprite_overflow(rendr_sprite_overflow),
						//REG2004
						.show_sprite(reg_show_sprite),
						.show_background(reg_show_background),
						.show_sprite_left(reg_show_sprite_left),
						.show_background_left(reg_show_background_left),
						//REG2000	
						.sprite_size(reg_sprite_size),			//1: 16; 0: 8
						.bg_ptable_addr(reg_bg_ptable_addr),	//Background pattern table address (0: $0000; 1: $1000)
						.sp_ptable_addr(reg_sp_ptable_addr),	//Sprite pattern table address for 8x8 sprites, (0: $0000; 1: $1000; ignored in 8x16 mode)
						//
						.dot_number(rendr_dot_number),			//340 max
						.line_number(rendr_line_number),			//261 max
						.dot_visible(rendr_dot_visible),
						.line_visible(rendr_line_visible),
						//
						.pixel_color_index(rendr_color_index)
					);					
//-------------------------------------------------------------------------

reg		[7:0]color_data;
always@(posedge sysclk)begin
	if(ppu_clock)color_data	<=	color_palette[rendr_color_index];
end

wire		color_wren;
assign	color_wren = rendr_dot_visible & rendr_line_visible;

reg		[15:0]color_addr;
always@(posedge sysclk)begin
	if(ppu_clock)begin
		if(color_wren)color_addr<=color_addr+1'd1;
		else if(~rendr_line_visible)color_addr<=16'hFFFF;
	end
end


endmodule