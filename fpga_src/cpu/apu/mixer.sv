module mixer(
					square_1_in,
					square_2_in,
					triangle_in,
					noise_in,
					mixer_out
				);

input	[3:0]square_1_in;
input	[3:0]square_2_in;
input	[3:0]triangle_in;
input	[3:0]noise_in;
output	[5:0]mixer_out = pulse_out + tnd_out;

wire	[4:0]pulse_sum = square_1_in + square_2_in;
reg [5:0]pulse_out;
always@* begin
	case(pulse_sum)
	  5'h00:   pulse_out = 6'h00;
      5'h01:   pulse_out = 6'h01;
      5'h02:   pulse_out = 6'h01;
      5'h03:   pulse_out = 6'h02;
      5'h04:   pulse_out = 6'h03;
      5'h05:   pulse_out = 6'h03;
      5'h06:   pulse_out = 6'h04;
      5'h07:   pulse_out = 6'h05;
      5'h08:   pulse_out = 6'h05;
      5'h09:   pulse_out = 6'h06;
      5'h0A:   pulse_out = 6'h07;
      5'h0B:   pulse_out = 6'h07;
      5'h0C:   pulse_out = 6'h08;
      5'h0D:   pulse_out = 6'h08;
      5'h0E:   pulse_out = 6'h09;
      5'h0F:   pulse_out = 6'h09;
      5'h10:   pulse_out = 6'h0A;
      5'h11:   pulse_out = 6'h0A;
      5'h12:   pulse_out = 6'h0B;
      5'h13:   pulse_out = 6'h0B;
      5'h14:   pulse_out = 6'h0C;
      5'h15:   pulse_out = 6'h0C;
      5'h16:   pulse_out = 6'h0D;
      5'h17:   pulse_out = 6'h0D;
      5'h18:   pulse_out = 6'h0E;
      5'h19:   pulse_out = 6'h0E;
      5'h1A:   pulse_out = 6'h0F;
      5'h1B:   pulse_out = 6'h0F;
      5'h1C:   pulse_out = 6'h0F;
      5'h1D:   pulse_out = 6'h10;
      5'h1E:   pulse_out = 6'h10;
		default: pulse_out  = 6'd0;
	endcase
end

wire	[6:0]tnd_sum = { triangle_in, 1'b0 } + { 1'b0, triangle_in } + { noise_in, 1'b0 };

reg [5:0]tnd_out;
always@* begin
	case(tnd_sum)
		7'h00:   tnd_out = 6'h00;
      7'h01:   tnd_out = 6'h01;
      7'h02:   tnd_out = 6'h01;
      7'h03:   tnd_out = 6'h02;
      7'h04:   tnd_out = 6'h03;
      7'h05:   tnd_out = 6'h03;
      7'h06:   tnd_out = 6'h04;
      7'h07:   tnd_out = 6'h05;
      7'h08:   tnd_out = 6'h05;
      7'h09:   tnd_out = 6'h06;
      7'h0A:   tnd_out = 6'h07;
      7'h0B:   tnd_out = 6'h07;
      7'h0C:   tnd_out = 6'h08;
      7'h0D:   tnd_out = 6'h08;
      7'h0E:   tnd_out = 6'h09;
      7'h0F:   tnd_out = 6'h09;
      7'h10:   tnd_out = 6'h0A;
      7'h11:   tnd_out = 6'h0A;
      7'h12:   tnd_out = 6'h0B;
      7'h13:   tnd_out = 6'h0B;
      7'h14:   tnd_out = 6'h0C;
      7'h15:   tnd_out = 6'h0C;
      7'h16:   tnd_out = 6'h0D;
      7'h17:   tnd_out = 6'h0D;
      7'h18:   tnd_out = 6'h0E;
      7'h19:   tnd_out = 6'h0E;
      7'h1A:   tnd_out = 6'h0F;
      7'h1B:   tnd_out = 6'h0F;
      7'h1C:   tnd_out = 6'h0F;
      7'h1D:   tnd_out = 6'h10;
      7'h1E:   tnd_out = 6'h10;
      7'h1F:   tnd_out = 6'h11;
      7'h20:   tnd_out = 6'h11;
      7'h21:   tnd_out = 6'h11;
      7'h22:   tnd_out = 6'h12;
      7'h23:   tnd_out = 6'h12;
      7'h24:   tnd_out = 6'h12;
      7'h25:   tnd_out = 6'h13;
      7'h26:   tnd_out = 6'h13;
      7'h27:   tnd_out = 6'h14;
      7'h28:   tnd_out = 6'h14;
      7'h29:   tnd_out = 6'h14;
      7'h2A:   tnd_out = 6'h15;
      7'h2B:   tnd_out = 6'h15;
      7'h2C:   tnd_out = 6'h15;
      7'h2D:   tnd_out = 6'h15;
      7'h2E:   tnd_out = 6'h16;
      7'h2F:   tnd_out = 6'h16;
      7'h30:   tnd_out = 6'h16;
      7'h31:   tnd_out = 6'h17;
      7'h32:   tnd_out = 6'h17;
      7'h33:   tnd_out = 6'h17;
      7'h34:   tnd_out = 6'h17;
      7'h35:   tnd_out = 6'h18;
      7'h36:   tnd_out = 6'h18;
      7'h37:   tnd_out = 6'h18;
      7'h38:   tnd_out = 6'h19;
      7'h39:   tnd_out = 6'h19;
      7'h3A:   tnd_out = 6'h19;
      7'h3B:   tnd_out = 6'h19;
      7'h3C:   tnd_out = 6'h1A;
      7'h3D:   tnd_out = 6'h1A;
      7'h3E:   tnd_out = 6'h1A;
      7'h3F:   tnd_out = 6'h1A;
      7'h40:   tnd_out = 6'h1B;
      7'h41:   tnd_out = 6'h1B;
      7'h42:   tnd_out = 6'h1B;
      7'h43:   tnd_out = 6'h1B;
      7'h44:   tnd_out = 6'h1B;
      7'h45:   tnd_out = 6'h1C;
      7'h46:   tnd_out = 6'h1C;
      7'h47:   tnd_out = 6'h1C;
      7'h48:   tnd_out = 6'h1C;
      7'h49:   tnd_out = 6'h1C;
      7'h4A:   tnd_out = 6'h1D;
      7'h4B:   tnd_out = 6'h1D;
		default: tnd_out  = 6'd0;
	endcase
end
endmodule