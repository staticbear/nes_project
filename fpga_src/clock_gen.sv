module clock_gen(
						ref_clk,			
						reset,
						pulse_out			
					 );
					 
input 	ref_clk;	
input    reset;	
output	pulse_out;

parameter DIVIDER_WIDTH = 6;
parameter DIVIDER_VALUE = 60;

//clk0
reg [DIVIDER_WIDTH-1:0]divider;
always@(posedge ref_clk or negedge reset)begin
	if(!reset)divider<=DIVIDER_VALUE;
	else if(|divider)divider<=divider-1'd1;
	else divider<=DIVIDER_VALUE;
end	
	
reg pulse_out;
always@(posedge ref_clk)pulse_out<=~(|divider);	
	
endmodule
