module mmc3(
				 sysclk,
				 cpu_clock,
				 reset,
				 //
				 prg_len,
				 gen_irq,
				 mirror,
				 //cpu
				 cpu_bus,
				 cpu_wr,
				 cpu_data_in,
				 cpu_data_out,
				 //ppu
				 ppu_bus,
				 ppu_wr,
				 ppu_data_in,
				 ppu_data_out,
				 //external ram  cpu
				 ext_cpu_bus,
				 ext_cpu_data_in,
				 ext_cpu_data_out,
				 ext_cpu_wr,
				 //external ram ppu
				 ext_ppu_bus,
				 ext_ppu_data_in,
				 ext_ppu_data_out,
				 ext_ppu_wr
				);

input		sysclk;
input		cpu_clock;
input		reset;
//
input		[15:0]prg_len;
output	gen_irq;
output	mirror;
//cpu
input		[15:0]cpu_bus;
input		cpu_wr;
input		[7:0]cpu_data_in;
output	[7:0]cpu_data_out;
//ppu
input		[13:0]ppu_bus;
input		ppu_wr;
input		[7:0]ppu_data_in;
output	[7:0]ppu_data_out;
//memory manager  cpu
output	[24:0]ext_cpu_bus;
input		[7:0]ext_cpu_data_in;
output	[7:0]ext_cpu_data_out;
output	ext_cpu_wr;
//memory manager  ppu
output	[24:0]ext_ppu_bus;
input		[7:0]ext_ppu_data_in;
output	[7:0]ext_ppu_data_out;
output	ext_ppu_wr;

assign	mirror 	=	mirror_type;
//--------------------------------------------------------------------------------
wire		R0_write;
assign	R0_write	=	cpu_bus[15] & cpu_wr & (~|cpu_bus[14:13]) & (~cpu_bus[0]);

wire		R1_write;
assign	R1_write	=	cpu_bus[15] & cpu_wr & (~|cpu_bus[14:13]) & cpu_bus[0];

