module CAR_V1_tb ();
    
    timeunit 1ns;
    timeprecision 1ps;

    localparam time CLK_PERIOD = 5ns;
    localparam unsigned RST_CLK_CYCLES = 10;

    localparam unsigned ACQ_DELAY  = 3ns;
    localparam unsigned APPL_DELAY = 1ns;
    
    localparam unsigned FRC_BIT_RESOLUTION      = 10;
    localparam unsigned INT_BIT_RESOLUTION      = 25;
    localparam unsigned NUM_BIT_RESOLUTION_PARA = 1+FRC_BIT_RESOLUTION;
    localparam unsigned NUM_BIT_RESOLUTION_DATA = 1+INT_BIT_RESOLUTION+FRC_BIT_RESOLUTION;
    localparam unsigned NUM_CHANNELS    = 35;
    localparam unsigned NUM_ADDR_WIDTH  = 6;

    localparam SAMPLING_RATE = 48;
    localparam TIME_WINDOW = 50;
    localparam SOUND_SOURCE_LENGHT = SAMPLING_RATE*TIME_WINDOW;
    
    // input interface
    logic clk, rst_ni, rst_n;
    logic signed [NUM_BIT_RESOLUTION_DATA-1 : 0] x;
    logic signed [NUM_BIT_RESOLUTION_DATA-1 : 0] y_o [NUM_CHANNELS-1:0];
    logic signed [NUM_BIT_RESOLUTION_DATA-1 : 0] z1_o [NUM_CHANNELS-1:0];
    logic signed [NUM_BIT_RESOLUTION_DATA-1 : 0] z2_o [NUM_CHANNELS-1:0];
    logic signed [NUM_BIT_RESOLUTION_DATA-1 : 0] mnt_y_o_queue[$] [NUM_CHANNELS-1:0];
    logic valid_i, ready_i;
    integer cnt, n_checks;
    int fd;
    // output interface
    // logic [NUM_BIT_RESOLUTION_DATA-1 : 0] z1_o, z2_o, y_o;
    logic valid_o, ready_o;

    clk_rst_gen #(
		.CLK_PERIOD 				(CLK_PERIOD),
		.RST_CLK_CYCLES 			(RST_CLK_CYCLES)
	)	i_clk_rst_gen (

		.clk_o 						(clk),
		.rst_no 					(rst_n)
	);
    
    // Instantiate the DUT
    CAR_module_v1 #(
        .FRC_BIT_RESOLUTION         (FRC_BIT_RESOLUTION),
        .INT_BIT_RESOLUTION         (INT_BIT_RESOLUTION),
        .NUM_BIT_RESOLUTION_DATA    (NUM_BIT_RESOLUTION_DATA),
        .NUM_BIT_RESOLUTION_PARA    (NUM_BIT_RESOLUTION_PARA),
        .NUM_CHANNELS               (NUM_CHANNELS),
        .NUM_ADDR_WIDTH             (NUM_ADDR_WIDTH)
    ) dut (
        .clk 						(clk),
        .rst_ni 					(rst_ni),
        .ready_i 					(ready_i),
        .valid_i 					(valid_i),
        .x                          (x),

        .valid_o 					(valid_o),
        .ready_o 					(ready_o),
        .y_o                        (y_o),
        .z1_o                       (z1_o),
        .z2_o                       (z2_o)
    );

event pulse_rsp_analysis;
string file_loc;
// initial begin
//     $sformat(file_loc, "../result/CAR_SimOut_FRC%d",FRC_BIT_RESOLUTION);
//     $display(file_loc);
//     fd = $fopen(file_loc, "w");
    
//     ready_i = 0;
//     valid_i = 0;
//     rst_ni  = 1;

//     # 10ns;
//     rst_ni = 0;
//     # 10ns;
//     rst_ni = 1;

//     # 10ns;
//     x = 31'b000_0000_0000_0000_0000_0001_0000_0000;
//     cnt = 1;

//     # 10ns;
//     valid_i = 1; // next state = DATA_IN
//     # 10ns;
//     valid_i = 0; // state = DATA_IN

//     # 10ns; // state = READ_MEM
//     // √ para_i_car
//     // √ data_i_car z1,z2,y
//     // √ x_d, x_q 
//     # 10ns; // state = CAR_COMPUTE
//     # 10ns; // CAR1
//     # 10ns; // CAR2
//     # 10ns; // CAR3
//     # 10ns; // CAR4
//     // √ y_d, z1_d, z2_d
//     # 10ns; // CAR5
//     // √ y_d, z1_d, z2_d
//     # 10ns; // WAIT_FOR_READY
//     // √ y_d, z1_d, z2_d
//     # 10ns; // TRANSFER // state = WRITE_MEM
//     // check memory update
//     # 10ns; // state = NEXT_CNT
//     // cnt_d = 1

//     # 10ns; // state = DATA_IN
//     # 10ns; // state = read_mem
//     // √ para_i_car
//     // √ data_i_car z1,z2,y
//     // √ x_d, x_q 
//     # 10ns; // state = CAR_COMPUTE
//     # 10ns; // CAR1
//     # 10ns; // CAR2
//     # 10ns; // CAR3
//     # 10ns; // CAR4
//     // y_d, z1_d, z2_d
//     # 10ns; // CAR5
//     // y_d, z1_d, z2_d
//     # 10ns; // WAIT_FOR_READY
//     // y_d, z1_d, z2_d
//     # 10ns; // TRANSFER // state = WRITE_MEM
//     // check memory update
//     # 10ns; // state = NEXT_CNT
//     // cnt_d = 2

