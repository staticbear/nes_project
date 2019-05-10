 module ppu_render(
						sysclk,
						ppu_clock,
						reset,
						//
						load_v,
						vram_tmp,
						fine_x_tmp,
						//
						vram_addrout,
						vram_datain,
						//
						oam_addrout,
						oam_datain,
						//REG2002
						sprite_hit,
						sprite_overflow,
						//REG2001
						show_sprite,
						show_background,
						show_sprite_left,
						show_background_left,
						//REG2000	
						sprite_size,		//1: 16; 0: 8
						bg_ptable_addr,	//Background pattern table address (0: $0000; 1: $1000)
						sp_ptable_addr,	//Sprite pattern table address for 8x8 sprites, (0: $0000; 1: $1000; ignored in 8x16 mode)
						//
						dot_number,			//340 max
						line_number,		//261 max
						dot_visible,
						line_visible,
						//
						pixel_color_index
					);
					
input		sysclk;
input		ppu_clock;
input		reset;
//
input		load_v;
input		[14:0]vram_tmp;
input		[2:0]fine_x_tmp;
//
output	[13:0]vram_addrout;
input		[7:0]vram_datain;
//
output	[7:0]oam_addrout;
input		[7:0]oam_datain;
//REG2002
output	sprite_hit;
output	sprite_overflow;
//REG2004
input		show_sprite;
input		show_background;
input		show_sprite_left;
input		show_background_left;
//REG2000
input		sprite_size;
input		bg_ptable_addr;
input		sp_ptable_addr;
//
output	[8:0]dot_number; 
output	[8:0]line_number;
output	dot_visible;
output	line_visible;
//
output	[4:0]pixel_color_index;


wire		enable_rendering = /*show_sprite &*/ show_background;
//-------------------------------------------------------------------------

