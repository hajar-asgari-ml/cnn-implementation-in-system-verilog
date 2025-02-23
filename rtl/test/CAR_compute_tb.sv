module CAR_compute_tb ();
    
    timeunit 1ns;
    timeprecision 1ps;

    localparam time CLK_PERIOD = 10ns;
    localparam unsigned RST_CLK_CYCLES = 10;

    localparam unsigned FRC_BIT_RESOLUTION      = 8;
    localparam unsigned NUM_BIT_RESOLUTION_DATA = 23+8;
    localparam unsigned NUM_BIT_RESOLUTION_PARA = 9;
    
    localparam unsigned ACQ_DELAY  = 30ns;
    localparam unsigned APPL_DELAY = 10ns;
    
    // input interface
    logic clk, rst_ni, rst_n;
    logic signed [NUM_BIT_RESOLUTION_DATA-1 : 0] z1_mem_i, z2_mem_i, x_i;
    logic signed [NUM_BIT_RESOLUTION_PARA-1 : 0] a0_i, c0_i, r_i, g_i, h_i;
    logic valid_i, ready_i;

    // output interface
    logic [NUM_BIT_RESOLUTION_DATA-1 : 0] z1_o, z2_o, y_o;
    logic valid_o, ready_o;

    clk_rst_gen #(
		.CLK_PERIOD 				(CLK_PERIOD),
		.RST_CLK_CYCLES 			(RST_CLK_CYCLES)
	)	i_clk_rst_gen (

		.clk_o 						(clk),
		.rst_no 					(rst_n) // not used here
	);
    
    // Instantiate the DUT
    CAR_compute #(
        .FRC_BIT_RESOLUTION         (FRC_BIT_RESOLUTION),
        .NUM_BIT_RESOLUTION_DATA    (NUM_BIT_RESOLUTION_DATA),
        .NUM_BIT_RESOLUTION_PARA    (NUM_BIT_RESOLUTION_PARA)
    ) dut (
        .clk 						(clk),
        .rst_ni 					(rst_ni),
        .z1_mem_i 					(z1_mem_i),
        .z2_mem_i 					(z2_mem_i),
        .x_i 						(x_i),
        .a0_i 						(a0_i),
        .c0_i 						(c0_i),
        .r_i 						(r_i),
        .g_i 						(g_i),
        .h_i 						(h_i),
        .valid_i 					(valid_i),
        .ready_i 					(ready_i),

        .z1_o 						(z1_o),
        .z2_o 						(z2_o),
        .y_o 						(y_o),
        .valid_o 					(valid_o),
        .ready_o 					(ready_o)
    );
    
