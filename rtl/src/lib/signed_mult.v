(* DONT_TOUCH = "yes" *) // to prevent vivado removing top level ports
module signed_mult #(
	parameter INPUT_BIT_RESOLUTION = 8,
	parameter OUTPUT_BIT_RESOLUTION = 2*INPUT_BIT_RESOLUTION)

	(out, a, b);

	output 	[OUTPUT_BIT_RESOLUTION-1:0]			out;
	input 	signed	[INPUT_BIT_RESOLUTION-1:0] 	a;
	input 	signed	[INPUT_BIT_RESOLUTION-1:0] 	b;

	assign out = a * b;
	
endmodule