module ppu_registers(
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
						dot_number,
						line_number,
						//REG2002
						sprite_hit,
						sprite_overflow,
						//REG2001
						show_sprite,
						show_background,
						show_sprite_left,
						show_background_left,
						//REG2000
						nmi_enable,
						sprite_size,				
						bg_ptable_addr,			
						sp_ptable_addr,						
						//
						oam_addrout,
						oam_datain,
						oam_dataout,
						oam_wr,
						//
						load_v,
						vram_tmp,
						fine_x_tmp,
						//
						vertical_blank,
						status_vb,
						//
						vram_addrout,
						vram_datain,
						vram_dataout,
						vram_wr
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
input		[8:0]dot_number;
input		[8:0]line_number;
//REG2002
input		sprite_hit;
input		sprite_overflow;
//REG2001
output	show_sprite;
output	show_background;
output	show_sprite_left;
output	show_background_left;
//REG_2000		
output	nmi_enable;	
output	sprite_size;				
output	bg_ptable_addr;			
output	sp_ptable_addr;						
//
output	[7:0]oam_addrout;
input		[7:0]oam_datain;
output	[7:0]oam_dataout;
output	oam_wr;
//
output	load_v;
output	[14:0]vram_tmp;
output	[2:0]fine_x_tmp;
//
output	vertical_blank;
output	status_vb;
//
output 	[13:0]vram_addrout;
input		[7:0]vram_datain;
output	[7:0]vram_dataout;
output	vram_wr;

//
assign 	ioreg_dataout 		= 	(ppu_cs && ioreg_addr == 3'd4 && !ioreg_wr) ? oam_datain : 
										(ppu_cs && ioreg_addr == 3'd2 && !ioreg_wr) ? {status_vb,sprite_hit,sprite_overflow,5'b00000}:
										(ppu_cs && ioreg_addr == 3'd7 && !ioreg_wr) ? vram_rddata : 8'hFF;
								  							  
//oam
assign	oam_addrout 		= 	REG_2003;
assign 	oam_dataout			= 	ioreg_datain;
assign	oam_wr				= 	(ppu_cs && ioreg_addr == 3'd4 & ioreg_wr);


assign	vram_dataout		=	ioreg_datain;
assign	vram_wr				=	(ppu_cs && ioreg_addr == 3'd7 & ioreg_wr);

wire		[7:0]vram_rddata 	= 	(&vram_tmp[13:8]) ? vram_datain : vram_rdbuf;	

//REG2004
assign	show_sprite					=	REG_2001[4];		//1: Show sprites
assign	show_background			=	REG_2001[3];		//1: Show background
assign	show_sprite_left			=	REG_2001[2];		//1: Show sprites in leftmost 8 pixels of screen, 0: Hide
assign	show_background_left		=	REG_2001[1];		//1: Show background in leftmost 8 pixels of screen, 0: Hide
//REG_2000
wire		nmi_enable					=	REG_2000[7];		//nmi enable
assign	sprite_size					= 	REG_2000[5];		//Sprite size (0: 8x8; 1: 8x16)
assign	bg_ptable_addr				=	REG_2000[4];		//Background pattern table address (0: $0000; 1: $1000)
assign	sp_ptable_addr				=	REG_2000[3];		//Sprite pattern table address for 8x8 sprites, (0: $0000; 1: $1000; ignored in 8x16 mode)
wire		vaddr_inc_val				=	REG_2000[2];		//VRAM address increment per CPU read/write of PPUDATA,(0: add 1, going across; 1: add 32, going down)
//-------------------------------------------------------------------------
//////////////////REG_2000///////////////////////PPUCTRL
//-------------------------------------------------------------------------
reg		[7:2]REG_2000;		
always@(posedge sysclk or negedge reset)begin
	if(!reset)REG_2000<=0;
	else if(ppu_cs && cpu_clock && ioreg_addr == 3'd0 && ioreg_wr)REG_2000<=ioreg_datain[7:2];
end
//-------------------------------------------------------------------------
//////////////////REG_2001///////////////////////PPUMASK
//-------------------------------------------------------------------------
reg 		[4:1]REG_2001;
always@(posedge sysclk or negedge reset)begin
	if(!reset)REG_2001<=0;
	else if(ppu_cs && cpu_clock && ioreg_addr == 3'd1 && ioreg_wr)REG_2001<=ioreg_datain[4:1];
end
//-------------------------------------------------------------------------
//////////////////REG_2002///////////////////////PPUSTATUS
//-------------------------------------------------------------------------
reg 		vertical_blank;
always@(posedge sysclk or negedge reset)begin
	if(!reset)															vertical_blank<=0;
	else if(line_number == 9'd241 && dot_number == 9'd1)	vertical_blank<=1'b1;
	else if(line_number == 9'd261 && dot_number == 9'd1)	vertical_blank<=0;
end

reg	status_vb;
always@(posedge sysclk or negedge reset)begin
	if(!reset)															status_vb<=0;
	else if(line_number == 9'd241 && dot_number == 9'd1)	status_vb<=1'b1;
	else if(( ppu_cs && cpu_clock  && ioreg_addr == 3'd2 && !ioreg_wr) || 
			  (line_number == 9'd261 && dot_number == 9'd1))status_vb<=0;
end
//-------------------------------------------------------------------------
//////////////////REG_2003///////////////////////OAMADDR
//-------------------------------------------------------------------------
reg 		[7:0]REG_2003;
always@(posedge sysclk or negedge reset)begin
	if(!reset)REG_2003<=0;
	else if(ppu_cs && cpu_clock && ioreg_wr)begin
		if(ioreg_addr == 3'd3)REG_2003<=ioreg_datain;												//set oam addr
		else if(ioreg_addr == 3'd4 )REG_2003<=REG_2003+1'd1;										//write into oam
	end
	else if(dot_number > 9'd256 && dot_number < 9'd321 && !vertical_blank)REG_2003<=0;	
end
//-------------------------------------------------------------------------
//////////////////REG_2005,REG_2006///////////////////////PPUSCROLL,PPUADDR
//-------------------------------------------------------------------------
reg 		tgl_w; 
always@(posedge sysclk or negedge reset)begin
	if(!reset)tgl_w<=0;
	else if(ppu_cs && cpu_clock && ioreg_addr == 3'd2 && !ioreg_wr)tgl_w<=0;										//read from 2002
	else if(ppu_cs && cpu_clock && (ioreg_addr == 3'd5 || ioreg_addr == 3'd6) && ioreg_wr)tgl_w<=~tgl_w;	//write into 2005/2006
end
/*
yyy NN YYYYY XXXXX
||| || ||||| +++++-- coarse X scroll
||| || +++++-------- coarse Y scroll
||| ++-------------- nametable select
+++----------------- fine Y scroll
*/

reg		load_v;
always@(posedge sysclk or negedge reset)begin
	if(!reset)load_v<=0;
	else if(!load_v)load_v<=ppu_cs && cpu_clock && tgl_w && ioreg_addr == 3'd6 && ioreg_wr;
	else load_v<=0;
end

wire 		[5:0]vram_add_val = vaddr_inc_val ? 6'd32 : 6'd1;
reg 		[14:0]vram_tmp;
always@(posedge sysclk or negedge reset)begin
	if(!reset)vram_tmp<=0;
	else if(ppu_cs && cpu_clock)begin
		if( ioreg_addr == 3'd5 && ioreg_wr )begin
			if(!tgl_w)										vram_tmp[4:0]<=ioreg_datain[7:3];
			else 												vram_tmp<={ioreg_datain[2:0],vram_tmp[11:10],ioreg_datain[7:3],vram_tmp[4:0]};
		end
		else if( ioreg_addr == 3'd6 && ioreg_wr )begin
			if(!tgl_w)										vram_tmp[14:8]<={1'b0,ioreg_datain[5:0]};
			else 												vram_tmp[7:0]<=ioreg_datain;
		end
		else if( ioreg_addr == 3'd0 && ioreg_wr )	vram_tmp[11:10]<=ioreg_datain[1:0];
	end
end

reg	[13:0]vram_addrout;
always@(posedge sysclk)begin
	if(load_v)														vram_addrout<=vram_tmp[13:0];
	else if(ppu_cs && cpu_clock && ioreg_addr == 3'd7)	vram_addrout<=vram_addrout+vram_add_val;
end
	
reg 		[2:0]fine_x_tmp;
always@(posedge sysclk or negedge reset)begin
	if(!reset)fine_x_tmp<=0;
	else if(ppu_cs && cpu_clock && ioreg_addr == 3'd5 && ioreg_wr && !tgl_w)fine_x_tmp<=ioreg_datain[2:0];
end
//-------------------------------------------------------------------------
//////////////////REG_2007///////////////////////PPUDATA
//-------------------------------------------------------------------------
reg		[7:0]vram_rdbuf;
always@(posedge sysclk)if(ppu_cs && cpu_clock && ioreg_addr == 3'd7 && !ioreg_wr)vram_rdbuf<=vram_datain;

endmodule