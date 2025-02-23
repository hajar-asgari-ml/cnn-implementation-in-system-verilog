module MAC_v2_tb_new();

	timeunit 1ns;
	timeprecision 1ps;

	localparam time CLK_PERIOD			= 100ns;
	localparam unsigned RST_CLK_CYCLES  = 10;
	localparam unsigned MAC_INPUT_BIT_RESOLUTION = 8;
	localparam unsigned MAC_OUTPUT_BIT_RESOLUTION = 32;
	localparam unsigned KERNEL_SIZE_W = 3;
	localparam unsigned KERNEL_SIZE_H = 3;
	localparam unsigned ACQ_DELAY = 30ns;
	localparam unsigned APPL_DELAY = 10ns;

	// input interface
	logic clk, rst_n;
	logic input_and_kernel_valid;
	logic [MAC_INPUT_BIT_RESOLUTION-1:0] 	input_data;
	logic [MAC_INPUT_BIT_RESOLUTION-1:0] 	kernel_weight;
	logic [MAC_OUTPUT_BIT_RESOLUTION-1:0] 	kernel_bias;

	// output interface
	logic mac_valid;
	logic [MAC_OUTPUT_BIT_RESOLUTION-1:0] 	mac_data;
	logic mac_ready;

	
	clk_rst_gen #(
		.CLK_PERIOD 					(CLK_PERIOD),
		.RST_CLK_CYCLES 				(RST_CLK_CYCLES)
	)	i_clk_rst_gen (

		.clk_o 							(clk),
		.rst_no 						(rst_n)
	);

	MAC_v2  #(
		.INPUT_BIT_RESOLUTION 			(MAC_INPUT_BIT_RESOLUTION),
		.OUTPUT_BIT_RESOLUTION  		(MAC_OUTPUT_BIT_RESOLUTION),
		.KERNEL_SIZE_W 					(KERNEL_SIZE_W),
		.KERNEL_SIZE_H 					(KERNEL_SIZE_H)
	)	dut (
		.clk_i 							(clk),
		.rst_ni 						(rst_n),
		.feature_in_and_kernel_valid_i	(input_and_kernel_valid),
		.feature_in_data_i 				(input_data),
		.kernel_weight_i				(kernel_weight),
		.kernel_bias_i 					(kernel_bias),
		.mac_valid_o 					(mac_valid),
		.mac_data_o 					(mac_data),
		.mac_ready_i					(mac_ready)
	);


logic rst_local;
int count_cell;

initial begin
	input_and_kernel_valid = 0;
	input_data = 0;
	kernel_weight = 0;
	kernel_bias = 0;
	mac_ready = 1;

	#2000;
	input_and_kernel_valid = 1;
	randomize(kernel_bias);
	@(posedge clk);
	while (count_cell < KERNEL_SIZE_W*KERNEL_SIZE_H) begin
		@(posedge clk);
		#APPL_DELAY; 
		$display("iteration %0d", count_cell);
		count_cell += 1;
		randomize(input_data);
		randomize(kernel_weight);
		$display("Input: %0d , Kernel_weight: %0d , Kernel_bias: %0d", input_data, kernel_weight, kernel_bias);
	end

	wait(mac_valid);
	$display("MAC value is: %0d", mac_data);
    @(posedge clk);
	#(APPL_DELAY);
	input_and_kernel_valid = 0;
	mac_ready = 0;
	$stop();
end


endmodule // MAC_tb