module nes_main(
						ref_clk,
						//vga
						vga_clk,
						vga_r,
						vga_g,
						vga_b,
						vga_hs,
						vga_vs,
						vga_blank,
						vga_sync,
						//audio
						audio_xck,
						audio_daclrck,
						audio_dacdat, 
						audio_bclk,
						audio_i2c_clk,
						audio_i2c_data,
						//sdram
						sdram_addr,
						sdram_dq,
						sdram_ba,
						sdram_ldqm,
						sdram_udqm,
						sdram_ras_n,
						sdram_cas_n,
						sdram_cke,
						sdram_clk,
						sdram_we_n,
						sdram_cs_n,
						//sdcard
						sdcard_cs,
						sdcard_sclk,
						sdcard_mosi,
						sdcard_miso,
						//joysticks
						joy_latch,
						joy_pulse,
						joy_data0,
						//7seg
						digit0,
						digit1,
						digit2,
						digit3,
						//audio indicator led
						leds
					);
(* chip_pin = "AF14" *)input  ref_clk;  //50MHz
//vga
(* chip_pin = "A11" *)output  vga_clk;  //25MHz
(* chip_pin = "F13,E12,D12,C12,B12,E13,C13,A13" *)output [7:0]vga_r;
(* chip_pin = "E11,F11,G12,G11,G10,H12,J10,J9" *) output [7:0]vga_g;
(* chip_pin = "J14,G15,F15,H14,F14,H13,G13,B13" *)output [7:0]vga_b;
(* chip_pin = "B11" *)output vga_hs;
(* chip_pin = "D11" *)output vga_vs;
(* chip_pin = "F10" *)output vga_blank;
(* chip_pin = "C10" *)output vga_sync;
//audio
(* chip_pin = "G7" *) output audio_xck;
(* chip_pin = "H8" *) output audio_daclrck; 
(* chip_pin = "J7" *) output audio_dacdat; 
(* chip_pin = "H7" *) output audio_bclk;
(* chip_pin = "J12" *)output audio_i2c_clk;
(* chip_pin = "K12" *)inout  audio_i2c_data;
//sdram
(* chip_pin = "AJ14,AH13,AG12,AG13,AH15,AF15,AD14,AC14,AB15,AE14,AG15,AH14,AK14" *) output [12:0]sdram_addr;
(* chip_pin = "AJ5,AJ6,AH7,AH8,AH9,AJ9,AJ10,AH10,AJ11,AK11,AG10,AK9,AK8,AK7,AJ7,AK6" *) inout [15:0]sdram_dq;
(* chip_pin = "AJ12,AF13" *) output [1:0]sdram_ba;
(* chip_pin = "AB13" *)  output sdram_ldqm;
(* chip_pin = "AK12" *)  output sdram_udqm;
(* chip_pin = "AE13" *)  output sdram_ras_n;
(* chip_pin = "AF11" *)  output sdram_cas_n;
(* chip_pin = "AK13" *)  output sdram_cke;
(* chip_pin = "AH12" *)  output sdram_clk;
(* chip_pin = "AA13" *)  output sdram_we_n;
(* chip_pin = "AG11" *)  output sdram_cs_n;
//sdcard
(* chip_pin = "AC18" *)output  sdcard_cs;  
(* chip_pin = "AK16" *)output  sdcard_sclk; 
(* chip_pin = "AD17" *)output  sdcard_mosi;  
(* chip_pin = "AK19" *)input   sdcard_miso;
//joysticks
(* chip_pin = "AB21" *)  output joy_latch;
(* chip_pin = "AD24" *)  output joy_pulse;
(* chip_pin = "AB17" *)	 input  joy_data0;
//7seg
(* chip_pin = "AH28,AG28,AF28,AG27,AE28,AE27,AE26" *)output	[6:0]digit0;
(* chip_pin = "AD27,AF30,AF29,AG30,AH30,AH29,AJ29" *)output	[6:0]digit1;
(* chip_pin = "AC30,AC29,AD30,AC28,AD29,AE29,AB23" *)output	[6:0]digit2;
(* chip_pin = "AB22,AB25,AB28,AC25,AD25,AC27,AD26" *)output	[6:0]digit3;
//leds
(* chip_pin = "Y21,W21,W20,Y19,W19,W17,V18,V17,W16,V16" *)output	[9:0]leds;



