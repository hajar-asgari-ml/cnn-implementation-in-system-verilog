module FlattenDense_tb();
	timeunit 1ns;
	timeprecision 1ps;

	localparam time CLK_PERIOD = 50ns;
	localparam unsigned RST_CLK_CYCLES = 10;

	localparam F_IN_W 							= 5;
	localparam F_IN_H 							= 1;
	localparam F_IN_D 							= 8;
	localparam NUM_NEURONS 						= 40;
	
	localparam DENSE_WEIGHTS_RESOLUTION 		= 8;
	localparam DENSE_WEIGHTS_ADDRWIDE 			= 12;

	localparam DENSE_BIAS_RESOLUTION 			= 32;
	localparam DENSE_BIAS_ADDRWIDE 				= 12;

	localparam FEATURE_IN_RESOLUTION 			= 32;
  	localparam FEATURE_IN_ADDRWIDE 				= 12;

  	localparam DENSE_OUT_RESOLUTION 			= 32;
  	localparam DENSE_OUT_ADDRWIDE 				= 12;

	localparam k = 40; // maximum( all the reading values from line per line)


	// input interfaces
	logic 										clk, rst_n;

	logic 										feature_in_valid; 								
	logic [FEATURE_IN_RESOLUTION-1 :0]			feature_in_data [0 : F_IN_D-1];			
	logic [FEATURE_IN_ADDRWIDE-1:0]				feature_in_addr; 					
	logic										feature_in_ready; 	

	logic 										dense_weights_valid;
	logic [DENSE_WEIGHTS_RESOLUTION-1 : 0]		dense_weights_data [0: NUM_NEURONS-1]; 		
	logic [DENSE_WEIGHTS_ADDRWIDE-1:0]			dense_weights_addr; 	

	logic 										dense_biases_valid; 
	logic [DENSE_BIAS_RESOLUTION-1:0] 			dense_biases_data[0:NUM_NEURONS-1];	
	logic [DENSE_BIAS_ADDRWIDE-1:0]				dense_biases_addr;	

	logic 										flattendense_valid;
	logic [DENSE_OUT_RESOLUTION-1:0] 			flattendense_data;	
	logic [DENSE_OUT_ADDRWIDE-1 : 0] 			flattendense_addr;
	logic 										flattendense_ready;

	logic [DENSE_BIAS_RESOLUTION-1 : 0] 		dense_dwscaling_m0;
	logic [3:0]									dense_dwscaling_n;	

	// output interfaces





	int dense_1_w;
	int dense_1_b;
	int feature_in_file;

	int k_ch;
	int k_row;

	bit [15:0] 									w [0:k-1];
	bit [7:0] 									k_w [0:NUM_NEURONS-1][0:F_IN_D*F_IN_H*F_IN_W-1];
	bit [15:0]									k_b [0:NUM_NEURONS-1];

	bit [FEATURE_IN_RESOLUTION-1:0] 			fin[0:F_IN_W-1];
	bit [FEATURE_IN_RESOLUTION-1:0] 			feature_in[0:F_IN_D-1][0:F_IN_W*F_IN_H-1];




	clk_rst_gen #(
		.CLK_PERIOD 							(CLK_PERIOD),
		.RST_CLK_CYCLES 						(RST_CLK_CYCLES)
	)	i_clk_rst_gen (

		.clk_o 									(clk),
		.rst_no 								(rst_n)
	);


	FlattenDense #(
		.F_IN_W 							(F_IN_W),
		.F_IN_H 							(F_IN_H),
		.F_IN_D 							(F_IN_D))

	dense_layer1	(
		.clk_i 								(clk),
		.rst_ni 							(rst_n),

		.feature_in_valid_i 				(feature_in_valid),
		.feature_in_data_i 					(feature_in_data),
		.feature_in_addr_i 					(feature_in_addr),
		.feature_in_ready_o 				(feature_in_ready), 

		.dense_weights_valid_i				(dense_weights_valid), 
		.dense_weights_data_i 				(dense_weights_data), 
		.dense_weights_addr_i 				(dense_weights_addr), 

		.dense_biases_valid_i 				(dense_biases_valid), 
		.dense_biases_data_i  				(dense_biases_data), 
		.dense_biases_addr_i  				(dense_biases_addr), 

		.dense_dwscaling_m0_i				(dense_dwscaling_m0), 
		.dense_dwscaling_n_i				(dense_dwscaling_n), 

		.flattendense_valid_o 				(flattendense_valid), 
		.flattendense_data_o  				(flattendense_data), 
		// .flattendense_addr_o  				(flattendense_addr), 
		.flattendense_ready_i 				(flattendense_ready));




	initial begin
		#100;
		//=============== import conv_2D layer 1 weights ==============================================
		dense_1_w = $fopen("../test/quantized_weights_biases/dense_1_weights.txt","r");
		k_ch = 0;
		while(!$feof(dense_1_w)) begin
			//------ dense layer 1
			$fscanf(dense_1_w, "%d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d", w[0] , w[1], w[2],  w[3], w[4], w[5], w[6], w[7], w[8], w[9], w[10], w[11], w[12] , w[13], w[14],  w[15], w[16], w[17], w[18], w[19], w[20], w[21], w[22], w[23], w[24] , w[25], w[26],  w[27], w[28], w[29], w[30], w[31], w[32], w[33], w[34], w[35], w[36], w[37], w[38], w[39]);
			$display("Line W : " ,w[0] , w[1], w[2],  w[3], w[4], w[5], w[6], w[7], w[8]);
			for (int i=0; i < F_IN_W*F_IN_H; i++) begin
					k_w [k_ch][i] = w[i];				
			end 
			k_ch += 1;
		end	
		$fclose(dense_1_w);
		$display("Test w1 : %b ", k_w[1][39]);	
			


		// //=============== import conv_2D layer 1 biases ================================================
		dense_1_b = $fopen("../test/quantized_weights_biases/dense_1_biases.txt","r");
		k_ch = 0;
		while(!$feof(dense_1_b)) begin
			$fscanf(dense_1_b, "%d ", w[0]);
			$display("Line b: %b    ", w[0]);

			k_b[k_ch] = w[0];
			k_ch += 1;
		end 
		$fclose(dense_1_b);
		$display("ALL weights and biases are succesfully read from files.");

		dense_dwscaling_m0 = 16'b1010_0010_1100_0000;	 
		dense_dwscaling_n = 7;
		#20 -> event_read_file_w_b;

	end


	event event_read_file_w_b;
	event event_load_w_b_rams;
	int count;
	initial begin
		@(event_read_file_w_b);
		count = 0;
		dense_weights_valid = 1'b0;
		$display("[%t] Start sending weights to RAMs", $time);
		# 1000;
		for (int i = 0; i < NUM_NEURONS; i++) begin
			dense_biases_data[i] = k_b[i];
		end 

		while(count < NUM_NEURONS) begin

			@(posedge clk);
			dense_weights_valid = 1'b1;
			dense_weights_addr = count;
			for (int i = 0; i < NUM_NEURONS; i++) begin				
				dense_weights_data [i] = k_w[count][i];				
			end 
			$display("load w rams: %d", count);
			count += 1;	
		end
		-> event_load_w_b_rams;

	end

endmodule