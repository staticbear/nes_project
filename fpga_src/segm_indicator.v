module segm_indicator(
								sysclk,
								delay_clock,
								gen_reset,
								digit0,
								digit1,
								digit2,
								digit3
							);
input		sysclk;
input		delay_clock;
input		gen_reset;
output	[6:0]digit0;
output	[6:0]digit1;
output	[6:0]digit2;
output	[6:0]digit3;		
					
parameter	blink_div 	= 	17'h1FFFF;						

parameter	letter_L		=	7'b1000111;
parameter	letter_O		=	7'b1000000;
parameter	letter_A		=	7'b0001000;
parameter	letter_d		=	7'b0100001;
parameter	letter_r		=	7'b1001110;
parameter	letter_U		=	7'b1000001;
parameter	letter_n		=	7'b1001000;
parameter	none			=	7'b1111111;
		
reg		[16:0]delay_cnt;			
always@(posedge sysclk)begin
	
	if(~|delay_cnt)delay_cnt<=blink_div;
	else if(delay_clock)delay_cnt<=delay_cnt-1'd1;
end

reg		blink;
always@(posedge sysclk)begin
	if(~|delay_cnt)blink<=~blink;
end

assign	digit3	=	gen_reset ? letter_r :
							blink		 ? letter_L :
											none;
							
assign	digit2	=	gen_reset ? letter_U :
							blink		 ? letter_O :
											none;
											
assign	digit1	=	gen_reset ? letter_n :
							blink		 ? letter_A :
											none;
											
assign	digit0	=	(gen_reset || ~blink) ? none : letter_d;

endmodule