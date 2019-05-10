module	vga(
					sysclk,
					vga_clk,
					reset,
					vga_hs,
					vga_vs,
					vga_av,
					vga_r,
					vga_g,
					vga_b,
					//
					vga_addr,
					vga_datain
				);
				
input		sysclk;
input		vga_clk;
input		reset;
output	vga_hs;
output	vga_vs;
output	vga_av;
output	[7:0]vga_r;
output	[7:0]vga_g;
output	[7:0]vga_b;
//
output	[15:0]vga_addr;
input		[7:0]vga_datain;

//settings for 640x480 60MHz
//horizontal
parameter h_allframe = 800;
parameter h_visible	= 640;
parameter h_front	   = 16;
parameter h_sync     = 96;
parameter h_back	   = 48;
//vertical
parameter v_allframe = 525;
parameter v_visible	= 480;
parameter v_front	   = 10;
parameter v_sync     = 2;
parameter v_back	   = 33;
//----------------------------------------------------------------------------------
reg [10:0]x_cnt;
always@(posedge sysclk or negedge reset)begin
   if(!reset)x_cnt<=0;
	else if(vga_clk)begin
	   if(x_cnt == h_allframe-1)x_cnt<=0;
		else x_cnt<=x_cnt+1'd1;
	end
end
//----------------------------------------------------------------------------------
reg vga_hs;                                     					
always@(posedge sysclk)if(vga_clk)vga_hs<=~(x_cnt<h_sync); 
//----------------------------------------------------------------------------------
reg [9:0]y_cnt;
always@(posedge sysclk or negedge reset)begin
   if(!reset)y_cnt<=0;
	else if(vga_clk)begin
	   if(x_cnt == h_allframe-1)begin
		   if(y_cnt == v_allframe-1)y_cnt<=0;
			else y_cnt<=y_cnt+1'd1;
		end
	end
end
//----------------------------------------------------------------------------------
reg vga_vs;
always@(posedge sysclk)if(vga_clk)vga_vs<=~(y_cnt<v_sync);
//----------------------------------------------------------------------------------


wire h_active = (x_cnt > h_sync + h_back) & (x_cnt < h_allframe - h_front);
wire v_active = (y_cnt > v_sync + v_back) & (y_cnt < v_allframe - v_front);
reg vga_av;
always@(posedge sysclk)if(vga_clk)vga_av<=h_active & v_active;


parameter	border_size	 = 64;
wire	h_myscrteen = (x_cnt > h_sync + h_back + border_size) & (x_cnt < h_allframe - h_front - border_size);
//----------------------------------------------------------------------------------

reg	[15:0]vga_addr;
always@(posedge sysclk or negedge reset)begin
	if(!reset)vga_addr<=0;
	else if(vga_clk)begin
		if(v_active)begin
			if(h_active)begin
				if(x_cnt[0] && h_myscrteen)vga_addr<=vga_addr+1'd1;
			end
			else if(!y_cnt[0])vga_addr<=pre_addr;
		end
		else vga_addr<=0;
	end
end

