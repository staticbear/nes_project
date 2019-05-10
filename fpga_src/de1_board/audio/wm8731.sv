module wm8731(
				sysclk,
				reset,
				action,
				busy,
				dev_addr,
				reg_addr,
				reg_data,
				i2c_sclk,//526 kHz max
				i2c_data
			  );
input  sysclk;
input  reset;
input  action;
output busy;
input  [6:0]dev_addr;
input  [6:0]reg_addr;
input  [8:0]reg_data;
output i2c_sclk;
inout  i2c_data;

assign i2c_sclk = clk_sel ? gen_clock : 1'b1;
assign i2c_data = direct_sel ? 1'bZ : wr_data[29];
assign busy = flag_send;

wire   clk_sel =(bit_cnt > 5'd1) & (bit_cnt < 5'd30) & !cst;
wire   direct_sel = ( bit_cnt == 5'd10) | ( bit_cnt == 5'd19) | ( bit_cnt == 5'd28);
//----------------------------------------------------------------------------------        
parameter div_set = 8'd79;
reg [7:0]div_cnt;
always@(posedge sysclk or negedge reset)begin
    if(!reset)div_cnt<=0;
	else if(div_cnt != div_set)div_cnt<=div_cnt+1'd1;
	else div_cnt<=0;
end
//----------------------------------------------------------------------------------
reg cst;
always@(posedge sysclk)begin
   cst<=gen_clock & (bit_cnt == 5'd29);
end
//----------------------------------------------------------------------------------
reg gen_clock;
always@(posedge sysclk or negedge reset)begin
    if(!reset)gen_clock<=1;
	else if(div_cnt == div_set)gen_clock<=~gen_clock;
end
//----------------------------------------------------------------------------------
reg old_state_clk;
always@(posedge sysclk)old_state_clk<=gen_clock;
wire clk_front = (!old_state_clk & gen_clock);
wire clk_back = (old_state_clk & !gen_clock);
//----------------------------------------------------------------------------------
reg flag_send;
always@(posedge sysclk or negedge reset)begin
   if(!reset)flag_send<=0;
   else begin
     if(!flag_send)flag_send<=action;
	  else if(bit_cnt == 5'd30 && clk_back)flag_send<=0;
	  else if(clk_front && direct_sel && i2c_data)flag_send<=0;
   end
end
//----------------------------------------------------------------------------------
reg [4:0]bit_cnt;
always@(posedge sysclk)begin
   if(!flag_send)bit_cnt<=5'd0;
   else if(clk_back)bit_cnt<=bit_cnt+1'd1;
end
//----------------------------------------------------------------------------------
reg [29:0]wr_data;
always@(posedge sysclk)begin
   if(!flag_send )wr_data<={	1'b1,1'b0,          //1->0  start
								dev_addr,1'b0,       //dev addr + rw
							    1'b0,                //ack
							    reg_addr,reg_data[8],//register addr + 1 wrdata
							    1'b0,                //ack
							    reg_data[7:0],       //wrdata
							    1'b0,                //ack
						        1'b0                 //x->0
							};
   else if(clk_back)wr_data<={wr_data[28:0],1'b1};
end
endmodule