//     # 110ns; // 11 cycles per CAR computation
//     // cnt_d = 3
//     # 220ns;
//     // cnt_d = 5
//     # 3300ns;
//     // cnt_d = 35 -> 'h23
//     // $fdisplay(fd, "%d, input (b): %b\n%p\n%p\n%p", cnt, x, y_o, z1_o, z2_o);

//     $fdisplay(fd, "%d, input (b): %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d ", cnt, x, y_o[0],  y_o[1],  y_o[2],  y_o[3],  y_o[4],  y_o[5],  y_o[6],
//                                                                        y_o[7],  y_o[8],  y_o[9],  y_o[10], y_o[11], y_o[12], y_o[13],
//                                                                        y_o[14], y_o[15], y_o[16], y_o[17], y_o[18], y_o[19], y_o[20],
//                                                                        y_o[21], y_o[22], y_o[23], y_o[24], y_o[25], y_o[26], y_o[27],
//                                                                        y_o[28], y_o[29], y_o[30], y_o[31], y_o[32], y_o[33], y_o[34] );

//     for (cnt = 1; cnt < 600; cnt = cnt + 1) begin
//         # 10ns;
//         # 10ns; // WaitForReady
//         ready_i = 1;
//         # 10ns; // Transfer
//         ready_i = 1;
//         # 10ns; // IDLE
//         # 10ns; // WaitForValid
//         x = 31'b0000000_00000000_00000000_00000000;
//         # 10ns;
//         valid_i = 1; // next state = DATA_IN
//         # 10ns;
//         valid_i = 0; // state = DATA_IN
//         # 3850ns; 
//         // $fdisplay(fd, "%d, input (b): %b\n%p\n%p\n%p", cnt, x, y_o, z1_o, z2_o);
//         $fdisplay(fd, "%d, input (b): %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d  ", cnt, x, y_o[0],  y_o[1],  y_o[2],  y_o[3],  y_o[4],  y_o[5],  y_o[6],
//                                                                        y_o[7],  y_o[8],  y_o[9],  y_o[10], y_o[11], y_o[12], y_o[13],
//                                                                        y_o[14], y_o[15], y_o[16], y_o[17], y_o[18], y_o[19], y_o[20],
//                                                                        y_o[21], y_o[22], y_o[23], y_o[24], y_o[25], y_o[26], y_o[27],
//                                                                        y_o[28], y_o[29], y_o[30], y_o[31], y_o[32], y_o[33], y_o[34] );

//     end
//     $fclose(fd);  
//     # 10ns;
//     -> pulse_rsp_analysis;
// end

int fd1, f_row, count;
logic [1+INT_BIT_RESOLUTION:0] sound_sample;
logic [1+INT_BIT_RESOLUTION:0] sound_source [0 : SOUND_SOURCE_LENGHT-1];
event event_read_file_src;
initial begin
    // @(pulse_rsp_analysis);
    # 4000ns;
    f_row = 0;
    fd1 = $fopen("/home/hasgari/ownCloud2/Institution/INI/AVATronic/ini_avatronic_anc_project/hdl_design/datasets/AVA_dataset/sound_m2_HP3_B_U.txt","r");
    $display("Load AVA sounds.");
    while(!$feof(fd1)) begin
        $fscanf(fd1, "%d", sound_sample);
        sound_source[f_row] = sound_sample;
        f_row += 1;
    end
    $fclose(fd1);
    -> event_read_file_src;
end

initial begin: application_block
    @(event_read_file_src);
    valid_i = 1'b0;
    ready_i = 1'b1;    
    cnt = 0;
    while (count < SOUND_SOURCE_LENGHT) begin
        @(posedge clk);
        valid_i = 1;
        // x = 0;
        x = {sound_source[count], 10'b0};
        $display("CAR input recieved at : %t ", $time());
        @(posedge clk);
        count += 1;
        valid_i = 0;
        # 20833; // 1/sr (ns)
    end
    @(posedge clk);
end

// int fd1;
initial begin: acquire_block 
logic signed [NUM_BIT_RESOLUTION_DATA-1 : 0] mnt_y_o [NUM_CHANNELS-1:0];
n_checks = 0;  
    wait (rst_n);
    while (n_checks < SOUND_SOURCE_LENGHT) begin
        @(posedge clk); 
        if (valid_o) begin
            mnt_y_o_queue.push_back(y_o);
            n_checks = n_checks + 1;
            $display("n_checks : %d", n_checks);
        end              
    end 
    fd1 = $fopen("/home/hasgari/ownCloud2/Institution/INI/AVATronic/ini_avatronic_anc_project/hdl_design/result/CAR_SimOut_AVA_data_sound_m2_B_U","w");
    for (int i=0; i<n_checks; i++) begin
        mnt_y_o = mnt_y_o_queue.pop_front();
        $fdisplay(fd1, "%d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d  ", mnt_y_o[0],  mnt_y_o[1],  mnt_y_o[2],  mnt_y_o[3],  mnt_y_o[4],  mnt_y_o[5],  mnt_y_o[6],
                                                                       mnt_y_o[7],  mnt_y_o[8],  mnt_y_o[9],  mnt_y_o[10], mnt_y_o[11], mnt_y_o[12], mnt_y_o[13],
                                                                       mnt_y_o[14], mnt_y_o[15], mnt_y_o[16], mnt_y_o[17], mnt_y_o[18], mnt_y_o[19], mnt_y_o[20],
                                                                       mnt_y_o[21], mnt_y_o[22], mnt_y_o[23], mnt_y_o[24], mnt_y_o[25], mnt_y_o[26], mnt_y_o[27],
                                                                       mnt_y_o[28], mnt_y_o[29], mnt_y_o[30], mnt_y_o[31], mnt_y_o[32], mnt_y_o[33], mnt_y_o[34] );        
    end
    #100;
    $fclose();
end




endmodule