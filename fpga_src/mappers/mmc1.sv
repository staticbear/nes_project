module	mmc1(
			  sysclk,
			  cpu_clock,
			  reset,
			  //
			  prg_len,
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


wire		mmc_write;
assign	mmc_write	=	cpu_bus[15] & cpu_wr;

assign	mirror		=	&mmc_control_mm;  //0 - vertical , 1 - horizontal
//--------------------------------------------------------------------------------
reg		[4:0]mmc_shift_reg;
always@(posedge sysclk or negedge reset)begin
	if(!reset)mmc_shift_reg<=5'b10000;
	else if(cpu_clock && mmc_write)begin
		if(cpu_data_in[7] || mmc_shift_reg[0])mmc_shift_reg<=5'b10000;
		else mmc_shift_reg<={cpu_data_in[0],mmc_shift_reg[4:1]};
	end
end
//--------------------------------------------------------------------------------
reg		[4:0]mmc_control;
always@(posedge sysclk or negedge reset)begin
	if(!reset)mmc_control<=0; 
	else if(cpu_clock && mmc_write)begin
		if(mmc_shift_reg[0] && cpu_bus[14:13] == 2'b00)mmc_control<={cpu_data_in[0],mmc_shift_reg[4:1]};
		else if(cpu_data_in[7])mmc_control<=mmc_control | 5'b01100;
	end
end

wire	mmc_control_c;			//CHR ROM bank mode
wire	[1:0]mmc_control_pp;	//PRG ROM bank mode
wire	[1:0]mmc_control_mm;	//Mirroring
assign	mmc_control_c	=	mmc_control[4];
assign	mmc_control_pp	=	mmc_control[3:2];
assign	mmc_control_mm	=	mmc_control[1:0];
//--------------------------------------------------------------------------------
reg		[4:0]mmc_chr_bank0;
always@(posedge sysclk or negedge reset)begin
	if(!reset)mmc_chr_bank0<=0;
	else if(cpu_clock && mmc_write && mmc_shift_reg[0] && cpu_bus[14:13] == 2'b01)begin
		mmc_chr_bank0<={cpu_data_in[0],mmc_shift_reg[4:1]};
	end
end
//--------------------------------------------------------------------------------
reg		[4:0]mmc_chr_bank1;
always@(posedge sysclk or negedge reset)begin
	if(!reset)mmc_chr_bank1<=0;
	else if(cpu_clock && mmc_write && mmc_shift_reg[0] && cpu_bus[14:13] == 2'b10)begin
		mmc_chr_bank1<={cpu_data_in[0],mmc_shift_reg[4:1]};
	end
end
//--------------------------------------------------------------------------------
reg		[4:0]mmc_prg_bank;
always@(posedge sysclk or negedge reset)begin
	if(!reset)mmc_prg_bank<=0;
	else if(cpu_clock && mmc_write && mmc_shift_reg[0] && cpu_bus[14:13] == 2'b11)begin
		mmc_prg_bank<={cpu_data_in[0],mmc_shift_reg[4:1]};
	end
end
//--------------------------------------------------------------------------------
reg		[4:0]last_prg_bank;
always@(posedge sysclk)begin
	if(!reset)last_prg_bank<=(prg_len[9:5] - 1'b1);
end
//--------------------------------------------------------------------------------
//memory manager  ppu
wire			[13:0]ppu_ram;
assign		ppu_ram				=	(ppu_bus[12] || ~mmc_control_mm[1]) ? ppu_bus : 								  
														(mmc_control_mm == 2'b10 ) ? {ppu_bus[13:12],1'b0,ppu_bus[10:0]}://vertical mirror
																							  {ppu_bus[13:11],1'b0,ppu_bus[9:0]} ;//horizontal mirror
																				
											
wire			[24:0]ppu_rom;
assign		ppu_rom				=	~mmc_control_c 	? { mmc_chr_bank0[3:1] , ppu_bus }:			   //switchable 8kb
												ppu_bus[12]		? { mmc_chr_bank1 	  , ppu_bus[11:0] } :	//switchable 4kb  on bank 1
																	  { mmc_chr_bank0 	  , ppu_bus[11:0]} ;		//switchable 4kb  on bank 0
												

assign		ext_ppu_bus			= 	ppu_bus[13] ? (25'h100000 | ppu_ram) : ppu_rom;
assign		ext_ppu_data_out	=	ppu_data_in;
assign		ext_ppu_wr			=	ppu_wr;

assign		ppu_data_out		=	ext_ppu_data_in;
//--------------------------------------------------------------------------------
//memory manager  cpu
wire		[24:0]mm_00_01;
wire		[24:0]mm_10;
wire		[24:0]mm_11;
assign		mm_00_01				=	{mmc_prg_bank,cpu_bus[14:0]};
assign		mm_10					=  cpu_bus[14] ? { mmc_prg_bank 	 , cpu_bus[13:0]} : 				//C000 - switchable 16kb 
																						cpu_bus[14:0];					//8000 - fix first bank
											 
assign		mm_11					=  cpu_bus[14] ?  { last_prg_bank , cpu_bus[13:0]}: 				//C000 - fix last bank
														      { mmc_prg_bank  , cpu_bus[13:0]};				//8000 - switchable 16kb 

wire			[24:0]cpu_rom;	
assign		cpu_rom				=	~mmc_control_pp[1] ? mm_00_01 :	//		0, 1: switch 32 KB at $8000, ignoring low bit of bank number;					
											 mmc_control_pp[0] ? mm_11 :		//		3: fix last bank at $C000 and switch 16 KB bank at $8000
																		mm_10;		//		2: fix first bank at $8000 and switch 16 KB bank at $C000;

wire			[24:0]cpu_ram;	
assign		cpu_ram				=	(25'h100000 | cpu_bus[14:0]);
																		
assign		ext_cpu_bus			=  cpu_bus[15] ? cpu_rom : cpu_ram;																	
assign		ext_cpu_data_out	=	cpu_data_in;
assign		ext_cpu_wr			=	cpu_bus[15] ? 1'b0 : cpu_wr;

assign		cpu_data_out		=	ext_cpu_data_in;


endmodule