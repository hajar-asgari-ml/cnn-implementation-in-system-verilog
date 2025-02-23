module Int32_to_Int8_out_tb();

	timeunit 1ns;
	timeprecision 1ps;

	localparam time CLK_PERIOD			= 100ns;
	localparam unsigned RST_CLK_CYCLES  = 10;
	localparam unsigned DWSCALING_IN_RESOLUTION = 32;
	localparam unsigned DWSCALING_OUT_RESOLUTION = 8;
	localparam unsigned ACQ_DELAY = 30ns;
	localparam unsigned APPL_DELAY = 10ns;

	// input interface
	logic 									clk, rst_n;
	logic [3:0] 							dwscaling_n;
	logic [DWSCALING_IN_RESOLUTION-1 : 0] 	dwscaling_m0;
	logic [DWSCALING_IN_RESOLUTION-1 : 0] 	dwscaling_data_i;
	logic 								  	dwscaling_valid_i;

	// output interface
	logic 								  	dwscaling_valid_o;
	logic [DWSCALING_OUT_RESOLUTION-1 : 0]	dwscaling_data_o;
	logic 									dwscaling_ready_i;

	
	clk_rst_gen #(
		.CLK_PERIOD 				(CLK_PERIOD),
		.RST_CLK_CYCLES 			(RST_CLK_CYCLES)
	)	i_clk_rst_gen (

		.clk_o 						(clk),
		.rst_no 					(rst_n)
	);

	Int32_to_Int8_out  #(
		.DWSCALING_IN_RESOLUTION 	(DWSCALING_IN_RESOLUTION), 
		.DWSCALING_OUT_RESOLUTION 	(DWSCALING_OUT_RESOLUTION)
	)	dut (
		.clk_i 						(clk),
		.rst_ni 					(rst_n),  
		.dwscaling_n_i    			(dwscaling_n), 
		.dwscaling_m0_i   			(dwscaling_m0), 
		.dwscaling_valid_i			(dwscaling_valid_i), 
		.dwscaling_data_i 			(dwscaling_data_i), 
		.dwscaling_ready_i			(dwscaling_ready_i),
		.dwscaling_data_o 			(dwscaling_data_o), 
		.dwscaling_valid_o			(dwscaling_valid_o)
	);

initial begin
	dwscaling_m0 = 32'b10001001000100110101001110001001;
	dwscaling_n = 7; 
	dwscaling_valid_i = 0;
	dwscaling_data_i = 0;
	dwscaling_ready_i = 1;	
	#2000;
	$display("Start reading kernel and input data at", $time());
	@(posedge clk);
	dwscaling_valid_i = 0;
	dwscaling_data_i = 0;
	@(posedge clk);
	dwscaling_valid_i = 1;
	dwscaling_data_i = 583;	
	@(posedge clk)
	dwscaling_valid_i = 0;
	dwscaling_data_i = 0;	
	#2000;
	@(posedge clk);
	@(posedge clk);	
	dwscaling_valid_i = 1;
	dwscaling_data_i = 22536;		
	@(posedge clk)
	dwscaling_valid_i = 0;
	dwscaling_data_i = 0;
	#2000;
	@(posedge clk);		
	dwscaling_valid_i = 1;
	dwscaling_data_i = 16'b0011_1010_1110_1011;		
	@(posedge clk)
	dwscaling_valid_i = 0;
	dwscaling_data_i = 0;	

	#2000;
	@(posedge clk);		
	dwscaling_valid_i = 1;
	dwscaling_data_i = 16'b1100_1010_1110_1011;		
	@(posedge clk)
	dwscaling_valid_i = 0;
	dwscaling_data_i = 0;

	@(posedge clk);
	#1000;
	$stop();
end
initial 
	$monitor("dwscaling_valid", dwscaling_valid_o);

endmodule // MAC_tb