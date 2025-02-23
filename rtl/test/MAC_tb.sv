module MAC_tb();

	timeunit 1ns;
	timeprecision 1ps;

	localparam time CLK_PERIOD			= 100ns;
	localparam unsigned RST_CLK_CYCLES  = 10;
	localparam unsigned MAC_INPUT_BIT_RESOLUTION = 8;
	localparam unsigned MAC_OUTPUT_BIT_RESOLUTION = 32;
	localparam unsigned ACQ_DELAY = 30ns;
	localparam unsigned APPL_DELAY = 10ns;

	// input interface
	logic clk, rst_n, clr_mac;
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

	MAC  #(
		.INPUT_BIT_RESOLUTION 		(MAC_INPUT_BIT_RESOLUTION),
		.OUTPUT_BIT_RESOLUTION  	(MAC_OUTPUT_BIT_RESOLUTION)
	)	dut (
		.clk_i 						(clk),
		.rst_ni 					(rst_n),
		.clr_i                   	(clr_mac),
		.input_and_kernel_valid_i	(input_and_kernel_valid),
		.input_data_i 				(input_data),
		.kernel_weight_i			(kernel_weight),
		.kernel_bias_i 				(kernel_bias),
		.mac_valid_o 				(mac_valid),
		.mac_data_o 				(mac_data),
		.mac_ready_i				(mac_ready)
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
	clr_mac = 1;
	input_and_kernel_valid = 0;
	input_data = 0;
	kernel_weight = 0;
	kernel_bias = 0;
	mac_ready = 0;
	#2000;
	$display("Start reading kernel and input data at", $time());
	@(posedge clk);
	clr_mac = 0;
	input_and_kernel_valid = 1;
	@(posedge clk);
	@(posedge clk)
	input_data = 3;
	kernel_weight = 3;
	kernel_bias = 10;
	// wait(posedge clk);
	@(posedge clk);
	input_data = 4;
	kernel_weight = 4;
	@(posedge clk);
	input_data = 5;
	kernel_weight = 5;
	@(posedge clk);
	input_data = 6;
	kernel_weight = 6;
	@(posedge clk);
	input_data = 7;
	kernel_weight = 7;
	input_and_kernel_valid = 0;
	mac_ready = 1;
	@(posedge clk)
	mac_ready = 0;
	@(posedge clk);
	clr_mac = 1;
	@(posedge clk);
	#1000;
	$stop();
end
initial 
	$monitor("mac_valid", mac_valid_o);

endmodule // MAC_tb