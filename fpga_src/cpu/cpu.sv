module cpu(
				sysclk,
				cpu_clock,
				delay_clock,
				gen_reset,
				pll_reset,
				cpu_irq,
				cpu_nmi,
				cpu_addr_bus,
				cpu_wr,
				cpu_data_in,
				cpu_data_out,
				//for debug
				cpu_unk_cmd,
				//apu
				cpu_sound_out,
				//joysticks data
				jc_fifo_empty,
				jc_fifo_rdreq,
				jc_fifo_q,
				//reload signal for dump loader
				load_dump,
				mapper_type,
				solder_mirror,
				dump_offset,
				dump_prg_len,
				dump_chr_len
				);
				
input		sysclk;
input		cpu_clock;
input		delay_clock;
input		gen_reset;
input		pll_reset;
input		cpu_irq;
input 	cpu_nmi;
output	[15:0]cpu_addr_bus;
output	cpu_wr;
input		[7:0]cpu_data_in;
output	[7:0]cpu_data_out;
//for_debug
output	cpu_unk_cmd;
output   [5:0]cpu_sound_out = apu_sound_out;
//joysticks data
input		jc_fifo_empty;
output	jc_fifo_rdreq;
input		[15:0]jc_fifo_q;
//reload signal for dump loader
output	load_dump;
output	[3:0]mapper_type;
output	solder_mirror;
output	[31:0]dump_offset;
output	[15:0]dump_prg_len;
output	[15:0]dump_chr_len;


assign 	cpu_addr_bus 	= core_rdy ? core_addr_bus : dma_addr_bus;
assign 	cpu_data_out 	= core_rdy ? core_data_out : dma_data_out;
assign 	cpu_wr 			= core_rdy ? core_wr : dma_wr;
//--------------------------------------------------------------------------------
wire 		[15:0]core_addr_bus;	
wire 		[7:0]core_data_in;
wire 		[7:0]core_data_out;	
wire 		core_wr;
wire 		core_irq;
wire 		core_nmi;	
wire 		core_rdy;
assign 	core_data_in 	= io_reg_cs ?  apu_ioreg_dataout | {7'b0,jc_ioreg_dataout} : 
													cpu_data_in;
assign 	core_irq 		= apu_irq & cpu_irq;
assign 	core_nmi 		= cpu_nmi;
assign 	core_rdy 		= dma_rdy;

wire		io_reg_cs;
assign	io_reg_cs 		= ~core_addr_bus[15] && core_addr_bus[14] && (~|core_addr_bus[13:5]);  //io reg 4000 - 4017

core6502	m_core6502(
						.sysclk(sysclk),
						.cpu_clock(cpu_clock),
						.reset(gen_reset),
						.rdy(core_rdy),
						.irq(core_irq),
						.nmi(core_nmi),
						.addr_bus(core_addr_bus),
						.rw(core_wr),
						.data_in(core_data_in),
						.data_out(core_data_out),
						//for debug
						.unk_cmd(cpu_unk_cmd)
					);					
//--------------------------------------------------------------------------------	

wire 		[4:0]dma_ioreg_addr = core_addr_bus[4:0];	
wire 		[7:0]dma_ioreg_datain = core_data_out;
wire 		dma_ioreg_wr = core_wr;	

wire 		[15:0]dma_addr_bus;
wire 		[7:0]dma_data_in = cpu_data_in;
wire 		[7:0]dma_data_out;
wire 		dma_wr;
wire 		dma_rdy;	

dma m_dma(
			.sysclk(sysclk),
			.cpu_clock(cpu_clock),
			.reset(gen_reset),
			.dma_cs(io_reg_cs),
			.ioreg_addr(dma_ioreg_addr),
			.ioreg_datain(dma_ioreg_datain),
			.ioreg_wr(dma_ioreg_wr),
			.addr_bus(dma_addr_bus),
			.data_in(dma_data_in),
			.data_out(dma_data_out),
			.data_wr(dma_wr),
			.rdy(dma_rdy)
			);
			
//--------------------------------------------------------------------------------
wire  	[4:0]apu_ioreg_addr = core_addr_bus[4:0];
wire 		[7:0]apu_ioreg_datain = core_data_out;
wire 		apu_ioreg_wr = core_wr;
wire		[7:0]apu_ioreg_dataout;
wire  	[5:0]apu_sound_out;	
wire  	apu_irq;	
			
apu m_apu(
					.sysclk(sysclk),
					.cpu_clock(cpu_clock),
					.reset(gen_reset),
					.apu_cs(io_reg_cs),
					//control
					.ioreg_addr(apu_ioreg_addr),
					.ioreg_datain(apu_ioreg_datain),
					.ioreg_dataout(apu_ioreg_dataout),
					.ioreg_wr(apu_ioreg_wr),
					//
					.irq_out(apu_irq),
					.sound_out(apu_sound_out)
				);	
//--------------------------------------------------------------------------------
wire  	[4:0]jc_ioreg_addr = core_addr_bus[4:0];		
wire		jc_ioreg_dataout;	
wire 		jc_ioreg_wr = core_wr;
wire		jc_reload;
joystick_control m_joystick_control(
												.sysclk(sysclk),
												.cpu_clock(cpu_clock),
												.delay_clock(delay_clock),
												.reset(gen_reset),
												.joy_cs(io_reg_cs), 
												.ioreg_addr(jc_ioreg_addr),
												.ioreg_dataout(jc_ioreg_dataout),
												.ioreg_wr(jc_ioreg_wr),
												//
												.reload(jc_reload),
												//from any joystick reader
												.fifo_empty(jc_fifo_empty),
												.fifo_rdreq(jc_fifo_rdreq),
												.fifo_q(jc_fifo_q)
											  );
//--------------------------------------------------------------------------------	
wire  	[4:0]rld_ioreg_addr = core_addr_bus[4:0];
wire 		[7:0]rld_ioreg_datain = core_data_out;
wire 		rld_ioreg_wr = core_wr;										 
reload_control m_reload_control(
											.sysclk(sysclk),
											.cpu_clock(cpu_clock),
											.reset(pll_reset),
											//
											.rld_cs(io_reg_cs), 
											.ioreg_addr(rld_ioreg_addr),
											.ioreg_datain(rld_ioreg_datain),
											.ioreg_wr(rld_ioreg_wr),
											//
											.reload(jc_reload),
											.load_dump(load_dump),
											.mapper_type(mapper_type),
											.solder_mirror(solder_mirror),
											.dump_offset(dump_offset),
											.dump_prg_len(dump_prg_len),
											.dump_chr_len(dump_chr_len)
											);
endmodule