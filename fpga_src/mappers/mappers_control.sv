module mappers_control(
								sysclk,
								cpu_clock,
								reset,
								//
								mc_irq,
								//
								mc_prg_len,  	
								mc_chr_len,	
								mc_mapper_type,
								mc_solder_mirror,
								mc_four_screen,
								//cpu
								mc_cpu_bus,
								mc_cpu_wr,
								mc_cpu_data_in,
								mc_cpu_data_out,
							   //ppu
								mc_ppu_bus,
								mc_ppu_wr,
								mc_ppu_data_in,
								mc_ppu_data_out,
								//to sdram cpu part
								sdram_cpu_bus,
							   sdram_cpu_data_in,
							   sdram_cpu_data_out,
							   sdram_cpu_wr,
							   //to sdram ppu part
							   sdram_ppu_bus,
							   sdram_ppu_data_in,
							   sdram_ppu_data_out,
							   sdram_ppu_wr,
								//to internal ram ppu part
								iram_ppu_bus,
								iram_ppu_data_out,
							   iram_ppu_data_in0,
							   iram_ppu_data_in1,
								iram_ppu_data_in2,
								iram_ppu_data_in3,
							   iram_ppu_wr0,
								iram_ppu_wr1,
								iram_ppu_wr2,
								iram_ppu_wr3
							);
input		sysclk;
input		cpu_clock;
input		reset;
//
output	mc_irq;
//
input		[15:0]mc_prg_len;
input		[15:0]mc_chr_len;
input		[3:0]mc_mapper_type;
input		mc_solder_mirror;
input		mc_four_screen;
//cpu
input		[15:0]mc_cpu_bus;
input		mc_cpu_wr;
input		[7:0]mc_cpu_data_in;
output	[7:0]mc_cpu_data_out;
//ppu
input		[13:0]mc_ppu_bus;
input		mc_ppu_wr;
input		[7:0]mc_ppu_data_in;
output	[7:0]mc_ppu_data_out;
//to sdram cpu part
output	[24:0]sdram_cpu_bus;
input		[7:0]sdram_cpu_data_in;
output	[7:0]sdram_cpu_data_out;
output	sdram_cpu_wr;
//to sdram ppu part
output	[24:0]sdram_ppu_bus;
input		[7:0]sdram_ppu_data_in;
output	[7:0]sdram_ppu_data_out;
output	sdram_ppu_wr;
//to internal ram ppu part
output	[9:0]iram_ppu_bus;
output	[7:0]iram_ppu_data_out;
input		[7:0]iram_ppu_data_in0;
input		[7:0]iram_ppu_data_in1;
input		[7:0]iram_ppu_data_in2;
input		[7:0]iram_ppu_data_in3;
output	iram_ppu_wr0;
output	iram_ppu_wr1;
output	iram_ppu_wr2;
output	iram_ppu_wr3;


