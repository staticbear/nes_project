module sound_manager(
							clk,				//	18.432	MHz
							reset,
							//audio samples
							audio_fifo_rdreq,
							audio_fifo_data,
							//physical interface		
							audio_daclrck,
							audio_dacdat,
							audio_bclk,	  
							audio_i2c_clk,
							audio_i2c_data
                   );
input  clk;
input  reset;
//audio samples
output	audio_fifo_rdreq;
input	[15:0]audio_fifo_data;
//physical interface	
output audio_daclrck;
output audio_dacdat;
output audio_bclk;

output audio_i2c_clk;
inout  audio_i2c_data;

assign audio_daclrck = gen_rl;

parameter SM_BEGIN    = 4'd0;
parameter SM_POWEROFF = 4'd1;
parameter SM_POWERON  = 4'd2;
parameter SM_REC_REG8 = 4'd3;
parameter SM_REC_REG7 = 4'd4;
parameter SM_REC_REG4 = 4'd5;
parameter SM_REC_REG5 = 4'd6;
parameter SM_REC_REG9 = 4'd7;
parameter SM_REC_REG3 = 4'd8;
parameter SM_WAIT     = 4'd9;
//---------------------------------------------------------------------------------- 
reg [3:0]sm;
always@(posedge clk or negedge reset)begin
   if(!reset)sm<=SM_BEGIN;
	else begin
	   case(sm)
			SM_BEGIN:sm<=SM_POWEROFF;
			SM_POWEROFF:if(old_busy && !busy)sm<=SM_POWERON;
			SM_POWERON:if(old_busy && !busy)sm<=SM_REC_REG8;
			SM_REC_REG8:if(old_busy && !busy)sm<=SM_REC_REG7;
			SM_REC_REG7:if(old_busy && !busy)sm<=SM_REC_REG4;
			SM_REC_REG4:if(old_busy && !busy)sm<=SM_REC_REG5;
			SM_REC_REG5:if(old_busy && !busy)sm<=SM_REC_REG9;
			SM_REC_REG9:if(old_busy && !busy)sm<=SM_REC_REG3;
			SM_REC_REG3:if(old_busy && !busy)sm<=SM_WAIT;
		endcase
	end
end
//---------------------------------------------------------------------------------- 
reg old_busy;
always@(posedge clk)old_busy<=busy;
//---------------------------------------------------------------------------------- 
reg [3:0]old_sm;
reg action;
always@(posedge clk)begin
   old_sm<=sm;
   action<=(old_sm!=sm & sm!=SM_WAIT);
end
//---------------------------------------------------------------------------------- 
reg [6:0]reg_addr;
reg [8:0]reg_data;
always@(posedge clk)begin
	case(sm)
		SM_POWEROFF:begin 	 
			reg_addr<=7'd6;
			reg_data<=9'b011111111;							//disable all
		end
		SM_POWERON:begin  	
			reg_addr<=7'd6;
			reg_data<=9'b000000111;							//enable all except line input, microphone,adc
		end
		SM_REC_REG8:begin
			reg_addr<=7'd8;
			reg_data<=9'b000000010;							//BOSR  = 1  SR = 0011  dac sample rating = 8 kHz /BOSR  = 0  SR = 0000  dac sample rating = 48 kHz
		end
		SM_REC_REG7:begin
			reg_addr<=7'd7;
			reg_data<=9'b0_0_0_0_0_00_01;                   //left justified format/16bit/clock master disable/
		end
		SM_REC_REG4:begin
			reg_addr<=7'd4;
			reg_data<=9'b000010000;                    		//dac select
		end
		SM_REC_REG5:begin
			reg_addr<=7'd5;
			reg_data<=9'b000000001;        					//adc hight pass filter disable           
		end
		SM_REC_REG9:begin
			reg_addr<=7'd9;
			reg_data<=9'b000000001;                         //digital interface enable
		end
		SM_REC_REG3:begin
			reg_addr<=7'd3;
			reg_data<=9'b0111111111;                       
		end
	endcase
end
//---------------------------------------------------------------------------------- 
parameter	REF_CLK			=	18432000;	//	18.432	MHz
parameter	SAMPLE_RATE		=	48000;		//	48		KHz
parameter	DATA_WIDTH		=	16;			//	16		Bits
parameter	CHANNEL_NUM		=	2;			//	Dual Channel

reg [3:0]gen_bclk_div;	
reg audio_bclk;	
always@(posedge clk or negedge reset)begin
   if(!reset)begin
		audio_bclk<=0;
		gen_bclk_div<=0;
	end
	else begin
	   if(gen_bclk_div >=REF_CLK/(SAMPLE_RATE*DATA_WIDTH*CHANNEL_NUM*2)-1)begin
		   audio_bclk<=~audio_bclk;
		   gen_bclk_div<=0;
		end
		else gen_bclk_div<=gen_bclk_div+1'd1;
	end
end
//---------------------------------------------------------------------------------- 
reg gen_rl;
reg [8:0]gen_rl_div;
always@(posedge clk or negedge reset)begin
   if(!reset)begin
		gen_rl_div<=0;
		gen_rl<=0;
	end
	else begin
	   if(gen_rl_div>= REF_CLK/(SAMPLE_RATE*2)-1)begin
		   gen_rl_div<=0;
		   gen_rl<=~gen_rl;
		end
		else gen_rl_div<=gen_rl_div+1'd1;
	end
end

//---------------------------------------------------------------------------------- 
//DAC SIDE
assign audio_dacdat = gen_rl ? 1'b0 : audio_fifo_data[~dac_bit_cnt];
//----------------------------------------------------------------------------------
wire flag_action = (gen_bclk_div == (REF_CLK/(SAMPLE_RATE*DATA_WIDTH*CHANNEL_NUM*2)-1)); 
reg [3:0]dac_bit_cnt;
always@(posedge clk)if(flag_action && audio_bclk)dac_bit_cnt<=dac_bit_cnt+1'd1;
//---------------------------------------------------------------------------------- 
reg audio_fifo_rdreq;
always@(posedge clk)audio_fifo_rdreq<=(dac_bit_cnt == 4'd15) & gen_rl;
//----------------------------------------------------------------------------------
wire busy;
wm8731 mwm8731(
				.sysclk(clk),
				.reset(reset),
				.action(action),
				.busy(busy),
				.dev_addr(7'b0011010),  
				.reg_addr(reg_addr),       
				.reg_data(reg_data),
				.i2c_sclk(audio_i2c_clk),
				.i2c_data(audio_i2c_data)
			  );

endmodule