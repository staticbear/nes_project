module noise(
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
				en_noise,
				frame_l,
				frame_e,
				//
				lcounter_status,
				//
				noise_out
			);
input	sysclk;	
input	cpu_clock;//1662607 Hz
input	reset;
//
input	apu_cs;
//control
input	[4:0]ioreg_addr;
input	[7:0]ioreg_datain;
input	ioreg_wr;
//
input	en_noise;
input 	frame_l;
input	frame_e;
//
output	lcounter_status;
//
output 	[3:0]noise_out;

assign  lcounter_status = length_counter!=0;
assign  noise_out = (!shift_reg[0] && length_counter != 0) ?  volume : 4'b0000;
//--------------------------------------------------------------------------------
//SHIFT REG+
//--------------------------------------------------------------------------------
reg [14:0]shift_reg;
wire mode = reg400E[7];
wire feedback = mode ? shift_reg[0] ^ shift_reg[6] : shift_reg[0] ^ shift_reg[1];
always@(posedge sysclk or negedge reset)begin
	if(!reset)shift_reg<=15'd1;
	else if(timer_clk)shift_reg<={feedback,shift_reg[14:1]};
end
//--------------------------------------------------------------------------------
//TIMER+
//--------------------------------------------------------------------------------
reg scnd_cpu_clock;
always@(posedge sysclk)if(cpu_clock)scnd_cpu_clock<=~scnd_cpu_clock;
//--------------------------------------------------------------------------------
wire 	timer_clk = ~(|timer_counter);
reg 	[11:0]timer_counter = 0;
always@(posedge sysclk)begin
	if(timer_clk)timer_counter<=timer_period;
	else if(scnd_cpu_clock && cpu_clock)timer_counter<=timer_counter-1'd1;
end
//--------------------------------------------------------------------------------
reg 	[11:0]timer_period = 0;
always@*begin
	case(reg400E[3:0])
		4'd0:timer_period=12'd4;
		4'd1:timer_period=12'd8;
		4'd2:timer_period=12'd14;
		4'd3:timer_period=12'd40;
		4'd4:timer_period=12'd60;
		4'd5:timer_period=12'd88;
		4'd6:timer_period=12'd118;
		4'd7:timer_period=12'd148;
		4'd8:timer_period=12'd188;
		4'd9:timer_period=12'd236;
		4'd10:timer_period=12'd354;
		4'd11:timer_period=12'd472;
		4'd12:timer_period=12'd708;
		4'd13:timer_period=12'd944;
		4'd14:timer_period=12'd1890;
		4'd15:timer_period=12'd3778;
	endcase
end

//--------------------------------------------------------------------------------
//LENGTH COUNTER
//--------------------------------------------------------------------------------
wire	length_counter_halt = reg400C[5];
wire	[4:0]length_counter_load = reg400F[7:3];
reg 	[7:0]length_counter = 0;
always@(posedge sysclk)begin
	if(!en_noise)length_counter<=0;
	else if(flag_regF_chg)begin
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
//ENVELOPE+
//--------------------------------------------------------------------------------
wire	envelope_disable 		= reg400C[4];
wire	envelope_loop	 		= reg400C[5];
wire 	[3:0]volume		 		= envelope_disable ? reg400C[3:0] : volume_counter;
wire	[3:0]envelope_period 	= reg400C[3:0];
reg	[3:0]envelope_counter = 0;
wire 	envelope_clk 			= ~(|envelope_counter);
always@(posedge sysclk)begin
	if(envelope_clk  || flag_regF_chg || flag_regC_chg)envelope_counter<=envelope_period;
	else if(frame_e)envelope_counter<=envelope_counter-1'd1;
end
//--------------------------------------------------------------------------------
reg		[3:0]volume_counter = 0;
always@(posedge sysclk)begin
	if(flag_regF_chg)volume_counter<=4'd15;
	else if(envelope_clk  && (volume_counter!=0 || envelope_loop))volume_counter<=volume_counter-1'd1;
end
//--------------------------------------------------------------------------------
//400F
reg		[7:0]reg400F = 0;
always@(posedge sysclk or negedge reset)begin
	if(!reset)reg400F<=0;
	else if(apu_cs && ioreg_addr == 5'h0F && ioreg_wr && cpu_clock)reg400F<=ioreg_datain;
end
//--------------------------------------------------------------------------------
reg 	flag_regF_chg = 0;
always@(posedge sysclk)begin
	if(flag_regF_chg)flag_regF_chg<=0;
	else if(apu_cs && ioreg_addr == 5'h0F && ioreg_wr && cpu_clock)flag_regF_chg<=1;
end
//--------------------------------------------------------------------------------
//400E
reg		[7:0]reg400E = 0;
always@(posedge sysclk or negedge reset)begin
	if(!reset)reg400E<=0;
	else if(apu_cs && ioreg_addr == 5'h0E && ioreg_wr && cpu_clock)reg400E<=ioreg_datain;
end
//--------------------------------------------------------------------------------
//400C
reg		[7:0]reg400C = 0;
always@(posedge sysclk or negedge reset)begin
	if(!reset)reg400C<=0;
	else if(apu_cs && ioreg_addr == 5'h0C && ioreg_wr && cpu_clock)reg400C<=ioreg_datain;
end
//--------------------------------------------------------------------------------
reg 	flag_regC_chg = 0;
always@(posedge sysclk)begin
	if(flag_regC_chg)flag_regC_chg<=0;
	else if(apu_cs && ioreg_addr == 5'h0C && ioreg_wr && cpu_clock)flag_regC_chg<=1;
end
endmodule