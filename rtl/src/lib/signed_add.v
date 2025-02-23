(* DONT_TOUCH = "yes" *) // to prevent vivado removing top level ports
module signed_add #(
	parameter INOUT_BIT_RESOLUTION = 16)

	(out, a, b);
	output 		[INOUT_BIT_RESOLUTION-1:0]	out;
	input 	signed	[INOUT_BIT_RESOLUTION-1:0] 	a;
	input 	signed	[INOUT_BIT_RESOLUTION-1:0] 	b;

	assign out = a + b;
	
endmodule