reg	[15:0]pre_addr;
always@(posedge sysclk)if(vga_clk && !h_active && y_cnt[0])pre_addr<=vga_addr;
//----------------------------------------------------------------------------------
wire	[23:0]rgb_code;
always@* begin
	case(vga_datain[5:0])
		6'd00:rgb_code = {8'h7C,8'h7C,8'h7C};
		6'd01:rgb_code = {8'h00,8'h00,8'hFC};
		6'd02:rgb_code = {8'h00,8'h00,8'hBC};
		6'd03:rgb_code = {8'h44,8'h28,8'hBC};
		6'd04:rgb_code = {8'h94,8'h00,8'h84};
		6'd05:rgb_code = {8'hA8,8'h00,8'h20};
		6'd06:rgb_code = {8'hA8,8'h10,8'h00};
		6'd07:rgb_code = {8'h88,8'h14,8'h00};
		6'd08:rgb_code = {8'h50,8'h30,8'h00};
		6'd09:rgb_code = {8'h00,8'h78,8'h00};
		6'd10:rgb_code = {8'h00,8'h68,8'h00};
		6'd11:rgb_code = {8'h00,8'h58,8'h00};
		6'd12:rgb_code = {8'h00,8'h40,8'h58};
		6'd13:rgb_code = {8'h00,8'h00,8'h00};
		6'd14:rgb_code = {8'h00,8'h00,8'h00};
		6'd15:rgb_code = {8'h00,8'h00,8'h00};
		6'd16:rgb_code = {8'hBC,8'hBC,8'hBC};
		6'd17:rgb_code = {8'h00,8'h78,8'hF8};
		6'd18:rgb_code = {8'h00,8'h58,8'hF8};
		6'd19:rgb_code = {8'h68,8'h44,8'hFC};
		6'd20:rgb_code = {8'hD8,8'h00,8'hCC};
		6'd21:rgb_code = {8'hE4,8'h00,8'h58};
		6'd22:rgb_code = {8'hF8,8'h38,8'h00};
		6'd23:rgb_code = {8'hE4,8'h5C,8'h10};
		6'd24:rgb_code = {8'hAC,8'h7C,8'h00};
		6'd25:rgb_code = {8'h00,8'hB8,8'h00};
		6'd26:rgb_code = {8'h00,8'hA8,8'h00};
		6'd27:rgb_code = {8'h00,8'hA8,8'h44};
		6'd28:rgb_code = {8'h00,8'h88,8'h88};
		6'd29:rgb_code = {8'h00,8'h00,8'h00};
		6'd30:rgb_code = {8'h00,8'h00,8'h00};
		6'd31:rgb_code = {8'h00,8'h00,8'h00};
		6'd32:rgb_code = {8'hF8,8'hF8,8'hF8};
		6'd33:rgb_code = {8'h3C,8'hBC,8'hFC};
		6'd34:rgb_code = {8'h68,8'h88,8'hFC};
		6'd35:rgb_code = {8'h98,8'h78,8'hF8};
		6'd36:rgb_code = {8'hF8,8'h78,8'hF8};
		6'd37:rgb_code = {8'hF8,8'h58,8'h98};
		6'd38:rgb_code = {8'hF8,8'h78,8'h58};
		6'd39:rgb_code = {8'hFC,8'hA0,8'h44};
		6'd40:rgb_code = {8'hF8,8'hB8,8'h00};
		6'd41:rgb_code = {8'hB8,8'hF8,8'h18};
		6'd42:rgb_code = {8'h58,8'hD8,8'h54};
		6'd43:rgb_code = {8'h58,8'hF8,8'h98};
		6'd44:rgb_code = {8'h00,8'hE8,8'hD8};
		6'd45:rgb_code = {8'h78,8'h78,8'h78};
		6'd46:rgb_code = {8'h00,8'h00,8'h00};
		6'd47:rgb_code = {8'h00,8'h00,8'h00};
		6'd48:rgb_code = {8'hFC,8'hFC,8'hFC};
		6'd49:rgb_code = {8'hA4,8'hE4,8'hFC};
		6'd50:rgb_code = {8'hB8,8'hB8,8'hF8};
		6'd51:rgb_code = {8'hD8,8'hB8,8'hF8};
		6'd52:rgb_code = {8'hF8,8'hB8,8'hF8};
		6'd53:rgb_code = {8'hF8,8'hA4,8'hC0};
		6'd54:rgb_code = {8'hF0,8'hD0,8'hB0};
		6'd55:rgb_code = {8'hFC,8'hE0,8'hA8};
		6'd56:rgb_code = {8'hF8,8'hD8,8'h78};
		6'd57:rgb_code = {8'hD8,8'hF8,8'h78};
		6'd58:rgb_code = {8'hB8,8'hF8,8'hB8};
		6'd59:rgb_code = {8'hB8,8'hF8,8'hD8};
		6'd60:rgb_code = {8'h00,8'hFC,8'hFC};
		6'd61:rgb_code = {8'hF8,8'hD8,8'hF8};
		6'd62:rgb_code = {8'h00,8'h00,8'h00};
		6'd63:rgb_code = {8'h00,8'h00,8'h00};
	endcase
end

assign	vga_r		=	h_myscrteen ? rgb_code[23:16] : 8'h00;
assign	vga_g 	=	h_myscrteen ? rgb_code[15:8] 	: 8'h00;
assign	vga_b 	=	h_myscrteen ? rgb_code[7:0] 	: 8'h00;
//----------------------------------------------------------------------------------
endmodule