wire		R2_write;
assign	R2_write	=	cpu_bus[15] & cpu_wr & (cpu_bus[14:13] == 2'b01) & (~cpu_bus[0]);

wire		R3_write;
assign	R3_write	=	cpu_bus[15] & cpu_wr & (cpu_bus[14:13] == 2'b01) & cpu_bus[0];

wire		R4_write;
assign	R4_write	=	cpu_bus[15] & cpu_wr & (cpu_bus[14:13] == 2'b10) & (~cpu_bus[0]);

wire		R5_write;
assign	R5_write	=	cpu_bus[15] & cpu_wr & (cpu_bus[14:13] == 2'b10) & cpu_bus[0];

wire		R6_write;
assign	R6_write	=	cpu_bus[15] & cpu_wr & (&cpu_bus[14:13]) & (~cpu_bus[0]);

wire		R7_write;
assign	R7_write	=	cpu_bus[15] & cpu_wr & (&cpu_bus[14:13]) & cpu_bus[0];
//--------------------------------------------------------------------------------R0
/*
7  bit  0
---- ----
CPxx xRRR
||    |||
||    +++- Specify which bank register to update on next write to Bank Data register
||         0: Select 2 KB CHR bank at PPU $0000-$07FF (or $1000-$17FF);
||         1: Select 2 KB CHR bank at PPU $0800-$0FFF (or $1800-$1FFF);
||         2: Select 1 KB CHR bank at PPU $1000-$13FF (or $0000-$03FF);
||         3: Select 1 KB CHR bank at PPU $1400-$17FF (or $0400-$07FF);
||         4: Select 1 KB CHR bank at PPU $1800-$1BFF (or $0800-$0BFF);
||         5: Select 1 KB CHR bank at PPU $1C00-$1FFF (or $0C00-$0FFF);
||         6: Select 8 KB PRG ROM bank at $8000-$9FFF (or $C000-$DFFF);
||         7: Select 8 KB PRG ROM bank at $A000-$BFFF
|+-------- PRG ROM bank mode (0: $8000-$9FFF swappable,
|                                $C000-$DFFF fixed to second-last bank;
|                             1: $C000-$DFFF swappable,
|                                $8000-$9FFF fixed to second-last bank)
+--------- CHR A12 inversion (0: two 2 KB banks at $0000-$0FFF,
                                 four 1 KB banks at $1000-$1FFF;
                              1: two 2 KB banks at $1000-$1FFF,
                                 four 1 KB banks at $0000-$0FFF)
*/
reg		[7:0]bank_select;
always@(posedge sysclk or negedge reset)begin
	if(!reset)bank_select<=0;
	else if(cpu_clock && R0_write)begin
		bank_select<=cpu_data_in;
	end
end

wire		[2:0]wr_select = 	bank_select[2:0];
wire		prg_mode 		=  bank_select[6];
wire		inv_a12  		=  bank_select[7];
//--------------------------------------------------------------------------------R1
reg		[7:0]bank0;  //0: Select 2 KB CHR bank at PPU $0000-$07FF (or $1000-$17FF);
reg		[7:0]bank1;  //1: Select 2 KB CHR bank at PPU $0800-$0FFF (or $1800-$1FFF);
reg		[7:0]bank2;  //2: Select 1 KB CHR bank at PPU $1000-$13FF (or $0000-$03FF);
reg		[7:0]bank3;  //3: Select 1 KB CHR bank at PPU $1400-$17FF (or $0400-$07FF);
reg		[7:0]bank4;  //4: Select 1 KB CHR bank at PPU $1800-$1BFF (or $0800-$0BFF);
reg		[7:0]bank5;  //5: Select 1 KB CHR bank at PPU $1C00-$1FFF (or $0C00-$0FFF);
reg		[5:0]bank6;  //6: Select 8 KB PRG ROM bank at $8000-$9FFF (or $C000-$DFFF);
reg		[5:0]bank7;  //7: Select 8 KB PRG ROM bank at $A000-$BFFF
always@(posedge sysclk or negedge reset)begin
	if(!reset)begin
		bank0<=0; 
		bank1<=0; 
		bank2<=0; 
		bank3<=0; 
		bank4<=0; 
		bank5<=0; 
		bank6<=0; 
		bank7<=0; 
	end
	else if(cpu_clock && R1_write)begin
		case(wr_select)
			3'd0:bank0<=cpu_data_in;
			3'd1:bank1<=cpu_data_in;
			3'd2:bank2<=cpu_data_in;
			3'd3:bank3<=cpu_data_in;
			3'd4:bank4<=cpu_data_in;
			3'd5:bank5<=cpu_data_in;
			3'd6:bank6<=cpu_data_in[5:0] & bank_mask;
			3'd7:bank7<=cpu_data_in[5:0] & bank_mask;
		endcase
	end
end
//--------------------------------------------------------------------------------R2
reg		mirror_type;  //Mirroring (0: vertical; 1: horizontal)
always@(posedge sysclk or negedge reset)begin
	if(!reset)mirror_type<=0;
	else if(cpu_clock && R2_write)begin
		mirror_type<=cpu_data_in[0];
	end
end
//--------------------------------------------------------------------------------R3
/*
7  bit  0
---- ----
RWxx xxxx
||
|+-------- Write protection (0: allow writes; 1: deny writes)
+--------- Chip enable (0: disable chip; 1: enable chip)
*/
reg		prg_ram_protect;
always@(posedge sysclk or negedge reset)begin
	if(!reset)prg_ram_protect<=0;
	else if(cpu_clock && R3_write)begin
		prg_ram_protect<=cpu_data_in[6];
	end
end
//--------------------------------------------------------------------------------R4
reg		[7:0]irq_latch;
always@(posedge sysclk or negedge reset)begin
	if(!reset)irq_latch<=0;
	else if(cpu_clock && R4_write)begin
		irq_latch<=cpu_data_in;
	end
end
//--------------------------------------------------------------------------------R5
reg		[7:0]irq_counter;
always@(posedge sysclk or negedge reset)begin
	if(!reset)irq_counter<=0;
	else begin
		if(ppu_tick)begin
			if(~|irq_counter || irq_rld)irq_counter<=irq_latch;
			else irq_counter<=irq_counter-1'd1;
		end
	end
end

reg		irq_rld;
always@(posedge sysclk or negedge reset)begin
	if(!reset)irq_rld<=0;
	else if(cpu_clock && R5_write)irq_rld<=1;
	else if(ppu_tick)irq_rld<=0;
end

reg		[1:0]sv_a12;
always@(posedge sysclk)sv_a12<={sv_a12[0],ppu_bus[12]};

wire		ppu_tick;
assign	ppu_tick = ~sv_a12[1] & sv_a12[0];

reg		[1:0]old_icnt;
always@(posedge sysclk)old_icnt<={old_icnt[0],|irq_counter};

assign	gen_irq	=	~(old_icnt[1] & ~old_icnt[0] & irq_enable);
//--------------------------------------------------------------------------------R6/R7
reg		irq_enable;    //1-enable , 0-disable
always@(posedge sysclk or negedge reset)begin
	if(!reset)irq_enable<=0;
	else if(cpu_clock)begin
		if(R6_write)irq_enable<=0;
		else if(R7_write)irq_enable<=1'b1;
	end
end
//--------------------------------------------------------------------------------
reg		[15:0]fl_prg_bank;
always@(posedge sysclk)begin
	if(!reset)fl_prg_bank<=(prg_len - (2'b01<<4));
end
//--------------------------------------------------------------------------------
reg		[15:0]sl_prg_bank;
always@(posedge sysclk)begin
	if(!reset)sl_prg_bank<=(prg_len - (2'b10<<4));
end

reg		[5:0]bank_mask;			//for turtles!
always@(posedge sysclk)begin
	bank_mask<=prg_len[9:4] - 1'd1;
end
//--------------------------------------------------------------------------------
//memory manager  cpu
wire		[24:0]cpu_sel_0;
assign	cpu_sel_0	=	prg_mode ? {sl_prg_bank , 9'b0} : {bank6 , 13'b0};

wire		[24:0]cpu_sel_1;
assign	cpu_sel_1	=	{bank7 , 13'b0};

wire		[24:0]cpu_sel_2;
assign	cpu_sel_2	=	prg_mode ? {bank6 , 13'b0} : {sl_prg_bank , 9'b0};

wire		[24:0]cpu_sel_3;
assign	cpu_sel_3	=	{fl_prg_bank , 9'b0};
/*
When $8000 & #$40 	is 0 	is #$40
CPU Bank 	   Value of MMC3 register 
$8000-$9FFF 	      R6 	(-2)
$A000-$BFFF 	      R7 	 R7
$C000-$DFFF 	     (-2) 	 R6
$E000-$FFFF 	     (-1) 	(-1) 
*/

wire		[24:0]sel_cpu_bank;
assign	sel_cpu_bank		=	(~|cpu_bus[14:13]) 			? 	cpu_sel_0 :	//$8000-$9FFF 
										(cpu_bus[14:13] == 2'b01) 	? 	cpu_sel_1 :	//$A000-$BFFF
										(cpu_bus[14:13] == 2'b10) 	?	cpu_sel_2 :	//$C000-$DFFF
																				cpu_sel_3 ;	//$E000-$FFFF
wire		[24:0]cpu_rom;
assign	cpu_rom				=	(sel_cpu_bank | cpu_bus[12:0]);
wire		[24:0]cpu_ram;
assign	cpu_ram				=	(25'h100000 | cpu_bus[14:0]);											
																				
assign	ext_cpu_bus			=	cpu_bus[15] ? cpu_rom : cpu_ram; 
assign	ext_cpu_data_out	=	cpu_data_in;
assign	ext_cpu_wr			=	cpu_bus[15] ? 1'b0 : cpu_wr & (~prg_ram_protect);

assign	cpu_data_out		=	ext_cpu_data_in;

//--------------------------------------------------------------------------------
//memory manager  ppu
wire		[13:0]ppu_ram;
assign	ppu_ram				=	(~mirror_type ) ?	{ppu_bus[13:12],1'b0,ppu_bus[10:0]}://vertical mirror
																{ppu_bus[13:11],1'b0,ppu_bus[9:0]} ;//horizontal mirror
/*
When $8000 & #$80 	is 0 				is #$80
PPU Bank 				Value of MMC3 register
$0000-$03FF 			R0 AND $FE 		R2
$0400-$07FF 			R0 OR 1 			R3
$0800-$0BFF 			R1 AND $FE 		R4
$0C00-$0FFF 			R1 OR 1 			R5
$1000-$13FF 			R2 				R0 AND $FE
$1400-$17FF 			R3 				R0 OR 1
$1800-$1BFF 			R4 				R1 AND $FE
$1C00-$1FFF 			R5 				R1 OR 1 
*/																

wire		[24:0]ppu_sel_0;
assign	ppu_sel_0 = inv_a12 ? {bank2 , 10'b0} : {bank0[7:1] , 1'b0 , 10'b0};

wire		[24:0]ppu_sel_1;
assign	ppu_sel_1 = inv_a12 ? {bank3 , 10'b0} : {bank0[7:1] , 1'b1 , 10'b0};

wire		[24:0]ppu_sel_2;
assign	ppu_sel_2 = inv_a12 ? {bank4 , 10'b0} : {bank1[7:1] , 1'b0 , 10'b0};

wire		[24:0]ppu_sel_3;
assign	ppu_sel_3 = inv_a12 ? {bank5 , 10'b0} : {bank1[7:1] , 1'b1 , 10'b0};

wire		[24:0]ppu_sel_4;
assign	ppu_sel_4 = inv_a12 ? {bank0[7:1] , 1'b0 , 10'b0} : {bank2 , 10'b0};

wire		[24:0]ppu_sel_5;
assign	ppu_sel_5 = inv_a12 ? {bank0[7:1] , 1'b1 , 10'b0} : {bank3 , 10'b0};

wire		[24:0]ppu_sel_6;
assign	ppu_sel_6 = inv_a12 ? {bank1[7:1] , 1'b0 , 10'b0} : {bank4 , 10'b0};

wire		[24:0]ppu_sel_7;
assign	ppu_sel_7 = inv_a12 ? {bank1[7:1] , 1'b1 , 10'b0} : {bank5 , 10'b0};


wire		[24:0]sel_ppu_bank;
assign	sel_ppu_bank = (~|ppu_bus[12:10]) 			? 	ppu_sel_0 :	//$0000-$03FF 
								(ppu_bus[12:10] == 3'b001)	? 	ppu_sel_1 :	//$0400-$07FF 
								(ppu_bus[12:10] == 3'b010)	? 	ppu_sel_2 :	//$0800-$0BFF 
								(ppu_bus[12:10] == 3'b011)	? 	ppu_sel_3 :	//$0C00-$0FFF
								(ppu_bus[12:10] == 3'b100)	? 	ppu_sel_4 :	//$1000-$13FF
								(ppu_bus[12:10] == 3'b101)	? 	ppu_sel_5 :	//$1400-$17FF
								(ppu_bus[12:10] == 3'b110)	? 	ppu_sel_6 :	//$1800-$1BFF
																		ppu_sel_7 ;	//$1C00-$1FFF

wire		[24:0]ppu_rom;
assign	ppu_rom = {sel_ppu_bank[24:10] , ppu_bus[9:0]};


assign	ext_ppu_bus			= 	ppu_bus[13] ? (25'h100000 | ppu_ram) : ppu_rom;
assign	ext_ppu_data_out	=	ppu_data_in;
assign	ext_ppu_wr			=	ppu_wr;

assign	ppu_data_out		=	ext_ppu_data_in;

endmodule