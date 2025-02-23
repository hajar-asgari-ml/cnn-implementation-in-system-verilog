module MAC_v3_tb();

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
		.CLK_PERIOD 				(CLK_PERIOD),
		.RST_CLK_CYCLES 			(RST_CLK_CYCLES)
	)	i_clk_rst_gen (

		.clk_o 						(clk),
		.rst_no 					(rst_n)
	);

	MAC_v4  #(
		.INPUT_BIT_RESOLUTION 			(MAC_INPUT_BIT_RESOLUTION),
		.OUTPUT_BIT_RESOLUTION  		(MAC_OUTPUT_BIT_RESOLUTION),
		.KERNEL_SIZE_W 					(KERNEL_SIZE_W),
		.KERNEL_SIZE_H 					(KERNEL_SIZE_H)
	)	dut (
		.clk_i 							(clk),
		.rst_ni 						(rst_n),
		.mac_fin_and_kernel_valid_i		(input_and_kernel_valid),
		.mac_fin_data_i 				(input_data),
		.mac_kernel_data_i				(kernel_weight),
		.mac_kernel_bias_i 				(kernel_bias),
		.mac_valid_o 					(mac_valid),
		.mac_data_o 					(mac_data),
		.mac_ready_i					(mac_ready)
	);


    // // TODO Instantiate the randomizing stream master.
    // rand_stream_mst #(
    //     .data_t             (rgb_t),
    //     .MIN_WAIT_CYCLES    (0),
    //     .MAX_WAIT_CYCLES    (5),
    //     .APPL_DELAY         (APPL_DELAY),
    //     .ACQ_DELAY          (ACQ_DELAY)
    // ) i_stim_gen (
    //     .clk_i         				(clk),
    //     .rst_ni     				(rst_n),
    //     .input_and_kernel_valid_o	(input_and_kernel_valid),
    //     .input_data_o 				(input_data),
    //     .kernel_weight_o 			(kernel_weight),
    //     .kernel_bias_o 				(kernel_bias),
    //     .mac_ready 					(mac_ready)
    // );
logic rst_local;

initial begin
	input_and_kernel_valid = 0;
	input_data = 0;
	kernel_weight = 0;
	kernel_bias = 0;
	mac_ready = 1;
	#2000;
	$display("Start sending kernel and input data at", $time());
	@(posedge clk);
	input_and_kernel_valid = 1;
	@(posedge clk);
	input_data = 1;
	kernel_weight = 1;
	kernel_bias = 100;
	@(posedge clk);
	input_data = 2;
	kernel_weight = 2;
	@(posedge clk);
	input_data = -3;
	kernel_weight = 3;
	@(posedge clk);
	input_data = 4;
	kernel_weight = 4;
	@(posedge clk);
	input_data = 5;
	kernel_weight = 5;
	@(posedge clk);
	input_data = 6;
	kernel_weight = -6;
	@(posedge clk);
	input_data = 7;
	kernel_weight = 7;
	@(posedge clk);
	input_data = 8;
	kernel_weight = 8;
	@(posedge clk);
	input_data = 9;
	kernel_weight = 9;
	@(posedge clk);
	input_and_kernel_valid = 0;

	wait(mac_valid);
	$display("MAC output is ready. mac_valid is %0b at time %0d. MAC_data value is: ", mac_valid, $time(), mac_data);	
	// @(posedge clk);
	// @(posedge clk);
	// @(posedge clk);
	// @(posedge clk);	
	input_and_kernel_valid = 0;
	mac_ready = 1;
	@(posedge clk)
	mac_ready = 0;
	@(posedge clk);
	@(posedge clk);
	
	#1000;
	$stop();
end
// initial 
// 	$monitor("mac_out:", mac_valid);

endmodule // MAC_tb