assign	 	audio_xck	= audio_clock;	
assign		vga_clk		=	vga_clock;
assign 		vga_sync 	= 0;
assign		sdram_clk 	= sysclk;
assign		leds 			= {4'b0,cpu_sound_out};
//--------------------------------------------------------------------------------
wire sysclk;
wire audio_clock;
wire reset;

syspll_new syspll_new_0(
		.refclk(ref_clk),   		
		.rst(1'b0),      			
		.outclk_0(sysclk), 	
		.outclk_1(audio_clock), 
		.locked(reset)    		
	);	
	
wire	cpu_clock;
clock_gen #(8'd6,6'd57-6'd1)clock_gen_cpu(
						.ref_clk(sysclk),			
						.reset(reset),
						.pulse_out(cpu_clock)			
					 );
					 
wire	ppu_clock;
clock_gen #(8'd5,5'd19-5'd1)clock_gen_ppu(
						.ref_clk(sysclk),			
						.reset(reset),
						.pulse_out(ppu_clock)			
					 );
					 
wire	vga_clock;
clock_gen #(8'd3,3'd4-3'd1)clock_gen_vga(
						.ref_clk(sysclk),			
						.reset(reset),
						.pulse_out(vga_clock)			
					 );

wire pulse1MHz;
clock_gen #(8'd8,8'd100 - 8'd1)clock_gen_debug(
						.ref_clk(sysclk),			
						.reset(reset),
						.pulse_out(pulse1MHz)			
					 );
//--------------------------------------------------------------------------------
wire 		[15:0]cpu_addr_bus;	
wire 		[7:0]cpu_data_out;	
wire 		[7:0]cpu_data_in;
assign	cpu_data_in = ppu_cs ? ppu_ioreg_dataout : mc_cpu_data_out;
wire 		cpu_wr;
wire		[5:0]cpu_sound_out;	

wire		load_dump;
wire		[3:0]mapper_type;
wire		[31:0]dump_offset;
wire		[15:0]dump_prg_len;
wire		[15:0]dump_chr_len;

cpu	 m_cpu(
				.sysclk(sysclk),
				.cpu_clock(cpu_clock),		//
				.delay_clock(pulse1MHz),	//1MHz
				.gen_reset(dl_gen_reset),
				.pll_reset(reset),
				.cpu_irq(mc_irq),
				.cpu_nmi(ppu_nmi),
				.cpu_addr_bus(cpu_addr_bus),
				.cpu_wr(cpu_wr),
				.cpu_data_in(cpu_data_in),
				.cpu_data_out(cpu_data_out),
				//for debug
				.cpu_unk_cmd(),
				//apu
				.cpu_sound_out(cpu_sound_out),
				//joysticks data
				.jc_fifo_empty(jc_fifo_empty),
				.jc_fifo_rdreq(jc_fifo_rdreq),
				.jc_fifo_q(jc_fifo_q),
				//reload signal for dump loader
				.load_dump(load_dump),
				.mapper_type(mapper_type),
				.solder_mirror(),
				.dump_offset(dump_offset),
				.dump_prg_len(dump_prg_len),
				.dump_chr_len(dump_chr_len)
				);
				
				