reg		dot_visible;
always@(posedge sysclk or negedge reset)begin
	if(!reset)dot_visible<=0;
	else if(ppu_clock)begin
		if(dot_number == 9'd0)dot_visible<=1;
		else if(dot_number == 9'd256)dot_visible<=0;
	end
end

reg		line_visible;
always@(posedge sysclk or negedge reset)begin
	if(!reset)line_visible<=0;
	else if(ppu_clock)begin
		if(line_number == 9'd7)line_visible<=1;
		else if(line_number == 9'd232)line_visible<=0;
	end
end
//-------------------------------------------------------------------------
reg		[8:0]dot_number;	
always@(posedge sysclk or negedge reset)begin
	if(!reset)							dot_number<=0;
	else if(ppu_clock)begin
		if(dot_number == 9'd340)	dot_number<=0;
		else 								dot_number<=dot_number+1'd1;
	end
end
//-------------------------------------------------------------------------
reg		[8:0]line_number;
always@(posedge sysclk or negedge reset)begin
	if(!reset)													line_number<=0;
	else if(ppu_clock && dot_number == 9'd340)begin
		if(line_number == 9'd261 )							line_number<=0;
		else 														line_number<=line_number+1'd1;
	end
end
//-------------------------------------------------------------------------
///////////////////////////////BACKGROUND//////////////////////////////////
//-------------------------------------------------------------------------
reg 		[4:0]coarse_y;
reg		[2:0]fine_y;
reg 		vert_nt;
always@(posedge sysclk or negedge reset)begin
	if(!reset)begin
		coarse_y<=0;
		fine_y<=0;
		vert_nt<=0;
	end
	else if(load_v)begin
		coarse_y<=vram_tmp[9:5];
		fine_y<=vram_tmp[14:12];
		vert_nt<=vram_tmp[11];
	end
	else if(ppu_clock && enable_rendering)begin
		if(dot_number == 9'd280 && line_number == 9'd261)begin
			coarse_y<=vram_tmp[9:5];
			fine_y<=vram_tmp[14:12];
			vert_nt<=vram_tmp[11];
		end
		if(dot_number == 9'd251)begin
			if(fine_y != 3'd7)   					// if fine Y < 7    
				fine_y <= fine_y + 1'd1;			// increment fine Y
			else begin
				fine_y<=0;								// fine Y = 0
				if(coarse_y == 5'd29)begin
					coarse_y<=0;						// coarse Y = 0
					vert_nt<=vert_nt ^ 1'b1;		// switch vertical nametable
				end
				else if(coarse_y == 5'd31)
					coarse_y<=0;						// coarse Y = 0, nametable not switched
				else 
					coarse_y<=coarse_y+1'd1;		// increment coarse Y
			end
		end
	end
end
//-------------------------------------------------------------------------
reg 		[4:0]coarse_x;
reg 		horiz_nt;
always@(posedge sysclk or negedge reset)begin
	if(!reset)begin
		coarse_x<=0;
		horiz_nt<=0;
	end
	else if(load_v)begin
		coarse_x<=vram_tmp[4:0];
		horiz_nt<=vram_tmp[10];
	end
	else if(ppu_clock && enable_rendering)begin
		if(dot_number == 9'd257)begin
			coarse_x<=vram_tmp[4:0];						//v horizontal = t horizontal
			horiz_nt<=vram_tmp[10];
		end
		else if(((ld_new_shift && dot_number < 9'd257) || 
				    dot_number == 9'd328 || dot_number== 9'd336))begin	//	each 8 position < 256 , 328 and 336 incriment horizontal(v)
			if(coarse_x == 5'd31)begin
				coarse_x<=5'd0;								// coarse X = 0       
				horiz_nt<=horiz_nt^1'b1;					// switch horizontal nametable
			end
			else	coarse_x<=coarse_x+1'd1;				// increment coarse X
		end
	end
end
//-------------------------------------------------------------------------+
reg 	[7:0]pattern_index;
always@(posedge sysclk)begin
	if(ppu_clock && dot_number[2:0] == 3'd2)pattern_index<=vram_datain;
end
//-------------------------------------------------------------------------+
reg 	[7:0]low_bg_latch;
always@(posedge sysclk)begin
	if(ppu_clock && dot_number[2:0] == 3'd6)low_bg_latch<=vram_datain;
end
//-------------------------------------------------------------------------
reg		fetch_tiles;
always@(posedge sysclk or negedge reset)begin
	if(!reset)fetch_tiles<=0;
	else if(ppu_clock)begin
		if(dot_number == 9'd0 || dot_number == 9'd320)fetch_tiles<=1;
		else if(dot_number == 9'd256 || dot_number == 9'd336)fetch_tiles<=0;
	end
end

reg		fetch_sprites;
always@(posedge sysclk or negedge reset)begin
	if(!reset)fetch_sprites<=0;
	else if(ppu_clock)begin
		if(dot_number == 9'd320)fetch_sprites<=0;
		else if(dot_number == 9'd256)fetch_sprites<=1;
	end
end

reg		fetch_lines;
always@(posedge sysclk or negedge reset)begin
	if(!reset)fetch_lines<=0;
	else if(ppu_clock)begin
		if(line_number == 9'd261)fetch_lines<=1;
		else if(line_number == 9'd239)fetch_lines<=0;
	end
end

reg		pre_rendr_line;
always@(posedge sysclk)begin
	if(ppu_clock)begin
		if(line_number == 9'd261)pre_rendr_line<=1;
		else pre_rendr_line<=0;
	end
end
//-------------------------------------------------------------------------
reg		ld_new_shift;
always@(posedge sysclk or negedge reset)begin
	if(!reset)ld_new_shift<=0;
	else if(ppu_clock)ld_new_shift<=&dot_number[2:0];
end
//-------------------------------------------------------------------------
reg		[15:0]tile_shif0;
reg		[15:0]tile_shif1;
always@(posedge sysclk or negedge reset)begin
	if(!reset)begin
		tile_shif0<=0;
		tile_shif1<=0;
	end
	else if(ppu_clock && fetch_tiles )begin 
		if(ld_new_shift)begin
			tile_shif0<={tile_shif0[14:7],low_bg_latch};	//load new data
			tile_shif1<={tile_shif1[14:7],vram_datain};	//load new data
		end
		else begin
			tile_shif0<={tile_shif0[14:0],1'b0};			//shift per one position
			tile_shif1<={tile_shif1[14:0],1'b0};			//shift per one position
		end
	end
end
//-------------------------------------------------------------------------+

wire		[3:0]sel_y;
assign	sel_y = coarse_y[1] ? 	{vram_datain[5],vram_datain[4],vram_datain[7],vram_datain[6]} : 
											{vram_datain[1],vram_datain[0],vram_datain[3],vram_datain[2]};
wire		[1:0]sel_x;
assign	sel_x	= coarse_x[1] ?	{sel_y[1],sel_y[0]} : {sel_y[3],sel_y[2]};

reg		[1:0]palette_latch0;
reg		[1:0]palette_latch1;
always@(posedge sysclk)begin
	if(ppu_clock)begin  
		if(dot_number[2:0] == 3'd4)begin
			palette_latch0[1]<=sel_x[0];
			palette_latch1[1]<=sel_x[1];
		end
		else if(ld_new_shift)begin
			palette_latch0[0]<=palette_latch0[1];
			palette_latch1[0]<=palette_latch1[1];
		end
	end
end
//-------------------------------------------------------------------------+
reg		[7:0]palette_shif0;
reg		[7:0]palette_shif1;
always@(posedge sysclk or negedge reset)begin
	if(!reset)begin
		palette_shif0<=0;
		palette_shif1<=0;
	end
	else if(ppu_clock && fetch_tiles)begin
		palette_shif0<={palette_shif0[6:0],palette_latch0[0]};
		palette_shif1<={palette_shif1[6:0],palette_latch1[0]};
	end
end

//-------------------------------------------------------------------------
//tile address      = 0x2000 | (v & 0x0FFF)
wire		[13:0]tile_addr; 	
assign 	tile_addr = {2'b10,vert_nt,horiz_nt,coarse_y,coarse_x};
wire		[13:0]attr_addr;
assign 	attr_addr = {2'b10,vert_nt,horiz_nt,4'b1111,coarse_y[4:2],coarse_x[4:2]};//10 NN 1111 YYY XXX
wire		[13:0]bg_pattert_low_addr;
assign 	bg_pattert_low_addr = {1'b0,bg_ptable_addr,pattern_index,1'b0,fine_y};
wire		[13:0]bg_pattern_high_addr;
assign 	bg_pattern_high_addr = {1'b0,bg_ptable_addr,pattern_index,1'b1,fine_y};

reg		[13:0]vram_addrout;
always@(posedge sysclk)begin
	if(fetch_tiles && fetch_lines)begin
		case(dot_number[2:0])
			3'd1:		vram_addrout <= tile_addr;			
			3'd3:		vram_addrout <= attr_addr;			
			3'd5:		vram_addrout <= bg_pattert_low_addr;   
			3'd7:		vram_addrout <= bg_pattern_high_addr;  
		endcase
	end
	else if(fetch_sprites && fetch_lines)begin
		case(sm_index[1])
			1'd0:		vram_addrout <= sprite_size ? spx16_pattern_low_addr : spx8_pattern_low_addr;   //0
			1'd1:		vram_addrout <= sprite_size ? spx16_pattern_high_addr : spx8_pattern_high_addr; //2
		endcase
	end
end
//-------------------------------------------------------------------------
/////////////////////////////////SPRITE////////////////////////////////////
//-------------------------------------------------------------------------
parameter SM_SPR_IDLE	=	2'd0;
parameter SM_SPR_INIT	=	2'd1;
parameter SM_SPR_EVAL	=	2'd2;
parameter SM_SPR_FETCH	=	2'd3;

reg		[1:0]sm_spr;	
always@(posedge sysclk or negedge reset)begin
	if(!reset)												sm_spr<=SM_SPR_IDLE;
	else if(!show_sprite)								sm_spr<=SM_SPR_IDLE;
	else if(ppu_clock)begin
		case(sm_spr)
			SM_SPR_IDLE:if(fetch_lines)				sm_spr<=SM_SPR_INIT;
			SM_SPR_INIT:begin
				if(dot_number == 9'd64 && ~pre_rendr_line)		sm_spr<=SM_SPR_EVAL;
				else if(dot_number == 9'd256 && pre_rendr_line)	sm_spr<=SM_SPR_FETCH;					
			end
			SM_SPR_EVAL:if(dot_number == 9'd256)	sm_spr<=SM_SPR_FETCH;
			SM_SPR_FETCH:if(dot_number == 9'd320)	sm_spr<=SM_SPR_IDLE;
		endcase
	end
end

//-------------------------------------------------------------------------
reg		odd_even;
always@(posedge sysclk)begin
	if(ppu_clock)begin
		if(sm_spr == SM_SPR_EVAL)odd_even<=~odd_even;   //0 -  odd ,1 - even
		else odd_even<=0;
	end
end
//-------------------------------------------------------------------------
wire 		[8:0]different_coord;
assign	different_coord 	= line_number - oam_datain;
wire		in_range;	
assign	in_range 			= (~(|different_coord[8:4])) & (~different_coord[3] | sprite_size);	
//-------------------------------------------------------------------------
reg	flag_s_cpy;
always@(posedge sysclk)begin
	if(ppu_clock)begin
		if (sm_spr != SM_SPR_EVAL)flag_s_cpy<=0;
		else if(!oam_index[1:0] && !odd_even)flag_s_cpy<=in_range;
	end
end
//-------------------------------------------------------------------------
assign 	oam_addrout = oam_index[7:0];
reg	[8:0]oam_index;
always@(posedge sysclk)begin
	if(ppu_clock )begin
		if (sm_spr != SM_SPR_EVAL)	oam_index<=0;
		else if(odd_even && ~oam_index[8])begin
			if(|oam_index[1:0])		oam_index<=oam_index+1'd1;
			else begin
				if(in_range)			oam_index<=oam_index+1'd1;
				else 						oam_index<=oam_index+8'd4;
			end
		end
	end
end
//-------------------------------------------------------------------------
reg	[5:0]s_oam_index;
always@(posedge sysclk)begin
	if(ppu_clock)begin
		if (sm_spr != SM_SPR_EVAL)s_oam_index<=0;
		else if(odd_even && flag_s_cpy && !s_oam_index[5])s_oam_index<=s_oam_index+1'd1;
	end
end
//-------------------------------------------------------------------------
wire	flag_s_oam_wren = ~(s_oam_index[5] | oam_index[8]);
//-------------------------------------------------------------------------
wire	zero_sprite	=	~(|oam_index[7:2]);
//-------------------------------------------------------------------------
reg	[7:0]s_oam[31:0];
always@(posedge sysclk)begin
	if(ppu_clock)begin
		if(sm_spr == SM_SPR_INIT || sm_spr == SM_SPR_IDLE)begin
			s_oam[0] <=8'hFF;	s_oam[1]<=8'hFF; 
			s_oam[4] <=8'hFF; s_oam[5]<=8'hFF;	
			s_oam[8] <=8'hFF;	s_oam[9]<=8'hFF;
			s_oam[12]<=8'hFF; s_oam[13]<=8'hFF;	
			s_oam[16]<=8'hFF; s_oam[17]<=8'hFF; 
			s_oam[20]<=8'hFF; s_oam[21]<=8'hFF;	
			s_oam[24]<=8'hFF;	s_oam[25]<=8'hFF;
			s_oam[28]<=8'hFF; s_oam[29]<=8'hFF;	
		end
		else if(odd_even && flag_s_cpy && flag_s_oam_wren)begin
			s_oam[s_oam_index]<=	s_oam_index[1:0] != 2'd2  ?  oam_datain :
										zero_sprite  ? (oam_datain | 8'b00000100) : (oam_datain & 8'b11100011);
		end
	end
end
//-------------------------------------------------------------------------
reg	sprite_overflow;
always@(posedge sysclk or negedge reset)begin
	if(!reset)sprite_overflow<=0;
	else if(pre_rendr_line)sprite_overflow<=0;
	else if(s_oam_index[5] && flag_s_cpy)sprite_overflow<=1'b1;
end
//-------------------------------------------------------------------------
reg		[5:0]fetch_cnt;
always@(posedge sysclk)begin
	if(ppu_clock)begin
		if(sm_spr == SM_SPR_FETCH)fetch_cnt<=fetch_cnt+1'd1;
		else fetch_cnt<=0;
	end
end

wire	[2:0]sm_index	=	fetch_cnt[2:0];
wire	[2:0]sl_index	=	fetch_cnt[5:3];
//-------------------------------------------------------------------------
wire		[7:0]tmp_sp_y;
wire		[7:0]tmp_sp_tile;
wire		[7:0]tmp_sp_attrib;
wire		[7:0]tmp_sp_x;

assign	tmp_sp_y			=	s_oam[{sl_index,2'd0}];
assign	tmp_sp_tile		=	s_oam[{sl_index,2'd1}];
assign	tmp_sp_attrib	=	s_oam[{sl_index,2'd2}];
assign	tmp_sp_x			=	s_oam[{sl_index,2'd3}];

/*
76543210
||||||||
||||||++- Palette (4 to 7) of sprite
|||+++--- Unimplemented
||+------ Priority (0: in front of background; 1: behind background)
|+------- Flip sprite horizontally
+-------- Flip sprite vertically
*/
wire		[1:0]tmp_sp_pallete_h = tmp_sp_attrib[1:0];
wire		tmp_sp_zero = tmp_sp_attrib[2];
wire		tmp_sp_priority = tmp_sp_attrib[5];
wire		flip_hr	= tmp_sp_attrib[6];
wire		flip_vr	= tmp_sp_attrib[7];


wire 		[8:0]sp_offset;
assign	sp_offset = line_number - tmp_sp_y;
wire		[3:0]sp_offset_x16;
assign	sp_offset_x16 = flip_vr ? ~sp_offset[3:0] : sp_offset[3:0];

wire		[13:0]spx8_pattern_low_addr;
assign 	spx8_pattern_low_addr	=	{1'b0,sp_ptable_addr,tmp_sp_tile,1'b0,sp_offset_x16[2:0]};
wire		[13:0]spx8_pattern_high_addr;
assign 	spx8_pattern_high_addr	=	{1'b0,sp_ptable_addr,tmp_sp_tile,1'b1,sp_offset_x16[2:0]};

wire		[13:0]spx16_pattern_low_addr;
assign 	spx16_pattern_low_addr	=	{1'b0,tmp_sp_tile[0],tmp_sp_tile[7:1],sp_offset_x16[3],1'b0,sp_offset_x16[2:0]};
wire		[13:0]spx16_pattern_high_addr;
assign 	spx16_pattern_high_addr	=	{1'b0,tmp_sp_tile[0],tmp_sp_tile[7:1],sp_offset_x16[3],1'b1,sp_offset_x16[2:0]};

wire		[7:0]vram_datain_inv;
assign	vram_datain_inv	=	{	vram_datain[0],vram_datain[1],vram_datain[2],vram_datain[3],
											vram_datain[4],vram_datain[5],vram_datain[6],vram_datain[7]	};
											
reg		[7:0]tmp_sp_pallete_l0;
reg		[7:0]tmp_sp_pallete_l1;
always@(posedge sysclk)begin
	if(ppu_clock)begin
		if(sm_index == 3'd1)tmp_sp_pallete_l0<=flip_hr ? vram_datain_inv 	: vram_datain;
		if(sm_index == 3'd3)tmp_sp_pallete_l1<=flip_hr ? vram_datain_inv	: vram_datain;
	end
end 
		
wire		empty_slot = (&tmp_sp_y);

reg		[7:0]sp_pallete_l0[7:0];
reg		[7:0]sp_pallete_l1[7:0];
reg		[1:0]sp_pallete_h[7:0];
reg		[7:0]sp_xpos_cntr[7:0];
reg		sp_priority[7:0];
reg		sp_zero[7:0];

always@(posedge sysclk)begin
	if(ppu_clock)begin
		if(&sm_index)begin
			sp_pallete_l0[sl_index]	<=	empty_slot ? 8'h00 : tmp_sp_pallete_l0;
			sp_pallete_l1[sl_index]	<=	empty_slot ? 8'h00 : tmp_sp_pallete_l1;
			sp_pallete_h[sl_index]	<=	empty_slot ? 2'h00 : tmp_sp_pallete_h;
			sp_xpos_cntr[sl_index]	<=	empty_slot ? 8'h00 : tmp_sp_x;
			sp_priority[sl_index]	<=	empty_slot ? 1'b0  : tmp_sp_priority;
			sp_zero[sl_index]			<=	empty_slot ? 1'b0  : tmp_sp_zero;
		end
		else if(dot_visible)begin
		
			if(|sp_xpos_cntr[0])sp_xpos_cntr[0]<=sp_xpos_cntr[0]-1'd1;
			else begin
				sp_pallete_l0[0]<={sp_pallete_l0[0][6:0],1'b0};
				sp_pallete_l1[0]<={sp_pallete_l1[0][6:0],1'b0};
			end
			
			if(|sp_xpos_cntr[1])sp_xpos_cntr[1]<=sp_xpos_cntr[1]-1'd1;
			else begin
				sp_pallete_l0[1]<={sp_pallete_l0[1][6:0],1'b0};
				sp_pallete_l1[1]<={sp_pallete_l1[1][6:0],1'b0};
			end
			
			if(|sp_xpos_cntr[2])sp_xpos_cntr[2]<=sp_xpos_cntr[2]-1'd1;
			else begin
				sp_pallete_l0[2]<={sp_pallete_l0[2][6:0],1'b0};
				sp_pallete_l1[2]<={sp_pallete_l1[2][6:0],1'b0};
			end
			
			if(|sp_xpos_cntr[3])sp_xpos_cntr[3]<=sp_xpos_cntr[3]-1'd1;
			else begin
				sp_pallete_l0[3]<={sp_pallete_l0[3][6:0],1'b0};
				sp_pallete_l1[3]<={sp_pallete_l1[3][6:0],1'b0};
			end
			
			if(|sp_xpos_cntr[4])sp_xpos_cntr[4]<=sp_xpos_cntr[4]-1'd1;
			else begin
				sp_pallete_l0[4]<={sp_pallete_l0[4][6:0],1'b0};
				sp_pallete_l1[4]<={sp_pallete_l1[4][6:0],1'b0};
			end
			
			if(|sp_xpos_cntr[5])sp_xpos_cntr[5]<=sp_xpos_cntr[5]-1'd1;
			else begin
				sp_pallete_l0[5]<={sp_pallete_l0[5][6:0],1'b0};
				sp_pallete_l1[5]<={sp_pallete_l1[5][6:0],1'b0};
			end
			
			if(|sp_xpos_cntr[6])sp_xpos_cntr[6]<=sp_xpos_cntr[6]-1'd1;
			else begin
				sp_pallete_l0[6]<={sp_pallete_l0[6][6:0],1'b0};
				sp_pallete_l1[6]<={sp_pallete_l1[6][6:0],1'b0};
			end
			
			if(|sp_xpos_cntr[7])sp_xpos_cntr[7]<=sp_xpos_cntr[7]-1'd1;
			else begin
				sp_pallete_l0[7]<={sp_pallete_l0[7][6:0],1'b0};
				sp_pallete_l1[7]<={sp_pallete_l1[7][6:0],1'b0};
			end
		end
	end
end

//-------------------------------------------------------------------------
///////////////////////////////RENDERING///////////////////////////////////
//-------------------------------------------------------------------------
wire		[3:0]spr0_color_index;
wire		[3:0]spr1_color_index;
wire		[3:0]spr2_color_index;
wire		[3:0]spr3_color_index;
wire		[3:0]spr4_color_index;
wire		[3:0]spr5_color_index;
wire		[3:0]spr6_color_index;
wire		[3:0]spr7_color_index;

wire		most_left_sprite = (dot_number > 9'd8 || show_sprite_left);

assign	spr0_color_index = (show_sprite && most_left_sprite) ? {sp_pallete_h[0],sp_pallete_l1[0][7],sp_pallete_l0[0][7]} : 4'b0000;
assign	spr1_color_index = (show_sprite && most_left_sprite) ? {sp_pallete_h[1],sp_pallete_l1[1][7],sp_pallete_l0[1][7]} : 4'b0000;
assign	spr2_color_index = (show_sprite && most_left_sprite) ? {sp_pallete_h[2],sp_pallete_l1[2][7],sp_pallete_l0[2][7]} : 4'b0000;
assign	spr3_color_index = (show_sprite && most_left_sprite) ? {sp_pallete_h[3],sp_pallete_l1[3][7],sp_pallete_l0[3][7]} : 4'b0000;
assign	spr4_color_index = (show_sprite && most_left_sprite) ? {sp_pallete_h[4],sp_pallete_l1[4][7],sp_pallete_l0[4][7]} : 4'b0000;
assign	spr5_color_index = (show_sprite && most_left_sprite) ? {sp_pallete_h[5],sp_pallete_l1[5][7],sp_pallete_l0[5][7]} : 4'b0000;
assign	spr6_color_index = (show_sprite && most_left_sprite) ? {sp_pallete_h[6],sp_pallete_l1[6][7],sp_pallete_l0[6][7]} : 4'b0000;
assign	spr7_color_index = (show_sprite && most_left_sprite) ? {sp_pallete_h[7],sp_pallete_l1[7][7],sp_pallete_l0[7][7]} : 4'b0000;

wire		[3:0]sp_color_index;
assign	sp_color_index		=	(~(|sp_xpos_cntr[0]) && (sp_pallete_l0[0][7] || sp_pallete_l1[0][7])) ? spr0_color_index : 
										(~(|sp_xpos_cntr[1]) && (sp_pallete_l0[1][7] || sp_pallete_l1[1][7])) ? spr1_color_index : 
										(~(|sp_xpos_cntr[2]) && (sp_pallete_l0[2][7] || sp_pallete_l1[2][7])) ? spr2_color_index : 
										(~(|sp_xpos_cntr[3]) && (sp_pallete_l0[3][7] || sp_pallete_l1[3][7])) ? spr3_color_index : 
										(~(|sp_xpos_cntr[4]) && (sp_pallete_l0[4][7] || sp_pallete_l1[4][7])) ? spr4_color_index : 
										(~(|sp_xpos_cntr[5]) && (sp_pallete_l0[5][7] || sp_pallete_l1[5][7])) ? spr5_color_index : 
										(~(|sp_xpos_cntr[6]) && (sp_pallete_l0[6][7] || sp_pallete_l1[6][7])) ? spr6_color_index : 
										(~(|sp_xpos_cntr[7]) && (sp_pallete_l0[7][7] || sp_pallete_l1[7][7])) ? spr7_color_index : 
										4'b0000;

wire		sp_priority_sel;
assign	sp_priority_sel	=	(~(|sp_xpos_cntr[0]) && (sp_pallete_l0[0][7] || sp_pallete_l1[0][7])) ? sp_priority[0] : 
										(~(|sp_xpos_cntr[1]) && (sp_pallete_l0[1][7] || sp_pallete_l1[1][7])) ? sp_priority[1] : 
										(~(|sp_xpos_cntr[2]) && (sp_pallete_l0[2][7] || sp_pallete_l1[2][7])) ? sp_priority[2] : 
										(~(|sp_xpos_cntr[3]) && (sp_pallete_l0[3][7] || sp_pallete_l1[3][7])) ? sp_priority[3] : 
										(~(|sp_xpos_cntr[4]) && (sp_pallete_l0[4][7] || sp_pallete_l1[4][7])) ? sp_priority[4] : 
										(~(|sp_xpos_cntr[5]) && (sp_pallete_l0[5][7] || sp_pallete_l1[5][7])) ? sp_priority[5] : 
										(~(|sp_xpos_cntr[6]) && (sp_pallete_l0[6][7] || sp_pallete_l1[6][7])) ? sp_priority[6] : 
										(~(|sp_xpos_cntr[7]) && (sp_pallete_l0[7][7] || sp_pallete_l1[7][7])) ? sp_priority[7] : 
										1'b0;		

wire		sp_zero_sel;
assign	sp_zero_sel			=	(~(|sp_xpos_cntr[0]) && (sp_pallete_l0[0][7] || sp_pallete_l1[0][7])) ? sp_zero[0] : 
										(~(|sp_xpos_cntr[1]) && (sp_pallete_l0[1][7] || sp_pallete_l1[1][7])) ? sp_zero[1] : 
										(~(|sp_xpos_cntr[2]) && (sp_pallete_l0[2][7] || sp_pallete_l1[2][7])) ? sp_zero[2] : 
										(~(|sp_xpos_cntr[3]) && (sp_pallete_l0[3][7] || sp_pallete_l1[3][7])) ? sp_zero[3] : 
										(~(|sp_xpos_cntr[4]) && (sp_pallete_l0[4][7] || sp_pallete_l1[4][7])) ? sp_zero[4] : 
										(~(|sp_xpos_cntr[5]) && (sp_pallete_l0[5][7] || sp_pallete_l1[5][7])) ? sp_zero[5] : 
										(~(|sp_xpos_cntr[6]) && (sp_pallete_l0[6][7] || sp_pallete_l1[6][7])) ? sp_zero[6] : 
										(~(|sp_xpos_cntr[7]) && (sp_pallete_l0[7][7] || sp_pallete_l1[7][7])) ? sp_zero[7] : 
										1'b0;	
										
wire 		[7:0]tile_shift1_low	=	tile_shif1[15:8];	
wire 		[7:0]tile_shift0_low	=	tile_shif0[15:8];	

wire		most_left_bg = (dot_number > 9'd8 || show_background_left);

wire		[3:0]bg_color_index;
assign	bg_color_index	= (show_background && most_left_bg) ? {palette_shif1[~fine_x_tmp],palette_shif0[~fine_x_tmp],
																				  tile_shift1_low[~fine_x_tmp],tile_shift0_low[~fine_x_tmp]}: 4'b0000;

												 														 
assign	pixel_color_index	=	((|sp_color_index[1:0] && ~sp_priority_sel) || 
										 (~|bg_color_index[1:0] && |sp_color_index[1:0])) ? 	{1'b1,sp_color_index} : 
																												{1'b0,bg_color_index};	
											
//-------------------------------------------------------------------------
reg	sprite_hit;
always@(posedge sysclk or negedge reset)begin
	if(!reset)sprite_hit<=0;
	else if(ppu_clock)begin
		if(pre_rendr_line)sprite_hit<=0;
		else if(|bg_color_index[1:0] && |sp_color_index[1:0] && sp_zero_sel)sprite_hit<=1'b1;
	end
end	
endmodule