module Conv2D_tb();
	timeunit 1ns;
	timeprecision 1ps;

	localparam time CLK_PERIOD = 50ns;
	localparam unsigned RST_CLK_CYCLES = 10;
	localparam k = 40; // maximum( all the reading values from line per line)
	localparam KERNEL_SIZE 						= 3;

	localparam F_IN_W1 							= 29;
	localparam F_IN_H1 							= 13;
	localparam F_IN_D1 							= 1;
	localparam F_OUT_W1 							= 14;
	localparam F_OUT_H1 							= 6;
	localparam F_OUT_D1 							= 4;
	localparam KERNEL_WEIGHTS_RESOLUTION 		= 8;
	localparam KERNEL_WEIGHTS_ADDRWIDE 			= 12;
	localparam KERNEL_BIAS_RESOLUTION 			= 32;
	localparam KERNEL_BIAS_ADDRWIDE 			= 12;
	localparam FEATURE_IN_RESOLUTION 			= 32;
  	localparam FEATURE_IN_ADDRWIDE 				= 12;
	localparam FEATURE_OUT_RESOLUTION 			= 32;
  	localparam FEATURE_OUT_ADDRWIDE 			= 12;

	typedef struct packed {
		logic signed [KERNEL_WEIGHTS_RESOLUTION-1:0] data;
		logic [FEATURE_OUT_ADDRWIDE-1:0] addr;
		logic ready;
	} conv2d_t;

	conv2d_t stim;

	// input interfaces
	logic 									clk, rst_n;
	logic 									feature_in_valid; 								
	logic [KERNEL_WEIGHTS_RESOLUTION-1 :0]	feature_in_data [0 : F_IN_D1-1];			
	logic [FEATURE_IN_ADDRWIDE-1:0]			feature_in_addr; 					
	logic									feature_in_ready; 	
	logic 									initialize_kernel_weights_ram1;
	logic [KERNEL_WEIGHTS_RESOLUTION-1 : 0]	kernel_weights_data1 [0 : F_OUT_D1-1][0 : F_IN_D1-1]; 		
	logic [KERNEL_WEIGHTS_ADDRWIDE-1:0]		kernel_weights_addr1; 		
	logic 									initialize_kernel_bias_ram1; 
	logic [KERNEL_BIAS_RESOLUTION-1:0] 		kernel_biases_data1 [0 : F_OUT_D1-1];	
	logic [KERNEL_BIAS_ADDRWIDE-1:0]		kernel_biases_addr1;
	logic [KERNEL_BIAS_RESOLUTION-1 : 0] 	kernel_dwscaling_m0[0 : F_OUT_D1-1];
	logic [3:0]								kernel_dwscaling_n [0: F_OUT_D1-1];

	// output interfaces
	logic 									feature_out_valid1 [0: F_OUT_D1-1];
	logic [KERNEL_WEIGHTS_RESOLUTION-1:0] 	feature_out_data1 [0 : F_OUT_D1-1];
	logic [FEATURE_OUT_ADDRWIDE-1:0]		feature_out_addr1;
	logic 									feature_out_ready1;
	conv2d_t act_resp, acq_resp_queue[$], exp_resp_queue[$];

	int conv2D_1_w, conv2D_2_w;
	int conv2D_1_b, conv2D_2_b;
	int feature_in_file;
	int k_ch;
	int k_row;
	bit [KERNEL_BIAS_RESOLUTION-1:0] 						w [0:k-1];
	bit [KERNEL_WEIGHTS_RESOLUTION-1:0] 					k1_w [0:F_OUT_D1-1][0:F_IN_D1-1][0:KERNEL_SIZE*KERNEL_SIZE-1];
	bit [KERNEL_BIAS_RESOLUTION-1:0]						k1_b [0:F_OUT_D1-1];
	bit [FEATURE_IN_RESOLUTION-1:0] 						fin[0:F_IN_W1-1];
	bit [FEATURE_IN_RESOLUTION-1:0] 						feature_in[0:F_IN_D1-1][0:F_IN_W1*F_IN_H1-1];

	clk_rst_gen #(
		.CLK_PERIOD 				(CLK_PERIOD),
		.RST_CLK_CYCLES 			(RST_CLK_CYCLES)
	)	i_clk_rst_gen (

		.clk_o 						(clk),
		.rst_no 					(rst_n)
	);


	Conv2D #(
		.F_IN_W 							(F_IN_W1),
		.F_IN_H 							(F_IN_H1),
		.F_IN_D 							(F_IN_D1),
		.KERNEL_SIZE 						(KERNEL_SIZE),
		.F_OUT_W 							(F_OUT_W1),
		.F_OUT_H 							(F_OUT_H1),
		.F_OUT_D 							(F_OUT_D1))

	conv2D_layer1	(
		.clk_i 								(clk),
		.rst_ni 							(rst_n),

		.feature_in_valid_i 				(feature_in_valid),
		.feature_in_data_i 					(feature_in_data),
		.feature_in_addr_i 					(feature_in_addr),
		.feature_in_ready_o 				(feature_in_ready),

		.kernel_weights_valid_i			 	(initialize_kernel_weights_ram1),
		.kernel_weights_data_i 				(kernel_weights_data1),
		.kernel_weights_addr_i 				(kernel_weights_addr1),

		// .initialize_kernel_bias_ram_i 		(initialize_kernel_bias_ram),
		.kernel_biases_data_i 				(kernel_biases_data1),
		// .kernel_biases_addr_i 				(kernel_biases_addr), 

		.kernel_dwscaling_m0_i 				(kernel_dwscaling_m0), 
		.kernel_dwscaling_n_i  				(kernel_dwscaling_n),

		.feature_out_valid_o 				(feature_out_valid1),
		.feature_out_data_o 				(feature_out_data1),
		.feature_out_addr_o 				(feature_out_addr1),
		.feature_out_ready_i			 	(feature_out_ready1)

		);


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

		#20 -> event_read_file_w_b;

		//=============== import input feature (feature_in) =============================================
		feature_in_file = $fopen("../test/feature_ins/quantized_feature_in0.txt","r");
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

		kernel_dwscaling_n [0] = 7;
		kernel_dwscaling_n [1] = 7;
		kernel_dwscaling_n [2] = 7;
		kernel_dwscaling_n [3] = 9;

		kernel_dwscaling_m0[0] = 32'b10001001000100110101001110001001;
		kernel_dwscaling_m0[1] = 32'b10000111111001111100001111011110;
		kernel_dwscaling_m0[2] = 32'b10010011100010110000010100110011;
		kernel_dwscaling_m0[3] = 32'b10011101111011010101110011001011;


	end


	event event_read_file_w_b;
	event event_load_w_b_rams;
	int count;
	initial begin
		@(event_read_file_w_b);
		count = 0;
		initialize_kernel_weights_ram1 = 1'b0;
		$display("[%t] Start sending weights to RAMs", $time);
		# 1000;
		for (int i = 0; i < F_OUT_D1; i++) begin
			kernel_biases_data1[i] = k1_b[i];
		end 

		while(count < KERNEL_SIZE*KERNEL_SIZE) begin

			@(posedge clk);
			initialize_kernel_weights_ram1 = 1'b1;
			kernel_weights_addr1 = count;
			for (int i = 0; i < F_OUT_D1; i++) begin
				for (int j = 0; j < F_IN_D1; j++) begin
					kernel_weights_data1 [i][j] = k1_w[i][j][count];
				end 
			end 
			$display("load w rams: %d", count);
			count += 1;	
		end
		-> event_load_w_b_rams;

	end

	initial begin
		feature_in_valid = 1'b0;
		@(event_load_w_b_rams);
		#2000;
		feature_in_valid = 1'b1;
		count = 0;
		k_ch = 0;
		while (count < F_IN_H1*F_IN_W1) begin
			@(posedge clk);
			feature_in_addr = count;
			feature_in_data[k_ch] = feature_in[k_ch][count];
			count += 1;
		end
		@(posedge clk);
		feature_in_valid = 1'b0;
		$display("Kernel RAMs are initialized.",);
	end


    // Acquire response
    // initial begin: acquire_block
    //     oup_ready = 1'b0;
    //     wait (rst_n);
    //     while (1) begin
    //         @(posedge clk);

    //         if (feature_out_valid1 ) begin
    //             acq_resp_queue.push_back(feature_out_addr1, feature_out_data1);
    //         end
    //     end
    // end





endmodule