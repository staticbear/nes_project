module joystick_control(
									sysclk,
									cpu_clock,
									delay_clock,
									reset,
									joy_cs, 
									ioreg_addr,
									//
									ioreg_dataout,
									ioreg_wr,
									//
									reload,
									//from any joystick reader
									fifo_empty,
									fifo_rdreq,
									fifo_q
								);

input 	sysclk;
input		cpu_clock;
input		delay_clock;
input		reset;
input		joy_cs;
input		[4:0]ioreg_addr;
//input		ioreg_datain;
output	ioreg_dataout;
input		ioreg_wr;
//
output	reload;
//from any joystick reader
input		fifo_empty;
output	fifo_rdreq;
input		[15:0]fifo_q;

assign		fifo_rdreq		= ~fifo_empty;
wire			joy_data_bit 	= (ioreg_addr == 5'h16) ? control_shift0[7] : control_shift1[7];											   
assign		ioreg_dataout 	= (joy_cs && (ioreg_addr == 5'h16 || ioreg_addr == 5'h17) && ~ioreg_wr) ? joy_data_bit : 1'b0;
assign		reload			= (~|reload_delay);

reg		[7:0]control_shift0;
always@(posedge sysclk or negedge reset)begin
	if(!reset)control_shift0<=0;
	else if(joy_cs && cpu_clock && (ioreg_addr == 5'h16 || ioreg_addr == 5'h17))begin
		if(ioreg_wr)						control_shift0<=fifo_q[7:0];
		else if(ioreg_addr == 5'h16)	control_shift0<={control_shift0[6:0],1'b0};
	end
end

reg		[7:0]control_shift1;
always@(posedge sysclk or negedge reset)begin
	if(!reset)control_shift1<=0;
	else if(joy_cs && cpu_clock && (ioreg_addr == 5'h16 || ioreg_addr == 5'h17))begin
		if(ioreg_wr)						control_shift1<=fifo_q[15:8];
		else if(ioreg_addr == 5'h17)	control_shift1<={control_shift1[6:0],1'b0};
	end
end

reg	[22:0]reload_delay;
always@(posedge sysclk)begin
	if(~|reload_delay)reload_delay<=23'd5000000;
	else if(delay_clock)begin
		if(fifo_q[5])reload_delay<=reload_delay-1'd1;
		else reload_delay<=23'd5000000;
	end
end

endmodule