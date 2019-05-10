module nes_joystick(
						sysclk,
						cpu_clock,
						reset,
						//sync
						fifo_empty,
						fifo_wrreq,
						fifo_data,
						//phy
						joy_latch,
						joy_pulse,
						joy_data0,
						joy_data1
					);
input		sysclk;
input		cpu_clock;
input		reset;
//sync
input		fifo_empty;
output	fifo_wrreq;
output	[15:0]fifo_data;
//phy
output	joy_latch;
output	joy_pulse;
input		joy_data0;
input		joy_data1;

assign	joy_pulse 	=	(gen_clock && |control_shift[8:1]);

assign	fifo_wrreq	=	(internal_clock && fifo_empty && control_shift[8]);
assign	fifo_data	=	{joy_btn_state1,joy_btn_state0};

reg		gen_clock;
always@(posedge sysclk)if(cpu_clock)gen_clock<=~gen_clock;

wire		internal_clock;
assign	internal_clock	=	(~gen_clock && cpu_clock);

reg		[8:0]control_shift;
always@(posedge sysclk or negedge reset)begin
	if(!reset)control_shift<=0;
	else if(internal_clock)control_shift<={control_shift[7:0],joy_latch};
end

reg		joy_latch;
always@(posedge sysclk or negedge reset)begin
	if(!reset)joy_latch<=0;
	else if(internal_clock)begin
		if(~|control_shift && ~joy_latch)joy_latch<=1'b1;
		else joy_latch<=1'b0;
	end
end

reg		[7:0]joy_btn_state0;
always@(posedge sysclk)begin
	if(internal_clock)joy_btn_state0<={joy_btn_state0[6:0],joy_data0};
end

reg		[7:0]joy_btn_state1;
always@(posedge sysclk)begin
	if(internal_clock)joy_btn_state1<={joy_btn_state1[6:0],joy_data1};
end

endmodule