module square_pulse(
					sysclk,
					cpu_clock,
					reset,
					//
					apu_cs,
					//control
					ioreg_addr,
					ioreg_datain,
					ioreg_wr,
					//
					en_pulse,
					frame_l,
					frame_e,
					//
					lcounter_status,
					//
					square_out
					);
input		sysclk;	
input		cpu_clock;//1662607 Hz
input		reset;
//
input		apu_cs;
//control
input		[4:0]ioreg_addr;
input		[7:0]ioreg_datain;
input		ioreg_wr;
//
input		en_pulse;
input 	frame_l;
input		frame_e;
//
output	lcounter_status;
//
output	[3:0]square_out;

parameter REG0_ADDR = 5'h00;  //4000
parameter REG1_ADDR = 5'h01;	//4001
parameter REG2_ADDR = 5'h02;	//4002
parameter REG3_ADDR = 5'h03;	//4003
parameter CHANNEL_N	= 1'b0;

assign  	lcounter_status = length_counter!=0;
assign 	square_out = en_out ? out_pulse : 4'h0;
wire 		en_out = en_pulse & (timer_period > 11'd8) & (new_timer_period[11] == 0) & (length_counter!=0 | length_counter_halt == 1);  
//--------------------------------------------------------------------------------
//TIMER+
//--------------------------------------------------------------------------------
reg 		scnd_cpu_clock;
always@(posedge sysclk)if(cpu_clock)scnd_cpu_clock<=~scnd_cpu_clock;
//--------------------------------------------------------------------------------
wire 	timer_clk = ~(|timer_counter);
reg 	[10:0]timer_counter = 0;
always@(posedge sysclk)begin
	if(timer_clk || flag_reg3_chg)timer_counter<=timer_period;
	else if(scnd_cpu_clock && cpu_clock)timer_counter<=timer_counter-1'd1;
end
//--------------------------------------------------------------------------------
reg 	[10:0]timer_period = 0;
always@(posedge sysclk)begin
	if(flag_reg3_chg)timer_period<={reg4003[2:0],reg4002};
	else if(sweep_clk && sweep_enable && sweep_shift!=0 && new_timer_period[11] == 0 && (length_counter!=0 || length_counter_halt == 1))begin		//sweep 
		timer_period<=new_timer_period[10:0];
	end
end
//--------------------------------------------------------------------------------  
//SEQUENCER+
//--------------------------------------------------------------------------------
reg 	[2:0]sequencer = 0;
always@(posedge sysclk)begin
	if(flag_reg3_chg)sequencer<=0;
	else if(timer_clk)sequencer<=sequencer+1'd1;
end
//--------------------------------------------------------------------------------

reg 	[3:0]out_pulse;
wire	[1:0]pulse_duty = reg4000[7:6];
always@* begin
	case(sequencer)
		3'd0: out_pulse = (pulse_duty == 2'd3) ? volume:4'b0000;
		3'd1: out_pulse = (pulse_duty == 2'd3) ? volume:4'b0000;
		3'd2: out_pulse = (pulse_duty == 2'd3) ? volume:4'b0000;
		3'd3: out_pulse = (pulse_duty == 2'd3 || pulse_duty == 2'd2) ? volume:4'b0000;
		3'd4: out_pulse = (pulse_duty == 2'd3 || pulse_duty == 2'd2) ? volume:4'b0000;
		3'd5: out_pulse = (pulse_duty == 2'd2 || pulse_duty == 2'd1) ? volume:4'b0000;
		3'd6: out_pulse = (pulse_duty == 2'd2 || pulse_duty == 2'd1 || pulse_duty == 2'd0) ? volume:4'b0000;
		3'd7: out_pulse = (pulse_duty == 2'd3) ? volume:4'b0000;
	endcase
end

//--------------------------------------------------------------------------------
//LENGTH COUNTER
//--------------------------------------------------------------------------------
wire	length_counter_halt = reg4000[5];
wire	[4:0]length_counter_load = reg4003[7:3];
reg 	[7:0]length_counter = 0;
always@(posedge sysclk)begin
	if(!en_pulse)length_counter<=0;
	else if(flag_reg3_chg)begin
		case(length_counter_load[4:1])
			4'h0:length_counter <= length_counter_load[0] ? 8'hFE : 8'h0A;  
			4'h1:length_counter <= length_counter_load[0] ? 8'h02 : 8'h14;
			4'h2:length_counter <= length_counter_load[0] ? 8'h04 : 8'h28;
			4'h3:length_counter <= length_counter_load[0] ? 8'h06 : 8'h50;
			4'h4:length_counter <= length_counter_load[0] ? 8'h08 : 8'hA0;
			4'h5:length_counter <= length_counter_load[0] ? 8'h0A : 8'h3C;
			4'h6:length_counter <= length_counter_load[0] ? 8'h0C : 8'h0E;
			4'h7:length_counter <= length_counter_load[0] ? 8'h0E : 8'h1A;
			4'h8:length_counter <= length_counter_load[0] ? 8'h10 : 8'h0C;
			4'h9:length_counter <= length_counter_load[0] ? 8'h12 : 8'h18;
			4'hA:length_counter <= length_counter_load[0] ? 8'h14 : 8'h30;
			4'hB:length_counter <= length_counter_load[0] ? 8'h16 : 8'h60;
			4'hC:length_counter <= length_counter_load[0] ? 8'h18 : 8'hC0;
			4'hD:length_counter <= length_counter_load[0] ? 8'h1A : 8'h48;
			4'hE:length_counter <= length_counter_load[0] ? 8'h1C : 8'h10;
			4'hF:length_counter <= length_counter_load[0] ? 8'h1E : 8'h20;
		endcase
	end
	else if(frame_l && length_counter!=0 && length_counter_halt == 0)length_counter<=length_counter-1'd1;
