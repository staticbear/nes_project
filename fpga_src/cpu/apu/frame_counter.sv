module frame_counter(
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
					irq_reset,
					frame_l,
					frame_e,
					//
					irq_out
					);

					
input		sysclk;	
input		cpu_clock;
input		reset;
//
input		apu_cs;
//control
input		[4:0]ioreg_addr;
input		[7:0]ioreg_datain;
input		ioreg_wr;
//
input		irq_reset;
output	frame_l;
output	frame_e;
//
output	irq_out;
assign 	irq_out = ~(~irq_gen[1] & irq_gen[0] & ~irq_inhibit);

parameter DIV_240HZ = (13'd7309 - 13'd1);  //13'd6944 - 13'd1 for pal 13'd7309 - 13'd1 for ntsc
//--------------------------------------------------------------------------------
//FRAME COUNTER+
//--------------------------------------------------------------------------------
/*
mode 0: 4-step  effective rate (approx)
---------------------------------------
    - - - f      60 Hz
    - l - l     120 Hz
    e e e e     240 Hz
mode 1: 5-step  effective rate (approx)
---------------------------------------
    - - - - -   (interrupt flag never set)
    l - l - -    96 Hz
    e e e e -   192 Hz
*/
//divider
reg 	[12:0]frame_div_cnt = 0;
wire	clock240 = ~(|frame_div_cnt);  
always@(posedge sysclk)begin
	if(clock240 || flag_reg17_chg)				frame_div_cnt<=DIV_240HZ;
	else if(|frame_div_cnt && cpu_clock)		frame_div_cnt<=frame_div_cnt-1'd1;
end
//--------------------------------------------------------------------------------
reg [2:0]frame_step = 0;
always@(posedge sysclk)begin
	if(flag_reg17_chg)frame_step<=0;
	else if(clock240)begin
		if((frame_step == 3'd3 && !frame_mode) ||
			(frame_step == 3'd4 && frame_mode))	frame_step<=0; 
		else 												frame_step<=frame_step+1'd1;
	end
end
//--------------------------------------------------------------------------------
//set interrupt flag
reg		frame_f = 0;
always@(posedge sysclk or negedge reset)begin
	if(!reset)frame_f<=0;
	else begin
		if(irq_reset || frame_mode)	  frame_f<=0;
		else if(clock240 && !frame_step)frame_f<=1;
	end
end

reg		[1:0]irq_gen;
always@(posedge sysclk)irq_gen<={irq_gen[0],frame_f};
//--------------------------------------------------------------------------------
//clock length counters and sweep units
reg		frame_l = 0;
always@(posedge sysclk)begin
	if(clock240)begin
		case(frame_step)
			3'd0:frame_l<=1'b1 & ~frame_mode;
			3'd2:frame_l<=1'b1;
			3'd4:frame_l<=1'b1;
		endcase 
	end
	else frame_l<=0;
end
//--------------------------------------------------------------------------------
//clock envelopes and triangle's linear counter
reg		frame_e = 0;
always@(posedge sysclk)begin
	if(clock240 && (!frame_mode || frame_step!=0))frame_e<=1'b1;
	else frame_e<=1'b0;
end

//--------------------------------------------------------------------------------
//CONTROL REGISTERS
//--------------------------------------------------------------------------------
wire frame_mode = reg4017[7];
wire irq_inhibit = reg4017[6];	
reg		[7:0]reg4017 = 0;
always@(posedge sysclk or negedge reset)begin
	if( !reset )																		reg4017<=0;
	else if( apu_cs && ioreg_addr == 5'h17 && ioreg_wr && cpu_clock )	reg4017<=ioreg_datain;
end
//--------------------------------------------------------------------------------
reg 	flag_reg17_chg = 0;
always@(posedge sysclk)begin
	if( flag_reg17_chg )																flag_reg17_chg<=0;
	else if( apu_cs && ioreg_addr == 5'h17 && ioreg_wr && cpu_clock )	flag_reg17_chg<=1;
end

endmodule