reg		[3:0]mapper_type;
always@(posedge sysclk)if(!reset)mapper_type<=mc_mapper_type;
//--------------------------------------------------------------------------------
//                                      NONE mapper type 0
//--------------------------------------------------------------------------------
wire		[24:0]ext_none_cbus		= mc_cpu_bus[15] ? mc_cpu_bus[14:0] : (25'h100000 | mc_cpu_bus[14:0]);
wire		[7:0]ext_none_cdataout	= mc_cpu_data_in;
wire		ext_none_cwr				= mc_cpu_wr;

wire		[13:0]ppu_ram;
assign	ppu_ram						= ( mc_ppu_bus[12] )  ? mc_ppu_bus :										//3000 - 3FFF
											 (~mc_solder_mirror ) ? {mc_ppu_bus[13:12],1'b0,mc_ppu_bus[10:0]}://vertical mirror
																		   {mc_ppu_bus[13:11],1'b0,mc_ppu_bus[9:0]} ;//horizontal mirror
																		 
wire		[24:0]ext_none_pbus		= mc_ppu_bus[13] ? (25'h100000 | ppu_ram) : mc_ppu_bus;
wire		[7:0]ext_none_pdataout	= mc_ppu_data_in;
wire		ext_none_pwr				= mc_ppu_wr;

wire		[7:0]none_cpu_dataout 	= sdram_cpu_data_in;
wire		[7:0]none_ppu_dataout;
assign	none_ppu_dataout 		 	= mc_ppu_bus[13] ? iram_ppu_data_in : sdram_ppu_data_in;
//--------------------------------------------------------------------------------
//                                      MMC1 mapper type 1
//--------------------------------------------------------------------------------
wire		[24:0]ext_mmc1_cbus;
wire		[7:0]ext_mmc1_cdatain 	= sdram_cpu_data_in;
wire		[7:0]ext_mmc1_cdataout;
wire		ext_mmc1_cwr;

wire		[24:0]ext_mmc1_pbus;
wire		[7:0]ext_mmc1_pdatain;
assign	ext_mmc1_pdatain 			= mc_ppu_bus[13] ? iram_ppu_data_in : sdram_ppu_data_in;
wire		[7:0]ext_mmc1_pdataout;
wire		ext_mmc1_pwr;

wire		[7:0]mmc1_cpu_dataout;
wire		[7:0]mmc1_ppu_dataout;

wire		mmc1_mirror;
mmc1	m_mmc1(
			  .sysclk(sysclk),
			  .cpu_clock(cpu_clock),
			  .reset(reset),
			  //
			  .prg_len(mc_prg_len),
			  .mirror(mmc1_mirror),
			   //cpu
			  .cpu_bus(mc_cpu_bus),
			  .cpu_wr(mc_cpu_wr),
			  .cpu_data_in(mc_cpu_data_in),
			  .cpu_data_out(mmc1_cpu_dataout),
			  //ppu
			  .ppu_bus(mc_ppu_bus),
			  .ppu_wr(mc_ppu_wr),
			  .ppu_data_in(mc_ppu_data_in),
			  .ppu_data_out(mmc1_ppu_dataout),
			  //external ram  cpu
			  .ext_cpu_bus(ext_mmc1_cbus),
			  .ext_cpu_data_in(ext_mmc1_cdatain),
			  .ext_cpu_data_out(ext_mmc1_cdataout),
			  .ext_cpu_wr(ext_mmc1_cwr),
			  //external ram ppu
			  .ext_ppu_bus(ext_mmc1_pbus),
			  .ext_ppu_data_in(ext_mmc1_pdatain),
			  .ext_ppu_data_out(ext_mmc1_pdataout),
			  .ext_ppu_wr(ext_mmc1_pwr)
			);
//--------------------------------------------------------------------------------
//                                      MMC3 mapper type 4
//--------------------------------------------------------------------------------	
wire		[24:0]ext_mmc3_cbus;
wire		[7:0]ext_mmc3_cdatain 	= sdram_cpu_data_in;
wire		[7:0]ext_mmc3_cdataout;
wire		ext_mmc3_cwr;

wire		[24:0]ext_mmc3_pbus;
wire		[7:0]ext_mmc3_pdatain;
assign	ext_mmc3_pdatain 			= mc_ppu_bus[13] ? iram_ppu_data_in : sdram_ppu_data_in;
wire		[7:0]ext_mmc3_pdataout;
wire		ext_mmc3_pwr;

wire		[7:0]mmc3_cpu_dataout;
wire		[7:0]mmc3_ppu_dataout;	
wire		mmc3_mirror;		
mmc3 m_mmc3(
				 .sysclk(sysclk),
			    .cpu_clock(cpu_clock),
			    .reset(reset),
				 //
				 .prg_len(mc_prg_len),
				 .gen_irq(mc_irq),
				 .mirror(mmc3_mirror),
				 //cpu
				 .cpu_bus(mc_cpu_bus),
			    .cpu_wr(mc_cpu_wr),
			    .cpu_data_in(mc_cpu_data_in),
			    .cpu_data_out(mmc3_cpu_dataout),
			    //ppu
			    .ppu_bus(mc_ppu_bus),
			    .ppu_wr(mc_ppu_wr),
			    .ppu_data_in(mc_ppu_data_in),
			    .ppu_data_out(mmc3_ppu_dataout),
				 //external ram  cpu
				 .ext_cpu_bus(ext_mmc3_cbus),
				 .ext_cpu_data_in(ext_mmc3_cdatain),
				 .ext_cpu_data_out(ext_mmc3_cdataout),
				 .ext_cpu_wr(ext_mmc3_cwr),
				 //external ram ppu
				 .ext_ppu_bus(ext_mmc3_pbus),
				 .ext_ppu_data_in(ext_mmc3_pdatain),
				 .ext_ppu_data_out(ext_mmc3_pdataout),
				 .ext_ppu_wr(ext_mmc3_pwr)
				);
//--------------------------------------------------------------------------------
//                                      AOROM mapper type 7
//--------------------------------------------------------------------------------
wire		[24:0]ext_aorom_cbus;
wire		[7:0]ext_aorom_cdatain 	= sdram_cpu_data_in;
wire		[7:0]ext_aorom_cdataout;
wire		ext_aorom_cwr;

wire		[24:0]ext_aorom_pbus;
wire		[7:0]ext_aorom_pdatain;
assign	ext_aorom_pdatain 		= sdram_ppu_data_in;
wire		[7:0]ext_aorom_pdataout;
wire		ext_aorom_pwr;

wire		[7:0]aorom_cpu_dataout;
wire		[7:0]aorom_ppu_dataout;

aorom m_aorom(
				 .sysclk(sysclk),
			    .cpu_clock(cpu_clock),
			    .reset(reset),
				  //cpu
				 .cpu_bus(mc_cpu_bus),
			    .cpu_wr(mc_cpu_wr),
			    .cpu_data_in(mc_cpu_data_in),
			    .cpu_data_out(aorom_cpu_dataout),
			    //ppu
			    .ppu_bus(mc_ppu_bus),
			    .ppu_wr(mc_ppu_wr),
			    .ppu_data_in(mc_ppu_data_in),
			    .ppu_data_out(aorom_ppu_dataout),
				 //external ram  cpu
				 .ext_cpu_bus(ext_aorom_cbus),
				 .ext_cpu_data_in(ext_aorom_cdatain),
				 .ext_cpu_data_out(ext_aorom_cdataout),
				 .ext_cpu_wr(ext_aorom_cwr),
				 //external ram ppu
				 .ext_ppu_bus(ext_aorom_pbus),
				 .ext_ppu_data_in(ext_aorom_pdatain),
				 .ext_ppu_data_out(ext_aorom_pdataout),
				 .ext_ppu_wr(ext_aorom_pwr)
				);	
//--------------------------------------------------------------------------------
//                                      SELECTORS CPU & PPU
//--------------------------------------------------------------------------------	
//cpu selectors
assign	mc_cpu_data_out		=	(mapper_type == 4'd1) ?	mmc1_cpu_dataout : 
											(mapper_type == 4'd4) ?	mmc3_cpu_dataout : 
											(mapper_type == 4'd7) ?	aorom_cpu_dataout: 
																			none_cpu_dataout;
		
assign	sdram_cpu_bus 			= (mapper_type == 4'd1) ?	ext_mmc1_cbus : 
										  (mapper_type == 4'd4) ?	ext_mmc3_cbus : 
										  (mapper_type == 4'd7) ?	ext_aorom_cbus: 
																			ext_none_cbus;
	
assign	sdram_cpu_data_out 	= (mapper_type == 4'd1) ?	ext_mmc1_cdataout : 
										  (mapper_type == 4'd4) ?	ext_mmc3_cdataout : 
										  (mapper_type == 4'd7) ?	ext_aorom_cdataout: 
																			ext_none_cdataout;

assign	sdram_cpu_wr			=	(mapper_type == 4'd1) ? ext_mmc1_cwr : 
											(mapper_type == 4'd4) ? ext_mmc3_cwr :
											(mapper_type == 4'd7) ? ext_aorom_cwr:
																			ext_none_cwr;
																																			
//ppu selectors																		
assign	mc_ppu_data_out		=	(mapper_type == 4'd1) ?	mmc1_ppu_dataout : 
											(mapper_type == 4'd4) ?	mmc3_ppu_dataout : 
											(mapper_type == 4'd7) ?	aorom_ppu_dataout: 
																			none_ppu_dataout;	
																			  
assign	sdram_ppu_bus 			= (mapper_type == 4'd1) ? 	ext_mmc1_pbus : 
										  (mapper_type == 4'd4) ? 	ext_mmc3_pbus : 
										  (mapper_type == 4'd7) ? 	ext_aorom_pbus: 
																			ext_none_pbus;	
														
assign	sdram_ppu_data_out	= (mapper_type == 4'd1) ? 	ext_mmc1_pdataout : 
										  (mapper_type == 4'd4) ? 	ext_mmc3_pdataout : 
										  (mapper_type == 4'd7) ? 	ext_aorom_pdataout: 
																			ext_none_pdataout;

assign	sdram_ppu_wr			=	(mapper_type == 4'd1) ? ext_mmc1_pwr : 
											(mapper_type == 4'd4) ? ext_mmc3_pwr : 
											(mapper_type == 4'd7) ? ext_aorom_pwr: 
																			ext_none_pwr;			
																		
				
wire		mirror_type;//0 - vertical , 1 - horizontal		
assign	mirror_type				=	(mapper_type == 4'd1) ? mmc1_mirror : 
											(mapper_type == 4'd4) ? mmc3_mirror : 
																			mc_solder_mirror;	
																			
assign	iram_ppu_bus			= 	mc_ppu_bus[9:0];
assign	iram_ppu_data_out 	= 	sdram_ppu_data_out;



wire		[7:0]iram_ppu_data_in;
assign	iram_ppu_data_in		=	(mc_ppu_bus[11:10] == 2'd0) ? iram_ppu_data_in0 : 
											(mc_ppu_bus[11:10] == 2'd1) ? iram_ppu_data_in1 : 
											(mc_ppu_bus[11:10] == 2'd2) ? iram_ppu_data_in2 : 
																					iram_ppu_data_in3 ; 

assign	iram_ppu_wr0			= (mc_ppu_bus[11:10] == 2'd0 || 									//2000 - 23FF
										  (mc_ppu_bus[11:10] == 2'd1 && mirror_type) ||
										  (mc_ppu_bus[11:10] == 2'd2 && ~mirror_type)) ? sdram_ppu_wr : 1'b0;

										  
assign	iram_ppu_wr1			= (mc_ppu_bus[11:10] == 2'd1 || 									//2400 - 27FF
										  (mc_ppu_bus[11:10] == 2'd0 && mirror_type) ||
										  (~&mc_ppu_bus[13:8] && mc_ppu_bus[11:10] == 2'd3 && ~mirror_type)) ?  sdram_ppu_wr : 1'b0;
										
										
assign	iram_ppu_wr2			= (mc_ppu_bus[11:10] == 2'd2 || 									//2800 - 2BFF
										  (~&mc_ppu_bus[13:8] && mc_ppu_bus[11:10] == 2'd3 && mirror_type) ||
										  (mc_ppu_bus[11:10] == 2'd0 && ~mirror_type)) ?  sdram_ppu_wr : 1'b0;
										  
										  
assign	iram_ppu_wr3			= ((~&mc_ppu_bus[13:8] && mc_ppu_bus[11:10] == 2'd3) || 	//2C00 - 2FFF
										  (mc_ppu_bus[11:10] == 2'd2 && mirror_type) ||
										  (mc_ppu_bus[11:10] == 2'd1 && ~mirror_type)) ?  sdram_ppu_wr : 1'b0;

endmodule