end
//--------------------------------------------------------------------------------
//SWEEP+
//--------------------------------------------------------------------------------
wire	sweep_enable = reg4001[7];
wire	[2:0]sweep_period = reg4001[6:4];
wire	sweep_negate = reg4001[3];
wire	[2:0]sweep_shift = reg4001[2:0];
reg		[2:0]sweep_counter = 0;
wire	sweep_clk = ~(|sweep_counter);
always@(posedge sysclk)begin
	if((sweep_clk && frame_l) || flag_reg1_chg || flag_reg3_chg)	sweep_counter<=sweep_period;
	else if(frame_l)												sweep_counter<=sweep_counter-1'd1;
end
//--------------------------------------------------------------------------------
reg	[11:0]new_timer_period = 0;
always@(posedge sysclk)begin
	if(flag_reg1_chg || flag_reg3_chg)new_timer_period<=0;
	else if(new_timer_period[11] == 0 && timer_period > 11'd8 && sweep_shift!=0 && (length_counter!=0 || length_counter_halt == 1))begin
		if(CHANNEL_N == 1'b0) 
			new_timer_period<=timer_period + sweep_negate ? ~(timer_period<<sweep_shift) : (timer_period>>sweep_shift) ;
		else 
			new_timer_period<=timer_period + sweep_negate ? ~(timer_period<<sweep_shift) + 1'd1 : (timer_period>>sweep_shift) ;
	end
end
//--------------------------------------------------------------------------------
//ENVELOPE+
//--------------------------------------------------------------------------------
wire	envelope_disable 		= reg4000[4];
wire	envelope_loop	  		= reg4000[5];
wire 	[3:0]volume		  		= envelope_disable ? reg4000[3:0] : volume_counter;
wire	[3:0]envelope_period 	= reg4000[3:0];
reg		[3:0]envelope_counter	= 0;
wire 	envelope_clk 			= ~(|envelope_counter);
always@(posedge sysclk)begin
	if(envelope_clk  || flag_reg0_chg || flag_reg3_chg)	envelope_counter<=envelope_period;
	else if(frame_e)									envelope_counter<=envelope_counter-1'd1;
end
//--------------------------------------------------------------------------------
reg	[3:0]volume_counter = 0;
always@(posedge sysclk)begin
	if(flag_reg3_chg)volume_counter<=4'd15;
	else if(envelope_clk && (volume_counter!=0 || envelope_loop))volume_counter<=volume_counter-1'd1;
end
//--------------------------------------------------------------------------------
//CONTROL REGISTERS
//--------------------------------------------------------------------------------
//4000
reg 	[7:0]reg4000 = 0;
always@(posedge sysclk or negedge reset)begin
	if(!reset)reg4000<=0;
	else if(apu_cs && ioreg_addr == REG0_ADDR && ioreg_wr && cpu_clock)reg4000<=ioreg_datain;
end
//--------------------------------------------------------------------------------
reg 	flag_reg0_chg = 0;
always@(posedge sysclk)begin
	if(flag_reg0_chg)flag_reg0_chg<=0;
	else if(apu_cs && ioreg_addr == REG0_ADDR && ioreg_wr && cpu_clock)flag_reg0_chg<=1;
end
//--------------------------------------------------------------------------------
//4001
reg		[7:0]reg4001 = 0;
always@(posedge sysclk or negedge reset)begin
	if(!reset)reg4001<=0;
	else if(apu_cs && ioreg_addr == REG1_ADDR && ioreg_wr && cpu_clock)reg4001<=ioreg_datain;
end
//--------------------------------------------------------------------------------
reg 	flag_reg1_chg;
always@(posedge sysclk)begin
	if(flag_reg1_chg)flag_reg1_chg<=0;
	else if(apu_cs && ioreg_addr == REG1_ADDR && ioreg_wr && cpu_clock)flag_reg1_chg<=1;
end
//--------------------------------------------------------------------------------
//4002
reg		[7:0]reg4002 = 0;
always@(posedge sysclk or negedge reset)begin
	if(!reset)reg4002<=0;
	else if(apu_cs && ioreg_addr == REG2_ADDR && ioreg_wr && cpu_clock)reg4002<=ioreg_datain;
end
//--------------------------------------------------------------------------------
//4003
reg		[7:0]reg4003 = 0;
always@(posedge sysclk or negedge reset)begin
	if(!reset)reg4003<=0;
	else if(apu_cs && ioreg_addr == REG3_ADDR && ioreg_wr && cpu_clock)reg4003<=ioreg_datain;
end
//--------------------------------------------------------------------------------
reg 	flag_reg3_chg = 0;
always@(posedge sysclk)begin
	if(flag_reg3_chg)flag_reg3_chg<=0;
	else if(apu_cs && ioreg_addr == REG3_ADDR && ioreg_wr && cpu_clock)flag_reg3_chg<=1;
end

endmodule