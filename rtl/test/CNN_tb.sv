
import pkg_parameters::*;
module CNN_tb();
	timeunit 1ns;
	timeprecision 1ps;

	localparam time CLK_PERIOD = 50ns;
	localparam unsigned RST_CLK_CYCLES = 10;
	

    localparam F_IN_W1       = 29;
    localparam F_IN_H1       = 13;
    localparam F_IN_D1       = 1;
    localparam F_OUT_W1      = 13;
    localparam F_OUT_H1      = 5;
    localparam F_OUT_D1      = 2;
    localparam F_IN_W2       = F_OUT_W1;
    localparam F_IN_H2       = F_OUT_H1;
    localparam F_IN_D2       = F_OUT_D1;
    localparam F_OUT_W2      = 5;
    localparam F_OUT_H2      = 1;
    localparam F_OUT_D2      = 8;
    localparam KERNEL_SIZE   = 3;
    localparam STRIDE        = 2;
    localparam PADDING       = 0;
    localparam NUM_NEURONS   = 60;
    localparam NUM_CLASSES 	 = 9;
    localparam k = NUM_NEURONS; // maximum( all the reading values from line per line)
    //----------------------------------------------------------------------------
    // monitpring parameters
    //............................................................................
    integer n_checks_l1,
			n_checks_l2;

	typedef struct {
		logic valid;
		logic signed [FEATURE_MAP_RESOLUTION-1:0] data [0: F_OUT_D1-1];
		logic [FEATURE_MAP_ADDRWIDE-1:0] addr;
	} conv2d_L1_t;

	typedef struct {
		logic valid;
		logic signed [FEATURE_MAP_RESOLUTION-1:0] data [0: F_OUT_D2-1];
		logic [FEATURE_MAP_ADDRWIDE-1:0] addr;
	} conv2d_L2_t;


	conv2d_L1_t mnt_resp_conv2d_L1_queue[$], act_resp_conv2d_L1; 
	conv2d_L2_t mnt_resp_conv2d_L2_queue[$], act_resp_conv2d_L2;



    //----------------------------------------------------------------------------
	// input interfaces
	//----------------------------------------------------------------------------	
	logic 									clk, rst_n;

	logic 									cnn_input_valid; 								
	logic [FEATURE_MAP_RESOLUTION-1 :0]		cnn_input_data[0 : F_IN_D1-1];			
	logic [FEATURE_MAP_ADDRWIDE-1:0]		cnn_input_addr; 					
	logic									cnn_input_ready; 

	//conv2d 1 interface -----------------------------------------------------------	
	logic 									conv2d1_kernel_weights_valid;
	logic [KERNEL_WEIGHTS_RESOLUTION-1 : 0]	conv2d1_kernel_weights_data [0 : F_OUT_D1-1][0 : F_IN_D1-1]; 		
	logic [KERNEL_WEIGHTS_ADDRWIDE-1:0]		conv2d1_kernel_weights_addr; 		

	// logic 								initialize_kernel_bias_ram1; 
	logic [KERNEL_BIAS_RESOLUTION-1:0] 		conv2d1_kernel_biases_data [0 : F_OUT_D1-1];	
	// logic [KERNEL_BIAS_ADDRWIDE-1:0]		kernel_biases_addr1;
	logic [FEATURE_MAP_RESOLUTION-1:0] 		conv2d1_kernel_dwscaling_z3; 
	logic [3:0] 							conv2d1_kernel_dwscaling_n [0:F_OUT_D1-1]; 
	logic [KERNEL_BIAS_RESOLUTION-1:0] 		conv2d1_kernel_dwscaling_m0[0:F_OUT_D1-1];
	logic [KERNEL_BIAS_RESOLUTION-1:0] 		conv2d1_kernel_dwscaling_b[0:F_OUT_D1-1];
	
	//conv2d 2 interface ------------------------------------------------------------	
	logic 									conv2d2_kernel_weights_valid;
	logic [KERNEL_WEIGHTS_RESOLUTION-1 : 0]	conv2d2_kernel_weights_data [0 : F_OUT_D2-1][0 : F_IN_D2-1]; 		
	logic [KERNEL_WEIGHTS_ADDRWIDE-1:0]		conv2d2_kernel_weights_addr; 	

	// logic 								initialize_kernel_bias_ram1; 
	logic [KERNEL_BIAS_RESOLUTION-1:0] 		conv2d2_kernel_biases_data [0 : F_OUT_D2-1];	
	// logic [KERNEL_BIAS_ADDRWIDE-1:0]		kernel_biases_addr1; 
	logic [FEATURE_MAP_RESOLUTION-1:0] 		conv2d2_kernel_dwscaling_z3;	
	logic [3:0] 							conv2d2_kernel_dwscaling_n [0:F_OUT_D2-1]; 
	logic [KERNEL_BIAS_RESOLUTION-1:0] 		conv2d2_kernel_dwscaling_m0 [0:F_OUT_D2-1];	
	logic [KERNEL_BIAS_RESOLUTION-1:0] 		conv2d2_kernel_dwscaling_b [0:F_OUT_D2-1];	

	//dense 1  interface ----------------------------------------------------
    logic                                   dense1_weights_valid; // initialize_dense__weights_ram_i
    logic [DENSE_WEIGHTS_RESOLUTION-1 : 0]  dense1_weights_data[0 : NUM_NEURONS-1];
    logic [DENSE_WEIGHTS_ADDRWIDE-1 : 0]    dense1_weights_addr;

    logic                                   dense1_biases_valid; 
    logic [DENSE_BIAS_RESOLUTION-1 : 0]     dense1_biases_data [0 : NUM_NEURONS-1];
    logic [DENSE_BIAS_ADDRWIDE-1 : 0]       dense1_biases_addr;
    logic [FEATURE_MAP_RESOLUTION-1 : 0] 	dense1_dwscaling_z3;
    logic [DENSE_BIAS_RESOLUTION-1 : 0] 	dense1_dwscaling_m0;
    logic [DENSE_BIAS_RESOLUTION-1 : 0] 	dense1_dwscaling_b [0 : NUM_NEURONS-1];
    logic [3:0] 							dense1_dwscaling_n;

	//dense 2 interface ----------------------------------------------------
    logic                                   dense2_weights_valid; // initialize_dense__weights_ram_i
    logic [DENSE_WEIGHTS_RESOLUTION-1 : 0]  dense2_weights_data[0 : NUM_CLASSES-1];
    logic [DENSE_WEIGHTS_ADDRWIDE-1 : 0]    dense2_weights_addr;

    logic                                   dense2_biases_valid; 
    logic [DENSE_BIAS_RESOLUTION-1 : 0]     dense2_biases_data [0 : NUM_CLASSES-1];
    logic [DENSE_BIAS_ADDRWIDE-1 : 0]       dense2_biases_addr;
    logic [FEATURE_MAP_RESOLUTION-1 : 0] 	dense2_dwscaling_z3;
    logic [DENSE_BIAS_RESOLUTION-1 : 0] 	dense2_dwscaling_b[0 : NUM_CLASSES-1];
    logic [DENSE_BIAS_RESOLUTION-1 : 0] 	dense2_dwscaling_m0;
    logic [3:0] 							dense2_dwscaling_n;    


	//----------------------------------------------------------------------------
	// output interfaces
	//----------------------------------------------------------------------------
	logic                                   cnn_prediction_valid[0: NUM_CLASSES-1];
    logic [FEATURE_MAP_RESOLUTION-1 : 0]  cnn_prediction_data[0: NUM_CLASSES-1];
    logic                                   cnn_prediction_ready;

	//----------------------------------------------------------------------------
	// module instantiating 
	//----------------------------------------------------------------------------

	clk_rst_gen #(
		.CLK_PERIOD 				(CLK_PERIOD),
		.RST_CLK_CYCLES 			(RST_CLK_CYCLES)
	)	i_clk_rst_gen (

		.clk_o 						(clk),
		.rst_no 					(rst_n)
	);

	CNN #( 
		.F_IN_W1 (F_IN_W1), 
		.F_IN_H1 (F_IN_H1),
		.F_IN_D1 (F_IN_D1),
		.F_OUT_W1 (F_OUT_W1),
		.F_OUT_H1 (F_OUT_H1),
		.F_OUT_D1 (F_OUT_D1),
		.F_IN_W2 (F_IN_W2),
		.F_IN_H2 (F_IN_H2),
		.F_IN_D2 (F_IN_D2),
		.F_OUT_W2 (F_OUT_W2),
		.F_OUT_H2 (F_OUT_H2),
		.F_OUT_D2 (F_OUT_D2),
		.NUM_NEURONS(NUM_NEURONS),
		.NUM_CLASSES(NUM_CLASSES))
	dut ( 
		.clk_i                         (clk), 
		.rst_ni                        (rst_n), 
		.cnn_input_valid_i             (cnn_input_valid), 
		.cnn_input_data_i              (cnn_input_data), 
		.cnn_input_addr_i              (cnn_input_addr), 
		.cnn_input_ready_o             (cnn_input_ready), 
		.cnn_prediction_valid_o        (cnn_prediction_valid), 
		.cnn_prediction_data_o         (cnn_prediction_data), 
		.cnn_prediction_ready_i        (cnn_prediction_ready), 

		.conv2d1_kernel_weights_valid_i(conv2d1_kernel_weights_valid), 
		.conv2d1_kernel_weights_data_i (conv2d1_kernel_weights_data), 
		.conv2d1_kernel_weights_addr_i (conv2d1_kernel_weights_addr), 
		.conv2d1_kernel_biases_data_i  (conv2d1_kernel_biases_data), 
		.conv2d1_kernel_dwscaling_z3_i (conv2d1_kernel_dwscaling_z3), 
		.conv2d1_kernel_dwscaling_m0_i (conv2d1_kernel_dwscaling_m0), 
		.conv2d1_kernel_dwscaling_n_i  (conv2d1_kernel_dwscaling_n), 
		.conv2d1_kernel_dwscaling_b_i  (conv2d1_kernel_dwscaling_b), 
		.conv2d1_vis_feature_map_valid_o (act_resp_conv2d_L1.valid),
		.conv2d1_vis_feature_map_data_o (act_resp_conv2d_L1.data),
		.conv2d1_vis_feature_map_addr_o (act_resp_conv2d_L1.addr),


		.conv2d2_kernel_weights_valid_i(conv2d2_kernel_weights_valid), 
		.conv2d2_kernel_weights_data_i (conv2d2_kernel_weights_data), 
		.conv2d2_kernel_weights_addr_i (conv2d2_kernel_weights_addr), 
		.conv2d2_kernel_biases_data_i  (conv2d2_kernel_biases_data),  
		.conv2d2_kernel_dwscaling_z3_i (conv2d2_kernel_dwscaling_z3), 
		.conv2d2_kernel_dwscaling_m0_i (conv2d2_kernel_dwscaling_m0), 
		.conv2d2_kernel_dwscaling_n_i  (conv2d2_kernel_dwscaling_n),
		.conv2d2_kernel_dwscaling_b_i  (conv2d2_kernel_dwscaling_b),
		.conv2d2_vis_feature_map_valid_o (act_resp_conv2d_L2.valid),
		.conv2d2_vis_feature_map_data_o (act_resp_conv2d_L2.data),
		.conv2d2_vis_feature_map_addr_o (act_resp_conv2d_L2.addr),		

		.dense1_weights_valid_i        (dense1_weights_valid), 
		.dense1_weights_data_i         (dense1_weights_data), 
		.dense1_weights_addr_i         (dense1_weights_addr), 
		.dense1_biases_valid_i         (dense1_biases_valid), 
		.dense1_biases_data_i          (dense1_biases_data), 
		.dense1_biases_addr_i          (dense1_biases_addr), 
		.dense1_dwscaling_z3_i         (dense1_dwscaling_z3),
		.dense1_dwscaling_m0_i         (dense1_dwscaling_m0),
		.dense1_dwscaling_b_i          (dense1_dwscaling_b),
		.dense1_dwscaling_n_i          (dense1_dwscaling_n), 		

		.dense2_weights_valid_i        (dense2_weights_valid), 
		.dense2_weights_data_i         (dense2_weights_data), 
		.dense2_weights_addr_i         (dense2_weights_addr), 
		.dense2_biases_valid_i         (dense2_biases_valid), 
		.dense2_biases_data_i          (dense2_biases_data), 
		.dense2_biases_addr_i          (dense2_biases_addr),
		.dense2_dwscaling_z3_i         (dense2_dwscaling_z3),
		.dense2_dwscaling_m0_i         (dense2_dwscaling_m0),
		.dense2_dwscaling_b_i          (dense2_dwscaling_b),
		.dense2_dwscaling_n_i          (dense2_dwscaling_n) 		
		);
	
	//----------------------------------------------------------------------------
	// Read kernels and feature in form files
	//----------------------------------------------------------------------------
	int conv2D_1_w, conv2D_2_w;
	int conv2D_1_b, conv2D_2_b;
	int feature_in_file;  
	int dense_l1_b, dense_l1_m0, dense_l1_n, dense_l1_z3;
	int dense_l2_b, dense_l2_m0, dense_l2_n, dense_l2_z3;
	int conv2d_l1_n, conv2d_l1_b, conv2d_l1_m0, conv2d_l1_z3;
	int conv2d_l2_n, conv2d_l2_b, conv2d_l2_m0, conv2d_l2_z3;

	int dense_1_w, dense_2_w;
	int dense_1_b, dense_2_b;
	int k_ch;
	int k_row;

	bit [KERNEL_BIAS_RESOLUTION-1:0] 						w [0:k-1];
	bit [KERNEL_WEIGHTS_RESOLUTION-1:0] 					k1_w [0:F_OUT_D1-1][0:F_IN_D1-1][0:KERNEL_SIZE*KERNEL_SIZE-1];
	bit [KERNEL_BIAS_RESOLUTION-1:0]						k1_b [0:F_OUT_D1-1];

	bit [KERNEL_WEIGHTS_RESOLUTION-1:0] 					k2_w [0:F_OUT_D2-1][0:F_IN_D2-1][0:KERNEL_SIZE*KERNEL_SIZE-1];
	bit [KERNEL_BIAS_RESOLUTION-1:0]						k2_b [0:F_OUT_D2-1];

	bit [KERNEL_WEIGHTS_RESOLUTION-1:0]						kd1_w [0:NUM_NEURONS-1][0:F_OUT_D2*F_OUT_H2*F_OUT_W2-1];
	bit [KERNEL_BIAS_RESOLUTION-1:0] 						kd1_b [0:NUM_NEURONS-1];
	bit [KERNEL_BIAS_RESOLUTION-1:0] 						d1_b [0:NUM_NEURONS-1];

	bit [KERNEL_WEIGHTS_RESOLUTION-1:0] 					kd2_w [0:NUM_CLASSES-1][0:NUM_NEURONS-1];
	bit [KERNEL_BIAS_RESOLUTION-1:0] 						kd2_b [0:NUM_CLASSES-1];	
	bit [KERNEL_BIAS_RESOLUTION-1:0] 						d2_b [0:NUM_CLASSES-1];

	bit [FEATURE_MAP_RESOLUTION-1:0] 						fin[0:F_IN_W1-1];
	bit [FEATURE_MAP_RESOLUTION-1:0] 						feature_in[0:F_IN_D1-1][0:F_IN_W1*F_IN_H1-1];
	
	initial begin
		#100;
		//=============== import conv_2D layer 1 weights ==============================================
		conv2D_1_w = $fopen("../test/quantized_weights_biases/conv2D_1_weights.txt","r");
		k_ch = 0;
		while(!$feof(conv2D_1_w)) begin
			//------ conv2D layer 1
			$fscanf(conv2D_1_w, "%d %d %d %d %d %d %d %d %d ", w[0] , w[1], w[2],  w[3], w[4], w[5], w[6], w[7], w[8]);
			$display("Line W : " ,w[0] , w[1], w[2],  w[3], w[4], w[5], w[6], w[7], w[8]);
			//------ conv2D layer 2
			// $fscanf(conv2D_1_w, "%d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d", w[0] , w[1], w[2],  w[3], w[4], w[5], w[6], w[7], w[8], w[9], w[10], w[11], w[12] , w[13], w[14],  w[15], w[16], w[17], w[18], w[19], w[20], w[21], w[22], w[23], w[24] , w[25], w[26],  w[27], w[28], w[29], w[30], w[31], w[32], w[33], w[34], w[35]);
			for (int i=0; i < F_IN_D1; i++) begin
				for (int j = 0; j < KERNEL_SIZE*KERNEL_SIZE; j++) begin
					k1_w [k_ch][i][j] = w[i+j*F_IN_D1];
				end 
			end 
			k_ch += 1;
		end	
		$fclose(conv2D_1_w);
		$display("Test Kw1 : %b ", k1_w[0][0][7]);	
			


		//=============== import conv_2D layer 1 biases ================================================
		conv2D_1_b = $fopen("../test/quantized_weights_biases/conv2D_1_biases.txt","r");
		k_ch = 0;
		while(!$feof(conv2D_1_b)) begin
			$fscanf(conv2D_1_b, "%d ", w[0]);
			$display("Line b: %b    ", w[0]);

			k1_b[k_ch] = w[0];
			k_ch += 1;
			// kernel_biases_data[k_ch] = w[0];
		end 
		$fclose(conv2D_1_b);
		$display("ALL weights and biases are succesfully read from files.");	 
		// #20 -> event_read_file_w_b;


		//=============== import conv_2D layer 2 weights ==============================================
		conv2D_2_w = $fopen("../test/quantized_weights_biases/conv2D_2_weights.txt","r");
		k_ch = 0;
		while(!$feof(conv2D_2_w)) begin
			// $fscanf(conv2D_2_w, "%d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d", w[0] , w[1], w[2],  w[3], w[4], w[5], w[6], w[7], w[8], w[9], w[10], w[11], w[12] , w[13], w[14],  w[15], w[16], w[17], w[18], w[19], w[20], w[21], w[22], w[23], w[24] , w[25], w[26],  w[27], w[28], w[29], w[30], w[31], w[32], w[33], w[34], w[35]);
			$fscanf(conv2D_2_w, "%d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d", w[0] , w[1], w[2],  w[3], w[4], w[5], w[6], w[7], w[8], w[9], w[10], w[11], w[12] , w[13], w[14],  w[15], w[16], w[17]);
			for (int i=0; i < F_IN_D2; i++) begin
				for (int j = 0; j < KERNEL_SIZE*KERNEL_SIZE; j++) begin
					// $display("kernel 2 %h ", w );
					k2_w [k_ch][i][j] = w[i+j*F_IN_D2];
				end 
			end 
			k_ch += 1;
			$display("kernel 2 %d %d ", w[0], w[1] );
		end	
		$fclose(conv2D_2_w);
		$display("Test Kw1 : %b ", k2_w[0][0][7]);	
			


		//=============== import conv_2D layer 2 biases ================================================
		conv2D_2_b = $fopen("../test/quantized_weights_biases/conv2D_2_biases.txt","r");
		k_ch = 0;
		while(!$feof(conv2D_2_b)) begin
			$fscanf(conv2D_2_b, "%d ", w[0]);
			$display("Line b: %b    ", w[0]);

			k2_b[k_ch] = w[0];
			k_ch += 1;
			// kernel_biases_data[k_ch] = w[0];
		end 
		$fclose(conv2D_2_b);
		$display("ALL weights and biases are succesfully read from files.");	 


		//============== dense 1 weights ===========================================================
		dense_1_w = $fopen("../test/quantized_weights_biases/dense_1_weights.txt","r");
		k_ch = 0;
		while(!$feof(dense_1_w)) begin
			$fscanf(dense_1_w, "%d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d", w[0] , w[1], w[2],  w[3], w[4], w[5], w[6], w[7], w[8], w[9], w[10], w[11], w[12] , w[13], w[14],  w[15], w[16], w[17], w[18], w[19], w[20], w[21], w[22], w[23], w[24] , w[25], w[26],  w[27], w[28], w[29], w[30], w[31], w[32], w[33], w[34], w[35], w[36], w[37], w[38], w[39]);
			// $display("Line dense W", w[0] , w[1], w[2],  w[3], w[4], w[5], w[6], w[7], w[8], w[9], w[10], w[11], w[12] , w[13], w[14],  w[15], w[16], w[17], w[18], w[19], w[20], w[21], w[22], w[23], w[24] , w[25], w[26],  w[27], w[28], w[29], w[30], w[31], w[32], w[33], w[34], w[35], w[36], w[37], w[38], w[39]);
			for (int i=0; i<F_OUT_D2*F_OUT_H2*F_OUT_W2; i++) begin
					kd1_w[k_ch][i]=w[i];
			end 
			k_ch += 1;
		end 
		$fclose(dense_1_w);

		//============== dense 1 biases =============================================================
		dense_1_b = $fopen("../test/quantized_weights_biases/dense_1_biases.txt","r");
		k_ch = 0;
		while(!$feof(dense_1_b)) begin
			$fscanf(dense_1_b, "%d ", w[0]);
			$display("Line b: %b    ", w[0]);

			kd1_b[k_ch] = w[0];
			k_ch += 1;
			// kernel_biases_data[k_ch] = w[0];
		end 
		$fclose(dense_1_b);

		//============== dense 2 weights ===========================================================
		dense_2_w = $fopen("../test/quantized_weights_biases/dense_2_weights.txt","r");
		k_ch = 0;
		while(!$feof(dense_2_w)) begin
			$fscanf(dense_2_w, "%d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d  %d %d %d %d %d %d %d %d %d %d  %d %d %d %d %d %d %d %d %d %d", w[0] , w[1], w[2],  w[3], w[4], w[5], w[6], w[7], w[8], w[9], w[10], w[11], w[12] , w[13], w[14],  w[15], w[16], w[17], w[18], w[19], w[20], w[21], w[22], w[23], w[24] , w[25], w[26],  w[27], w[28], w[29], w[30], w[31], w[32], w[33], w[34], w[35], w[36], w[37], w[38], w[39], w[40], w[41], w[42], w[43], w[44] , w[45], w[46],  w[47], w[48], w[49], w[50], w[51], w[52], w[53], w[54], w[55], w[56], w[57], w[58], w[59]);
			// $display("Line dense W", w[0] , w[1], w[2],  w[3], w[4], w[5], w[6], w[7], w[8], w[9], w[10], w[11], w[12] , w[13], w[14],  w[15], w[16], w[17], w[18], w[19], w[20], w[21], w[22], w[23], w[24] , w[25], w[26],  w[27], w[28], w[29], w[30], w[31], w[32], w[33], w[34], w[35], w[36], w[37], w[38], w[39]);
			for (int i=0; i<NUM_NEURONS; i++) begin
					kd2_w[k_ch][i]=w[i];
			end 
			k_ch += 1;
		end 
		$fclose(dense_2_w);

		//============== dense 2 biases =============================================================
		dense_2_b = $fopen("../test/quantized_weights_biases/dense_2_biases.txt","r");
		k_ch = 0;
		while(!$feof(dense_2_b)) begin
			$fscanf(dense_2_b, "%d ", w[0]);
			$display("Line b: %b    ", w[0]);

			kd2_b[k_ch] = w[0];
			k_ch += 1;
			// kernel_biases_data[k_ch] = w[0];
		end 
		$fclose(dense_2_b);

		//=============== import input feature (feature_in) =============================================
		feature_in_file = $fopen("../test/feature_ins/quantized_feature_in2.txt","r");
		k_row = 0;
		k_ch = 0;
		while(!$feof(feature_in_file)) begin
			$fscanf(feature_in_file, "%d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d ", fin[0], fin[1], fin[2], fin[3], fin[4], fin[5], fin[6], fin[7], fin[8], fin[9], fin[10], fin[11], fin[12], fin[13], fin[14], fin[15], fin[16], fin[17], fin[18], fin[19], fin[20], fin[21], fin[22], fin[23], fin[24], fin[25], fin[26], fin[27], fin[28] );
			
			for (int i = 0; i<F_IN_W1; i++) begin
				feature_in[k_ch][i + k_row*F_IN_W1] = fin[i];
			end 

			$display("feature in row", k_row);
			k_row += 1;
		end 

		//=============== assign down scaling factors (m0 & n) ===========================================
		//================================================================================================
		//--------------------conv2d L1 ----------------------------------------------------------------
		//================================================================================================

		// conv2d_l1_n = $fopen("../test/cnn_m0_n_b/conv2d_l1_dw_param.txt","r");
		// k_row = 0;
		// while(!$feof(conv2d_l1_n)) begin
		// 	$fscanf(conv2d_l1_n, "%d ", w[0], w[1]);			
		// 	conv2d1_kernel_dwscaling_n [k_row] 	= w[0];
		// 	conv2d1_kernel_dwscaling_m0 [k_row] 	= w[1];
		// 	$display("n value : %d", w[0]);
		// 	$display("m0 value : %d", w[1] );
		// 	k_row += 1;
		// end

		conv2d_l1_n = $fopen("../test/cnn_m0_n_b/conv2d_l1_n.txt","r");
		k_row = 0;
		while(!$feof(conv2d_l1_n)) begin
			$fscanf(conv2d_l1_n, "%d ", w[0]);			
			conv2d1_kernel_dwscaling_n [k_row] 	= w[0];
			k_row += 1;
		end  

		conv2d_l1_b = $fopen("../test/cnn_m0_n_b/conv2d_l1_b.txt","r");
		k_row = 0;
		while(!$feof(conv2d_l1_b)) begin
			$fscanf(conv2d_l1_b, "%d ", w[0]);			
			conv2d1_kernel_dwscaling_b [k_row] 	= w[0];
			k_row += 1;
		end 	
		
		conv2d_l1_m0 = $fopen("../test/cnn_m0_n_b/conv2d_l1_m0.txt","r");
		k_row = 0;
		while(!$feof(conv2d_l1_m0)) begin
			$fscanf(conv2d_l1_m0, "%d ", w[0]);			
			conv2d1_kernel_dwscaling_m0 [k_row] 	= w[0];
			k_row += 1;
		end 	
		
		conv2d_l1_z3 = $fopen("../test/cnn_m0_n_b/conv2d_l1_z3.txt","r");
		k_row = 0;
		while(!$feof(conv2d_l1_z3)) begin
			$fscanf(conv2d_l1_z3, "%d ", w[0]);			
			conv2d1_kernel_dwscaling_z3	= w[0];
			k_row += 1;
		end 
		//================================================================================================
		//--------------------conv2d L2 ----------------------------------------------------------------
		//================================================================================================			

		conv2d_l1_n = $fopen("../test/cnn_m0_n_b/conv2d_l2_n.txt","r");
		k_row = 0;
		while(!$feof(conv2d_l1_n)) begin
			$fscanf(conv2d_l1_n, "%d ", w[0]);			
			conv2d2_kernel_dwscaling_n [k_row] 	= w[0];
			k_row += 1;
		end  

		conv2d_l1_b = $fopen("../test/cnn_m0_n_b/conv2d_l2_b.txt","r");
		k_row = 0;
		while(!$feof(conv2d_l1_b)) begin
			$fscanf(conv2d_l1_b, "%d ", w[0]);			
			conv2d2_kernel_dwscaling_b [k_row] 	= w[0];
			k_row += 1;
		end 	
		
		conv2d_l1_m0 = $fopen("../test/cnn_m0_n_b/conv2d_l2_m0.txt","r");
		k_row = 0;
		while(!$feof(conv2d_l1_m0)) begin
			$fscanf(conv2d_l1_m0, "%d ", w[0]);			
			conv2d2_kernel_dwscaling_m0 [k_row] 	= w[0];
			k_row += 1;
		end 	
		
		conv2d_l1_z3 = $fopen("../test/cnn_m0_n_b/conv2d_l2_z3.txt","r");
		k_row = 0;
		while(!$feof(conv2d_l1_z3)) begin
			$fscanf(conv2d_l1_z3, "%d ", w[0]);			
			conv2d2_kernel_dwscaling_z3	= w[0];
			k_row += 1;
		end 

		//================================================================================================
		//--------------------dense L1 ----------------------------------------------------------------
		//================================================================================================

		dense_l1_b = $fopen("../test/cnn_m0_n_b/dense_l1_n.txt","r");
		k_row = 0;
		while(!$feof(dense_l1_b)) begin
			$fscanf(dense_l1_b, "%d ", w[0] );			
			dense1_dwscaling_n = w[0];
			k_row += 1;
		end 	

		dense_l1_b = $fopen("../test/cnn_m0_n_b/dense_l1_m0.txt","r");
		k_row = 0;
		while(!$feof(dense_l1_b)) begin
			$fscanf(dense_l1_b, "%d ", w[0] );			
			dense1_dwscaling_m0 = w[0];
			k_row += 1;
		end 	

		dense_l1_b = $fopen("../test/cnn_m0_n_b/dense_l1_z3.txt","r");
		k_row = 0;
		while(!$feof(dense_l1_b)) begin
			$fscanf(dense_l1_b, "%d ", w[0] );			
			dense1_dwscaling_z3 = w[0];
			$display("feature in row", k_row);
			k_row += 1;
		end 

		dense_l1_b = $fopen("../test/cnn_m0_n_b/dense_l1_b.txt","r");
		k_row = 0;
		while(!$feof(dense_l1_b)) begin
			$fscanf(dense_l1_b, "%d ", w[0] );			
			dense1_dwscaling_b [k_row] = w[0];
			k_row += 1;
		end 

		//================================================================================================
		//--------------------dense L1 ----------------------------------------------------------------
		//================================================================================================		

		dense_l1_b = $fopen("../test/cnn_m0_n_b/dense_l2_n.txt","r");
		k_row = 0;
		while(!$feof(dense_l1_b)) begin
			$fscanf(dense_l1_b, "%d ", w[0] );			
			dense2_dwscaling_n = w[0];
			k_row += 1;
		end 	

		dense_l1_b = $fopen("../test/cnn_m0_n_b/dense_l2_m0.txt","r");
		k_row = 0;
		while(!$feof(dense_l1_b)) begin
			$fscanf(dense_l1_b, "%d ", w[0] );			
			dense2_dwscaling_m0 = w[0];
			k_row += 1;
		end 	

		dense_l1_b = $fopen("../test/cnn_m0_n_b/dense_l2_z3.txt","r");
		k_row = 0;
		while(!$feof(dense_l1_b)) begin
			$fscanf(dense_l1_b, "%d ", w[0] );			
			dense2_dwscaling_z3 = w[0];
			$display("feature in row", k_row);
			k_row += 1;
		end 

		dense_l2_b = $fopen("../test/cnn_m0_n_b/dense_l2_b.txt","r");
		k_row = 0;
		while(!$feof(dense_l2_b)) begin
			$fscanf(dense_l2_b, "%d ", w[0] );			
			dense2_dwscaling_b [k_row] = w[0];
			k_row += 1;
		end 

		#20 -> event_read_file_w_b_fin;
	end
	event 	event_read_file_w_b_fin;
	event 	event_load_w_b_rams;
	int 	count;
	
	initial begin
		@(event_read_file_w_b_fin);
		count = 0;
		conv2d1_kernel_weights_valid = 1'b0;
		conv2d2_kernel_weights_valid = 1'b0;
		$display("[%t] Start sending weights to RAMs", $time);
		# 1000;

		//================ conv2d layer 1 ==========================
		for (int i = 0; i < F_OUT_D1; i++) begin
			conv2d1_kernel_biases_data[i] = k1_b[i];
		end 

		while(count < KERNEL_SIZE*KERNEL_SIZE) begin
			@(posedge clk);
			conv2d1_kernel_weights_valid = 1'b1;
			conv2d1_kernel_weights_addr = count;
			for (int i = 0; i < F_OUT_D1; i++) begin
				for (int j = 0; j < F_IN_D1; j++) begin
					conv2d1_kernel_weights_data [i][j] = k1_w[i][j][count];
				end 
			end 
			$display("load w rams: %d", count);
			count += 1;	
		end
		//================ conv2d layer 2 ==========================
		count = 0;
		for (int i = 0; i < F_OUT_D2; i++) begin
			conv2d2_kernel_biases_data[i] = k2_b[i];
		end 

		while(count < KERNEL_SIZE*KERNEL_SIZE) begin
			@(posedge clk);
			conv2d2_kernel_weights_valid = 1'b1;
			conv2d2_kernel_weights_addr = count;
			for (int i = 0; i < F_OUT_D2; i++) begin
				for (int j = 0; j < F_IN_D2; j++) begin
					conv2d2_kernel_weights_data [i][j] = k2_w[i][j][count];
				end 
			end 
			$display("load w rams: %d", count);
			count += 1;	
		end		
				
		//================ dense layer 1 ==========================		
		count = 0;
		for (int i = 0; i < NUM_NEURONS; i++) begin
			dense1_biases_data[i] = kd1_b[i];
		end 

		while(count < F_OUT_D2*F_OUT_H2*F_OUT_W2) begin

			@(posedge clk);
			dense1_weights_valid = 1'b1;
			dense1_weights_addr = count;
			for (int i = 0; i < NUM_NEURONS; i++) begin				
				dense1_weights_data [i] = kd1_w[i][count];				
			end 
			$display("load w rams: %d", count);
			count += 1;	
		end
		//================ dense layer 2 ==========================		
		count = 0;
		for (int i = 0; i < NUM_CLASSES; i++) begin
			dense2_biases_data[i] = kd2_b[i];
		end 

		while(count < NUM_NEURONS) begin

			@(posedge clk);
			dense2_weights_valid = 1'b1;
			dense2_weights_addr = count;
			for (int i = 0; i < NUM_NEURONS; i++) begin				
				dense2_weights_data [i] = kd2_w[i][count];				
			end 
			$display("load w rams: %d", count);
			count += 1;	
		end
		$display("Kernel RAMs are initialized.",);
		-> event_load_w_b_rams;

	end

	initial begin: application_block
		cnn_input_valid = 1'b0;
		@(event_load_w_b_rams);
		#2000;
		count = 0;
		k_ch = 0;
		while (count < F_IN_H1*F_IN_W1) begin
			@(posedge clk);
			cnn_input_valid = 1'b1;
			cnn_input_addr = count;
			cnn_input_data [k_ch] = feature_in[k_ch][count];
			@(posedge clk);
			cnn_input_valid = 1'b0;
			count += 1;
			@(posedge clk);
		end
		@(posedge clk);
		cnn_input_valid = 1'b0;
		$display("Feature in is ready to be processed.",);
	end


    initial begin: acquire_block 
    n_checks_l2 = 0;  
    n_checks_l1 = 0; 	
        wait (rst_n);

        while (1) begin
            @(posedge clk);		

            if (act_resp_conv2d_L1.valid) begin
            	mnt_resp_conv2d_L1_queue.push_back(act_resp_conv2d_L1);
            	n_checks_l1 = n_checks_l1 + 1;
            end  
            if (act_resp_conv2d_L2.valid) begin
            	mnt_resp_conv2d_L2_queue.push_back(act_resp_conv2d_L2);
            	n_checks_l2 = n_checks_l2 + 1;
            end   			
        	
        end 
    end

    int fd1, fd2;
    initial begin
    	conv2d_L1_t mnt_resp_l1;
    	conv2d_L2_t mnt_resp_l2;
    	wait(rst_n);
    	while(n_checks_l1 < F_OUT_W1*F_OUT_H1) begin
    		@(posedge clk);
    		$display("ACQUIRING CONV2D L1 RESPONSE! %d", n_checks_l1);
    	end 
		fd1 = $fopen("../result/conv2d_L1_fm","w");
		for (int i=0; i<n_checks_l1; i++) begin
			mnt_resp_l1 = mnt_resp_conv2d_L1_queue.pop_front();
	    	$fdisplay(fd1, "%d %d %d %d %d", i, mnt_resp_l1.data[0], mnt_resp_l1.data[1], mnt_resp_l1.data[2], mnt_resp_l1.data[3]);
	    	$display("%d   %h %h %h %h", i, mnt_resp_l1.data[0], mnt_resp_l1.data[1], mnt_resp_l1.data[2], mnt_resp_l1.data[3]);
	    end  
		$fclose();

		while(n_checks_l2 < F_OUT_W2*F_OUT_H2) begin
    		@(posedge clk);
    		$display("ACQUIRING CONV2D L2 RESPONSE! %d", n_checks_l2);
    	end 
		fd2 = $fopen("../result/conv2d_L2_fm","w");
		for (int i=0; i<n_checks_l2; i++) begin
			mnt_resp_l2 = mnt_resp_conv2d_L2_queue.pop_front();
	    	$fdisplay(fd2, "%d %d %d %d %d %d %d %d ", i, mnt_resp_l2.data[0],  mnt_resp_l2.data[1],  mnt_resp_l2.data[2],  mnt_resp_l2.data[3], mnt_resp_l2.data[4],  mnt_resp_l2.data[5],  mnt_resp_l2.data[6],  mnt_resp_l2.data[7]);
	    	$display("%d   %h %h %h %h %h %h %h ", i, mnt_resp_l2.data[0], mnt_resp_l2.data[1], mnt_resp_l2.data[2], mnt_resp_l2.data[3], mnt_resp_l2.data[4], mnt_resp_l2.data[5], mnt_resp_l2.data[6], mnt_resp_l2.data[7]);
	    end  
		$fclose(); 

		#100;
//		$stop();   	
    	
    end



endmodule