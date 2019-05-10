/*
0  	+
1 	-
2 	or
3 	and
4 	xor
5   lsl
6   lsr
7   rol
8   ror
*/
module alu(
			cmd,
			ci,
			data_a,
			data_b,
			result,
			no,
			zo,
			co,
			vo
			);
input	[3:0]cmd;
input	ci;
input 	[7:0]data_a;
input	[7:0]data_b;
output	[7:0]result;
output	no;
output	zo;
output	co;
output	vo;
//--------------------------------------------------------------------------------
reg [8:0]temp;
always@* begin
	case(cmd)
		4'd0:temp=data_a + data_b + ci;
		4'd1:temp=data_a - (data_b + ci);
		4'd2:temp=data_a | data_b;
		4'd3:temp=data_a & data_b;
		4'd4:temp=data_a ^ data_b;
		4'd5:temp={data_a[7:0],1'b0};
		4'd6:temp={data_a[0],1'b0,data_a[7:1]};
		4'd7:temp={data_a[7:0],ci};
		4'd8:temp={data_a[0],ci,data_a[7:1]};
		default:temp=9'd0;
	endcase
end
//--------------------------------------------------------------------------------
assign result = temp[7:0];
assign no = temp[7];
assign zo = !temp[7:0];
assign co = temp[8];
assign vo = data_a[7] ^ data_b[7] ^ co ^ no;

endmodule