nes_joystick m_nes_joystick(
									.sysclk(sysclk),
									.cpu_clock(cpu_clock),
									.reset(dl_gen_reset),
									//sync
									.fifo_empty(jc_fifo_empty),
									.fifo_wrreq(jc_fifo_wrreq),
									.fifo_data(jc_fifo_data),
									//phy
									.joy_latch(joy_latch),
									.joy_pulse(joy_pulse),
									.joy_data0(~joy_data0),
									.joy_data1(1'b0)
									);
wire		jc_fifo_wrreq;
wire		[15:0]jc_fifo_data;	
wire		jc_fifo_empty;
wire		jc_fifo_rdreq;
wire		[15:0]jc_fifo_q;
wire		jc_fifo_full;

fifo_16x16 jc_fifo_16x16(
	.clock(sysclk),
	.data(jc_fifo_data),
	.rdreq(jc_fifo_rdreq),
	.wrreq(jc_fifo_wrreq && ~jc_fifo_full),
	.empty(jc_fifo_empty),
	.full(jc_fifo_full),
	.q(jc_fifo_q)
	);
//--------------------------------------------------------------------------------
wire afs_wrfull;
wire afs_rdempty;
fifo_16x16_2clk audio_fifo_sync(
	.data({2'b0,cpu_sound_out,8'b0}),
	.rdclk(audio_clock),
	.rdreq(sndm_fifo_rdreq & !afs_rdempty),
	.wrclk(sysclk),
	.wrreq(1'b1 & !afs_wrfull & cpu_clock),
	.q(sndm_fifo_data),
	.rdempty(afs_rdempty),
	.wrfull(afs_wrfull)
	);	
//--------------------------------------------------------------------------------		
wire	sndm_fifo_rdreq;
wire 	[15:0]sndm_fifo_data;		
sound_manager 	m_sound_manager(
							.clk(audio_clock),				//	18.432	MHz
							.reset(reset),
							//audio samples
							.audio_fifo_rdreq(sndm_fifo_rdreq),
							.audio_fifo_data(sndm_fifo_data),
							//physical interface		
							.audio_daclrck(audio_daclrck),
							.audio_dacdat(audio_dacdat),
							.audio_bclk(audio_bclk),	  
							.audio_i2c_clk(audio_i2c_clk),
							.audio_i2c_data(audio_i2c_data)
                   );
//--------------------------------------------------------------------------------	
wire		ppu_cs						= ~(|cpu_addr_bus[15:14]) & cpu_addr_bus[13];
wire		[2:0]ppu_ioreg_addr	 	= cpu_addr_bus[2:0];
wire		[7:0]ppu_ioreg_datain 	= cpu_data_out;
wire		[7:0]ppu_ioreg_dataout;
wire		ppu_ioreg_wr			 	= cpu_wr;
wire		ppu_nmi;
wire		ppu_v_blank;

wire		[13:0]ppu_addr_bus;
wire		[7:0]ppu_data_in = mc_ppu_data_out;
wire		[7:0]ppu_data_out;
wire		ppu_wr;

wire		[7:0]ppu_oam_addrout;
wire		[7:0]ppu_oam_datain;
wire		[7:0]ppu_oam_dataout;
wire		ppu_oam_wr;

wire		[15:0]ppu_color_addr;
wire		[7:0]ppu_color_data;
wire		ppu_color_wren;

ppu	m_ppu(	
				.sysclk(sysclk),
				.cpu_clock(cpu_clock),
				.ppu_clock(ppu_clock),			//5.369318MHz  5369318
				.reset(dl_gen_reset),
				///
				.ppu_cs(ppu_cs),
				//
				.ioreg_addr(ppu_ioreg_addr),
				.ioreg_datain(ppu_ioreg_datain),
				.ioreg_dataout(ppu_ioreg_dataout),
				.ioreg_wr(ppu_ioreg_wr),
				//
				.ppu_addr_bus(ppu_addr_bus),
				.ppu_data_in(ppu_data_in),
				.ppu_data_out(ppu_data_out),
				.ppu_wr(ppu_wr),
				//
				.oam_addrout(ppu_oam_addrout),
				.oam_datain(ppu_oam_datain),
				.oam_dataout(ppu_oam_dataout),
				.oam_wr(ppu_oam_wr),
				//
				.ppu_nmi(ppu_nmi),
				.v_blank(ppu_v_blank),
				//
				.color_addr(ppu_color_addr),
				.color_data(ppu_color_data),
				.color_wren(ppu_color_wren)
			  );
			  
ppu_oam m_ppu_oam(
	.address(ppu_oam_addrout),
	.clock(sysclk),
	.data(ppu_oam_dataout),
	.wren(ppu_oam_wr),
	.q(ppu_oam_datain)
	);

wire		[15:0]vga_addr;
wire		[7:0]vga_datain_0;
wire		[7:0]vga_datain_1;
wire		[7:0]vga_datain_2;
vga		m_vga(
					.sysclk(sysclk),
					.vga_clk(vga_clock),
					.reset(reset),
					.vga_hs(vga_hs),
					.vga_vs(vga_vs),
					.vga_av(vga_blank),
					.vga_r(vga_r),
					.vga_g(vga_g),
					.vga_b(vga_b),
					//
					.vga_addr(vga_addr),
					.vga_datain(vga_datain_2)
				);	

wire		ppu_ram_select;
wire		[15:0]dma_rdaddr;
wire		[7:0]dma_rddata0;
wire		[7:0]dma_rddata1;
wire		[15:0]dma_wraddr;
wire		dma_wren;
wire		[7:0]dma_wrdata;
vga_mem_control m_vga_mem_control(
												.sysclk(sysclk),
												.reset(dl_gen_reset),
												//
												.ppu_v_blank(ppu_v_blank),
												.ppu_ram_select(ppu_ram_select),
												.vga_addr(vga_addr[15:12]),
												//
												.dma_rdaddr(dma_rdaddr),
												.dma_rddata0(dma_rddata0),
												.dma_rddata1(dma_rddata1),
												//
												.dma_wraddr(dma_wraddr),
												.dma_wren(dma_wren),
												.dma_wrdata(dma_wrdata)
											  );
//tripple buffer											  
vga_ram m_vga_ram_0(
	.clock(sysclk),
	.data(ppu_color_data),
	.rdaddress(dma_rdaddr),
	.wraddress(ppu_color_addr),
	.wren(ppu_color_wren & ~ppu_ram_select),
	.q(dma_rddata0)
	);	
	
vga_ram m_vga_ram_1(
	.clock(sysclk),
	.data(ppu_color_data),
	.rdaddress(dma_rdaddr),
	.wraddress(ppu_color_addr),
	.wren(ppu_color_wren & ppu_ram_select),
	.q(dma_rddata1)
	);	
	
vga_ram m_vga_ram_2(
	.clock(sysclk),
	.data(dma_wrdata),
	.rdaddress(vga_addr),
	.wraddress(dma_wraddr),
	.wren(dma_wren),
	.q(vga_datain_2)
	);	
//--------------------------------------------------------------------------------
wire		mc_irq;
//cpu
wire		[15:0]mc_cpu_bus		= cpu_addr_bus;
wire		mc_cpu_wr 				= cpu_wr;
wire		[7:0]mc_cpu_data_in 	= cpu_data_out;
wire		[7:0]mc_cpu_data_out;
//ppu
wire		[13:0]mc_ppu_bus 		= ppu_addr_bus;
wire		mc_ppu_wr		  		= ppu_wr;
wire		[7:0]mc_ppu_data_in	= ppu_data_out;
wire		[7:0]mc_ppu_data_out;
//to sdram cpu part
wire		[24:0]sdram_cpu_bus;
wire		[7:0]sdram_cpu_data_in 	=	mngr_cpu_data_out;
wire		[7:0]sdram_cpu_data_out;
wire		sdram_cpu_wr;
//to sdram cpu part
wire		[24:0]sdram_ppu_bus;
wire		[7:0]sdram_ppu_data_in	=	mngr_ppu_data_out;
wire		[7:0]sdram_ppu_data_out;
wire		sdram_ppu_wr;

//to internal ram ppu part
wire		[9:0]iram_ppu_bus;
wire		[7:0]iram_ppu_data_out;
wire		[7:0]iram_ppu_data_in0;
wire		[7:0]iram_ppu_data_in1;
wire		[7:0]iram_ppu_data_in2;
wire		[7:0]iram_ppu_data_in3;
wire		iram_ppu_wr0;
wire		iram_ppu_wr1;
wire		iram_ppu_wr2;
wire		iram_ppu_wr3;
mappers_control m_mappers_control(
												.sysclk(sysclk),
												.cpu_clock(cpu_clock),
												.reset(dl_gen_reset),
												//
												.mc_irq(mc_irq),
												//
												.mc_prg_len(dump_prg_len),  	
												.mc_chr_len(dump_chr_len),
												.mc_mapper_type(mapper_type),
												.mc_solder_mirror(1'b0),
												.mc_four_screen(1'b0),
												//cpu
												.mc_cpu_bus(mc_cpu_bus),
												.mc_cpu_wr(mc_cpu_wr),
												.mc_cpu_data_in(mc_cpu_data_in),
												.mc_cpu_data_out(mc_cpu_data_out),
												//ppu
												.mc_ppu_bus(mc_ppu_bus),
												.mc_ppu_wr(mc_ppu_wr),
												.mc_ppu_data_in(mc_ppu_data_in),
												.mc_ppu_data_out(mc_ppu_data_out),
												//to sdram cpu part
												.sdram_cpu_bus(sdram_cpu_bus),
												.sdram_cpu_data_in(sdram_cpu_data_in),
												.sdram_cpu_data_out(sdram_cpu_data_out),
												.sdram_cpu_wr(sdram_cpu_wr),
												//to sdram ppu part
												.sdram_ppu_bus(sdram_ppu_bus),
												.sdram_ppu_data_in(sdram_ppu_data_in),
												.sdram_ppu_data_out(sdram_ppu_data_out),
												.sdram_ppu_wr(sdram_ppu_wr),
												//to internal ram ppu part
												.iram_ppu_bus(iram_ppu_bus),
												.iram_ppu_data_out(iram_ppu_data_out),
												.iram_ppu_data_in0(iram_ppu_data_in0),
												.iram_ppu_data_in1(iram_ppu_data_in1),
												.iram_ppu_data_in2(iram_ppu_data_in2),
												.iram_ppu_data_in3(iram_ppu_data_in3),
												.iram_ppu_wr0(iram_ppu_wr0),
												.iram_ppu_wr1(iram_ppu_wr1),
												.iram_ppu_wr2(iram_ppu_wr2),
												.iram_ppu_wr3(iram_ppu_wr3)
											);
ppu_ram ppu_ram_0(
						.address(iram_ppu_bus),
						.clock(sysclk),
						.data(iram_ppu_data_out),
						.wren(iram_ppu_wr0),
						.q(iram_ppu_data_in0)
					  );	

ppu_ram ppu_ram_1(
						.address(iram_ppu_bus),
						.clock(sysclk),
						.data(iram_ppu_data_out),
						.wren(iram_ppu_wr1),
						.q(iram_ppu_data_in1)
					  );
					  
ppu_ram ppu_ram_2(
						.address(iram_ppu_bus),
						.clock(sysclk),
						.data(iram_ppu_data_out),
						.wren(iram_ppu_wr2),
						.q(iram_ppu_data_in2)
					  );
					  
ppu_ram ppu_ram_3(
						.address(iram_ppu_bus),
						.clock(sysclk),
						.data(iram_ppu_data_out),
						.wren(iram_ppu_wr3),
						.q(iram_ppu_data_in3)
					  ); 
//--------------------------------------------------------------------------------
wire		[24:0]mngr_cpu_addr 		= 	sdram_cpu_bus;
wire		[7:0]mngr_cpu_data_in	= 	sdram_cpu_data_out;
wire		[7:0]mngr_cpu_data_out;
wire		mngr_cpu_wr					=	sdram_cpu_wr;

wire		[24:0]mngr_ppu_addr 		= 	sdram_ppu_bus;
wire		[7:0]mngr_ppu_data_in	= 	sdram_ppu_data_out;
wire		[7:0]mngr_ppu_data_out;
wire		mngr_ppu_wr					=	sdram_ppu_wr;

sdram_manager m_sdram_manager(
							.sysclk(sysclk),			
							.reset(reset),
							//
							.ldr_req(ldr_req),
							.ldr_ack(ldr_ack),
							.ldr_lh(ldr_lh),
							.ldr_addr(ldr_addr),
							.ldr_data_in(ldr_data_in),
							//
							.cpu_addr(mngr_cpu_addr),
							.cpu_data_in(mngr_cpu_data_in),
							.cpu_data_out(mngr_cpu_data_out),
							.cpu_wr(mngr_cpu_wr),
							//
							.ppu_addr(mngr_ppu_addr),
							.ppu_data_in(mngr_ppu_data_in),
							.ppu_data_out(mngr_ppu_data_out),
							.ppu_wr(mngr_ppu_wr),
							//request fifo
							.rq_fifo_empty(rq_fifo_empty),
							.rq_fifo_data(rq_fifo_data),
							.rq_fifo_wrreq(rq_fifo_wrreq),
							//answer fifo
							.an_fifo_empty(an_fifo_empty),
							.an_fifo_rdreq(an_fifo_rdreq),
							.an_fifo_q(an_fifo_q)
							);
							
wire		rq_fifo_empty;
wire		[35:0]rq_fifo_data;
wire		rq_fifo_wrreq;
wire		rq_fifo_rdreq;
wire		[35:0]rq_fifo_q;
wire		rq_fifo_full;

fifo_36x36 	rq_fifo_36x36(
									.clock(sysclk),
									.data(rq_fifo_data),
									.rdreq(rq_fifo_rdreq),
									.wrreq(rq_fifo_wrreq && ~rq_fifo_full),
									.empty(rq_fifo_empty),
									.full(rq_fifo_full),
									.q(rq_fifo_q)
								);			
						
wire		an_fifo_empty;
wire		an_fifo_rdreq;
wire		[8:0]an_fifo_q;
wire		[8:0]an_fifo_data;
wire		an_fifo_wrreq;
wire		an_fifo_full;

fifo_9x9 	an_fifo_9x9(
									.clock(sysclk),
									.data(an_fifo_data),
									.rdreq(an_fifo_rdreq),
									.wrreq(an_fifo_wrreq && ~an_fifo_full),
									.empty(an_fifo_empty),
									.full(an_fifo_full),
									.q(an_fifo_q)
								);						
sdram	m_sdram(
					.sysclk(sysclk),				//100MHz
					.delay_clock(pulse1MHz),	//1MHz
					.reset(reset),
					//read fifo
					.rq_fifo_empty(rq_fifo_empty),
					.rq_fifo_rdreq(rq_fifo_rdreq),
					.rq_fifo_q(rq_fifo_q),
					//answer fifo
					.an_fifo_data(an_fifo_data),
					.an_fifo_wrreq(an_fifo_wrreq),
					//sdram_interface
					.sdram_addr(sdram_addr),
					.sdram_dq(sdram_dq),
					.sdram_ba(sdram_ba),
					.sdram_ldqm(sdram_ldqm),
					.sdram_udqm(sdram_udqm),
					.sdram_ras_n(sdram_ras_n),
					.sdram_cas_n(sdram_cas_n),
					.sdram_cke(sdram_cke),
					.sdram_we_n(sdram_we_n),
					.sdram_cs_n(sdram_cs_n)
             );	
				 
//--------------------------------------------------------------------------------	
wire	dl_gen_reset;

wire		ldr_req;
wire		ldr_ack;
wire		ldr_lh;
wire		[24:0]ldr_addr;
wire		[7:0]ldr_data_in;
dump_loader m_dump_loader(
									.sysclk(sysclk),
									.delay_clock(pulse1MHz),
									.reset(reset),
									//
									.gen_reset(dl_gen_reset),
									//
									.load_dump(load_dump),
									.dump_offset(dump_offset),
									.dump_prg_len(dump_prg_len),
									.dump_chr_len(dump_chr_len),
									//sdcard control
									.busy(sdcard_busy),
									.error(sdcard_error),
									.rw_addr(sdcard_rw_addr),
									.read_pulse(sdcard_read_pulse),
									.empty(sdfifo_empty),
									.rdreq(sdfifo_rdreq),
									.q(sdfifo_q),
									//sdram manager
									.ldr_req(ldr_req),
									.ldr_ack(ldr_ack),
									.ldr_lh(ldr_lh),
									.ldr_addr(ldr_addr),
									.ldr_data(ldr_data_in)
								);


wire		sdcard_busy;
wire		sdcard_error;
wire		[31:0]sdcard_rw_addr;
wire		sdcard_read_pulse;
	
sdcard m_sdcard(
						.sysclk(sysclk),			//100MHz
						.reset(reset),
						//status
						.busy(sdcard_busy),
						.error(sdcard_error),
						//parameters & command
						.rw_addr(sdcard_rw_addr),
						.read_pulse(sdcard_read_pulse),
						.write_pulse(1'b0),
						//sync fifo 
						.data(sdfifo_data),
						.wrreq(sdfifo_wrreq),
						//sync fifo
						.rdreq(),
						.q(),
						//physical
						.cs(sdcard_cs),
						.sclk(sdcard_sclk),
						.mosi(sdcard_mosi),
						.miso(sdcard_miso)
					);	
					
wire		[7:0]sdfifo_data;		
wire		sdfifo_rdreq;		
wire		sdfifo_wrreq;		
wire		sdfifo_empty;			
wire		sdfifo_full;	
wire		[7:0]sdfifo_q;
fifo_sdcard m_fifo_sdcard(
									.clock(sysclk),
									.data(sdfifo_data),
									.rdreq(sdfifo_rdreq),
									.wrreq(sdfifo_wrreq && ~sdfifo_full),
									.empty(sdfifo_empty),
									.full(sdfifo_full),
									.q(sdfifo_q)
								 );
								 
//--------------------------------------------------------------------------------								 
segm_indicator segm_indicator(
										.sysclk(sysclk),
										.delay_clock(pulse1MHz),
										.gen_reset(dl_gen_reset),
										.digit0(digit0),
										.digit1(digit1),
										.digit2(digit2),
										.digit3(digit3)
										);
endmodule