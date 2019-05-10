module apu(
					sysclk,	
					cpu_clock,//1662607 Hz
					reset,
					//
					apu_cs,
					//control
					ioreg_addr,
					ioreg_datain,
					ioreg_dataout,
					ioreg_wr,
					//
					irq_out,
					sound_out
					);
input		sysclk;
input 	cpu_clock;
input		reset;
//
input		apu_cs;
//control
input		[4:0]ioreg_addr;
input		[7:0]ioreg_datain;
output	[7:0]ioreg_dataout;
input		ioreg_wr;
//
output	irq_out;
output	[5:0]sound_out;

assign ioreg_dataout = (apu_cs && ioreg_addr == 5'h15 && ~ioreg_wr) ? {1'b0,irq_out,2'b0,lcounter_noise,lcounter_triangle,lcounter_pulse2,lcounter_pulse1}:8'h0;

//--------------------------------------------------------------------------------
wire	frame_l;
wire	frame_e;
frame_counter mframe_counter(
					.sysclk(sysclk),
					.cpu_clock(cpu_clock),
					.reset(reset),
					//
					.apu_cs(apu_cs),
					//control
					.ioreg_addr(ioreg_addr),
					.ioreg_datain(ioreg_datain),
					.ioreg_wr(ioreg_wr),
					//
					.irq_reset(apu_cs && ioreg_addr == 5'h15 && ~ioreg_wr && cpu_clock), //read from 4015 reset irq flag
					.frame_l(frame_l),
					.frame_e(frame_e),
					//
					.irq_out(irq_out)
					);
//--------------------------------------------------------------------------------
wire	lcounter_pulse1;
wire	[3:0]square_pulse_1;
square_pulse #(5'h00,5'h01,5'h02,5'h03,1'b0) msquare_pulse_1(
					.sysclk(sysclk),
					.cpu_clock(cpu_clock),
					.reset(reset),
					//
					.apu_cs(apu_cs),
					//control
					.ioreg_addr(ioreg_addr),
					.ioreg_datain(ioreg_datain),
					.ioreg_wr(ioreg_wr),
					//
					.en_pulse(enable_pulse1),
					.frame_l(frame_l),
					.frame_e(frame_e),
					//
					.lcounter_status(lcounter_pulse1),
					//
					.square_out(square_pulse_1)
					);
//--------------------------------------------------------------------------------	
wire	lcounter_pulse2;
wire	[3:0]square_pulse_2;				
square_pulse #(5'h04,5'h05,5'h06,5'h07,1'b1) msquare_pulse_2(
					.sysclk(sysclk),
					.cpu_clock(cpu_clock),
					.reset(reset),
					//
					.apu_cs(apu_cs),
					//control
					.ioreg_addr(ioreg_addr),
					.ioreg_datain(ioreg_datain),
					.ioreg_wr(ioreg_wr),
					//
					.en_pulse(enable_pulse2),
					.frame_l(frame_l),
					.frame_e(frame_e),
					//
					.lcounter_status(lcounter_pulse2),
					//
					.square_out(square_pulse_2)
					);
//--------------------------------------------------------------------------------
wire	lcounter_triangle;
wire	[3:0]triangle_out;	

triangle m_triangle(
				.sysclk(sysclk),
				.cpu_clock(cpu_clock),
				.reset(reset),
				//
				.apu_cs(apu_cs),
				//control
				.ioreg_addr(ioreg_addr),
				.ioreg_datain(ioreg_datain),
				.ioreg_wr(ioreg_wr),
				//
				.en_triangle(enable_triangle),
				.frame_l(frame_l),
				.frame_e(frame_e),
				//
				.lcounter_status(lcounter_triangle),
				//
				.triangle_out(triangle_out)
				);
//--------------------------------------------------------------------------------	
wire	lcounter_noise;	
wire	[3:0]noise_out;
noise m_noise(
				.sysclk(sysclk),
				.cpu_clock(cpu_clock),
				.reset(reset),
				//
				.apu_cs(apu_cs),
				//control
				.ioreg_addr(ioreg_addr),
				.ioreg_datain(ioreg_datain),
				.ioreg_wr(ioreg_wr),
				//
				.en_noise(enable_noise),
				.frame_l(frame_l),
				.frame_e(frame_e),
				//
				.lcounter_status(lcounter_noise),
				//
				.noise_out(noise_out)
			);
//--------------------------------------------------------------------------------	

mixer m_mixer(
					.square_1_in(square_pulse_1),
					.square_2_in(square_pulse_2),
					.triangle_in(triangle_out),
					.noise_in(noise_out),
					.mixer_out(sound_out)
				);
//--------------------------------------------------------------------------------
//CONTROL REGISTERS
//--------------------------------------------------------------------------------
wire		enable_DMC			= reg4015[4];
wire		enable_noise 		= reg4015[3];
wire		enable_triangle 	= reg4015[2];
wire		enable_pulse2 		= reg4015[1];
wire		enable_pulse1 		= reg4015[0];
reg		[7:0]reg4015 = 0;
always@(posedge sysclk or negedge reset)begin
	if(!reset)reg4015<=0;
	else if(apu_cs && ioreg_addr == 5'h15 && ioreg_wr && cpu_clock)reg4015<=ioreg_datain;
end

endmodule