initial begin
    // test CAR impulse response of channel 0 with given parameters
    z1_mem_i = 0;
    z2_mem_i = 0;
    x_i = 0;
    a0_i = 0;
    c0_i = 0;
    r_i = 0;
    g_i = 0;
    h_i = 0;
    valid_i = 0;
    ready_i = 0;
    rst_ni = 1;

    # 10ns;
    rst_ni = 0;
    # 10ns;
    rst_ni = 1;
    
    x_i         = 31'b0000000000000000000000100000000;
    z1_mem_i    = 31'b0;
    z2_mem_i    = 31'b0;
    // parameters
    // a0_i, c0_i, r_i, g_i, h_i = 0.844, 0.536, 0.943, 0.523, 0.536
    a0_i  = 9'b0_11011000;
    c0_i  = 9'b0_10001001;
    r_i   = 9'b0_11110001;
    g_i   = 9'b0_10000101;
    h_i   = 9'b0_10001001;

    # 30ns;
    valid_i = 1;
    # 10ns;
    valid_i = 0;
    # 10ns;
    $display("time %d,  Output: y_o %b, z1_o %b, z2_o %b, valid_o %b, ready_o %b", $time, y_o, z1_o, z2_o, valid_o, ready_o);
    # 10ns;
    $display("time %d,  Output: y_o %b, z1_o %b, z2_o %b, valid_o %b, ready_o %b", $time, y_o, z1_o, z2_o, valid_o, ready_o);
    # 10ns;
    $display("time %d,  Output: y_o %b, z1_o %b, z2_o %b, valid_o %b, ready_o %b", $time, y_o, z1_o, z2_o, valid_o, ready_o);
    # 10ns;
    $display("time %d,  Output: y_o %b, z1_o %b, z2_o %b, valid_o %b, ready_o %b", $time, y_o, z1_o, z2_o, valid_o, ready_o);
    # 10ns;
    $display("time %d,  Output: y_o %b, z1_o %b, z2_o %b, valid_o %b, ready_o %b", $time, y_o, z1_o, z2_o, valid_o, ready_o);
    # 10ns;
    $display("time %d,  Output: y_o %b, z1_o %b, z2_o %b, valid_o %b, ready_o %b", $time, y_o, z1_o, z2_o, valid_o, ready_o);
    wait(valid_o);
    # 10ns;
    ready_i = 1;
    $display("time %d,  Output: y_o %b, z1_o %b, z2_o %b, valid_o %b, ready_o %b", $time, y_o, z1_o, z2_o, valid_o, ready_o);
    # 10ns;
    ready_i = 0;
    $display("time %d,  Output: y_o %b, z1_o %b, z2_o %b, valid_o %b, ready_o %b", $time, y_o, z1_o, z2_o, valid_o, ready_o);
    # 30ns;
    $display("time %d,  Output: y_o %b, z1_o %b, z2_o %b, valid_o %b, ready_o %b", $time, y_o, z1_o, z2_o, valid_o, ready_o);

    # 10ns;
    x_i      = 31'b0000000000000000000000010000101; // 0.523
    z1_mem_i = 31'b0000000000000000000000100000000; // 1
    z2_mem_i = 31'b0;
    // parameters
    // a0_i, c0_i, r_i, g_i, h_i = 0.861, 0.509, 0.946, 0.521, 0.509
    a0_i  = 9'b0_11011100;
    c0_i  = 9'b0_10000010;
    r_i   = 9'b0_11110010;
    g_i   = 9'b0_10000101;
    h_i   = 9'b0_10000010;

    # 30ns;
    valid_i = 1;
    # 10ns;
    valid_i = 0;
    # 10ns;
    $display("time %d,  Output: y_o %b, z1_o %b, z2_o %b, valid_o %b, ready_o %b", $time, y_o, z1_o, z2_o, valid_o, ready_o);
    # 10ns;
    $display("time %d,  Output: y_o %b, z1_o %b, z2_o %b, valid_o %b, ready_o %b", $time, y_o, z1_o, z2_o, valid_o, ready_o);
    # 10ns;
    $display("time %d,  Output: y_o %b, z1_o %b, z2_o %b, valid_o %b, ready_o %b", $time, y_o, z1_o, z2_o, valid_o, ready_o);
    # 10ns;
    $display("time %d,  Output: y_o %b, z1_o %b, z2_o %b, valid_o %b, ready_o %b", $time, y_o, z1_o, z2_o, valid_o, ready_o);
    # 10ns;
    $display("time %d,  Output: y_o %b, z1_o %b, z2_o %b, valid_o %b, ready_o %b", $time, y_o, z1_o, z2_o, valid_o, ready_o);
    # 10ns;
    $display("time %d,  Output: y_o %b, z1_o %b, z2_o %b, valid_o %b, ready_o %b", $time, y_o, z1_o, z2_o, valid_o, ready_o);
    wait(valid_o);
    # 10ns;
    ready_i = 1;
    $display("time %d,  Output: y_o %b, z1_o %b, z2_o %b, valid_o %b, ready_o %b", $time, y_o, z1_o, z2_o, valid_o, ready_o);
    # 10ns;
    ready_i = 0;
    $display("time %d,  Output: y_o %b, z1_o %b, z2_o %b, valid_o %b, ready_o %b", $time, y_o, z1_o, z2_o, valid_o, ready_o);
    # 30ns;
    $display("time %d,  Output: y_o %b, z1_o %b, z2_o %b, valid_o %b, ready_o %b", $time, y_o, z1_o, z2_o, valid_o, ready_o);

    # 10ns;
    x_i      = 31'b0000000000000000000000010011101; // 0.61617
    z1_mem_i = 31'b0000000000000000000000101010110; // 1.33751
    z2_mem_i = 31'b0000000000000000000000101001011; // 1.29602
    // parameters
    // a0_i, c0_i, r_i, g_i, h_i = 0.876, 0.483, 0.949, 0.519, 0.483
    a0_i  = 9'b0_11100000;
    c0_i  = 9'b0_01111011;
    r_i   = 9'b0_11110010;
    g_i   = 9'b0_10000100;
    h_i   = 9'b0_01111011;

    # 30ns;
    valid_i = 1;
    # 10ns;
    valid_i = 0;
    # 10ns;
    $display("time %d,  Output: y_o %b, z1_o %b, z2_o %b, valid_o %b, ready_o %b", $time, y_o, z1_o, z2_o, valid_o, ready_o);
    # 10ns;
    $display("time %d,  Output: y_o %b, z1_o %b, z2_o %b, valid_o %b, ready_o %b", $time, y_o, z1_o, z2_o, valid_o, ready_o);
    # 10ns;
    $display("time %d,  Output: y_o %b, z1_o %b, z2_o %b, valid_o %b, ready_o %b", $time, y_o, z1_o, z2_o, valid_o, ready_o);
    # 10ns;
    $display("time %d,  Output: y_o %b, z1_o %b, z2_o %b, valid_o %b, ready_o %b", $time, y_o, z1_o, z2_o, valid_o, ready_o);
    # 10ns;
    $display("time %d,  Output: y_o %b, z1_o %b, z2_o %b, valid_o %b, ready_o %b", $time, y_o, z1_o, z2_o, valid_o, ready_o);
    # 10ns;
    $display("time %d,  Output: y_o %b, z1_o %b, z2_o %b, valid_o %b, ready_o %b", $time, y_o, z1_o, z2_o, valid_o, ready_o);
    wait(valid_o);
    # 10ns;
    ready_i = 1;
    $display("time %d,  Output: y_o %b, z1_o %b, z2_o %b, valid_o %b, ready_o %b", $time, y_o, z1_o, z2_o, valid_o, ready_o);
    # 10ns;
    ready_i = 0;
    $display("time %d,  Output: y_o %b, z1_o %b, z2_o %b, valid_o %b, ready_o %b", $time, y_o, z1_o, z2_o, valid_o, ready_o);
    # 30ns;
    $display("time %d,  Output: y_o %b, z1_o %b, z2_o %b, valid_o %b, ready_o %b", $time, y_o, z1_o, z2_o, valid_o, ready_o);

    $stop();
end

endmodule