module triangle(
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
				en_triangle,
				frame_l,
				frame_e,
				//
				lcounter_status,
				//
				triangle_out
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
input		en_triangle;
input 	frame_l;
input		frame_e;
//
output	lcounter_status;
//
output 	[3:0]triangle_out;


assign  	lcounter_status = length_counter!=0;
assign 	triangle_out = en_triangle ? (sequencer[4] ? sequencer[3:0] : ~sequencer[3:0]) : 4'd0;

//--------------------------------------------------------------------------------
//LINEAR COUNTER
//--------------------------------------------------------------------------------
reg  [6:0]linear_counter;
always@(posedge sysclk or negedge reset)begin
	if(!reset)linear_counter<=0;
	else if(frame_e)begin
		if( flag_linear_halt )linear_counter<=reg4008[6:0];
		else if( frame_e && linear_counter!=0 )linear_counter<=linear_counter-1'd1;
	end
end
//--------------------------------------------------------------------------------
reg flag_linear_halt;
always@(posedge sysclk or negedge reset)begin
	if(!reset)flag_linear_halt<=0;
	else if(flag_regB_chg)flag_linear_halt<=1'b1;
	else if(frame_e && !length_counter_halt)flag_linear_halt<=1'b0;
end
//--------------------------------------------------------------------------------
//LENGTH COUNTER
//--------------------------------------------------------------------------------
wire	length_counter_halt = reg4008[7];
wire	[4:0]length_counter_load = reg400B[7:3];
reg 	[7:0]length_counter = 0;
always@(posedge sysclk)begin
	if(!en_triangle)length_counter<=0;
	else if(flag_regB_chg)begin
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
//TIMER+
//--------------------------------------------------------------------------------
wire 	timer_clk = ~(|timer_counter);
reg 	[10:0]timer_counter = 0;
always@(posedge sysclk)begin
	if(timer_clk || flag_regB_chg)timer_counter<=timer_period;
	else if( cpu_clock )timer_counter<=timer_counter-1'd1;
end
//--------------------------------------------------------------------------------
reg 	[10:0]timer_period = 0;
always@(posedge sysclk)begin
	if(flag_regB_chg)timer_period<={reg400B[2:0],reg400A};
end
//--------------------------------------------------------------------------------  
//SEQUENCER+
//--------------------------------------------------------------------------------
reg 	[4:0]sequencer = 0;
always@(posedge sysclk)begin
	if(timer_clk)begin
		if(length_counter!=0 && linear_counter!=0)sequencer<=sequencer+1'd1;
	end
end
//--------------------------------------------------------------------------------
//4008
reg		[7:0]reg4008 = 0;
always@(posedge sysclk or negedge reset)begin
	if(!reset)reg4008<=0;
	else if(apu_cs && ioreg_addr == 5'h08 && ioreg_wr && cpu_clock)reg4008<=ioreg_datain;
end
//--------------------------------------------------------------------------------
//400A
reg		[7:0]reg400A = 0;
always@(posedge sysclk or negedge reset)begin
	if(!reset)reg400A<=0;
	else if(apu_cs && ioreg_addr == 5'h0A && ioreg_wr && cpu_clock)reg400A<=ioreg_datain;
end
//--------------------------------------------------------------------------------
//400B
reg		[7:0]reg400B = 0;
always@(posedge sysclk or negedge reset)begin
	if(!reset)reg400B<=0;
	else if(apu_cs && ioreg_addr == 5'h0B && ioreg_wr && cpu_clock)reg400B<=ioreg_datain;
end
//--------------------------------------------------------------------------------
reg 	flag_regB_chg = 0;
always@(posedge sysclk)begin
	if(flag_regB_chg)flag_regB_chg<=0;
	else if(apu_cs && ioreg_addr == 5'h0B && ioreg_wr && cpu_clock)flag_regB_chg<=1;
end
endmodule