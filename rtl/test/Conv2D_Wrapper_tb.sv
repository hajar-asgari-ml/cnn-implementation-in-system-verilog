module Conv2D_Wrapper_tb();
	timeunit 1ns;
	timeprecision 1ps;

	localparam time CLK_PERIOD = 50ns;
	localparam unsigned RST_CLK_CYCLES = 10;
	localparam k = 40; // maximum( all the reading values from line per line)
	localparam KERNEL_SIZE 						= 3;

	localparam F_IN_W1 							= 29;
	localparam F_IN_H1 							= 13;
	localparam F_IN_D1 							= 1;
	localparam F_OUT_W1 							= 13;
	localparam F_OUT_H1 							= 5;
	localparam F_OUT_D1 							= 2;
	localparam KERNEL_WEIGHTS_RESOLUTION 		= 8;
	localparam KERNEL_WEIGHTS_ADDRWIDE 			= 12;
	localparam KERNEL_BIAS_RESOLUTION 			= 32;
	localparam KERNEL_BIAS_ADDRWIDE 			= 12;
	localparam FEATURE_IN_RESOLUTION 			= 32;
  	localparam FEATURE_IN_ADDRWIDE 				= 12;
	localparam FEATURE_OUT_RESOLUTION 			= 32;
  	localparam FEATURE_OUT_ADDRWIDE 			= 12;
  	localparam TOT_STIMS = F_OUT_W1*F_OUT_H1;
  	integer n_stims,
			n_checks,
			n_errs,
			n_timeout;

	typedef struct {
		logic signed [KERNEL_WEIGHTS_RESOLUTION-1:0] data [0: F_OUT_D1-1];
		logic [FEATURE_OUT_ADDRWIDE-1:0] addr;
	} conv2d_t;

	// typedef struct packed {
	// 	logic signed [MAC_INPUT_BIT_RESOLUTION-1:0] i,w;
	// 	logic signed [MAC_OUTPUT_BIT_RESOLUTION-1:0] b;
	// } mac_t;

	conv2d_t act_resp, acq_resp_queue[$], exp_resp_queue[$], mnt_resp, mnt_resp_queue[$];

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
	logic [KERNEL_BIAS_RESOLUTION-1 : 0] 	kernel_dwscaling_b[0 : F_OUT_D1-1];
	logic [FEATURE_MAP_RESOLUTION:0]		kernel_dwscaling_z3;

	// output interfaces
	logic 									feature_out_valid1 [0: F_OUT_D1-1];
	logic [KERNEL_WEIGHTS_RESOLUTION-1:0] 	feature_out_data1 [0 : F_OUT_D1-1];
	logic [FEATURE_OUT_ADDRWIDE-1:0]		feature_out_addr1;
	logic 									feature_out_ready1;
	

	int conv2D_1_w, conv2D_2_w;
	int conv2D_1_b, conv2D_2_b;
	int conv2d_l1;
	int feature_in_file;
	int k_ch;
	int k_row;
	bit [KERNEL_BIAS_RESOLUTION-1:0] 						w [0:k-1];
	bit signed [KERNEL_WEIGHTS_RESOLUTION-1:0] 					k1_w [0:F_OUT_D1-1][0:F_IN_D1-1][0:KERNEL_SIZE*KERNEL_SIZE-1];
	bit signed [KERNEL_BIAS_RESOLUTION-1:0]						k1_b [0:F_OUT_D1-1];
	bit [FEATURE_IN_RESOLUTION-1:0] 						fin [0:F_IN_W1-1];
	bit signed [FEATURE_IN_RESOLUTION-1:0]							stim [0:F_IN_D1-1][0:F_IN_H1-1][0:F_IN_W1-1];
	bit [FEATURE_IN_RESOLUTION-1:0] 						feature_in [0:F_IN_D1-1][0:F_IN_W1*F_IN_H1-1];

	clk_rst_gen #(
		.CLK_PERIOD 				(CLK_PERIOD),
		.RST_CLK_CYCLES 			(RST_CLK_CYCLES)
	)	i_clk_rst_gen (

		.clk_o 						(clk),
		.rst_no 					(rst_n)
	);


	Conv2D_Wrapper #(
		.F_IN_W 							(F_IN_W1),
		.F_IN_H 							(F_IN_H1),
		.F_IN_D 							(F_IN_D1),
		.KERNEL_SIZE 						(KERNEL_SIZE),
		.F_OUT_W 							(F_OUT_W1),
		.F_OUT_H 							(F_OUT_H1),
		.F_OUT_D 							(F_OUT_D1), 
		.INITFILENAMEWEIGHT    				("../test/mem/cnn_param_mem/conv2d_1_weights.txt"), 
		.INITFILENAMEBIAS      				("../test/mem/cnn_param_mem/conv2d_1_biases.txt"), 
		.INITFILENAMEM0    					("../test/mem/cnn_param_mem/conv2d_1_m0.txt"), 
		.INITFILENAMEN     					("../test/mem/cnn_param_mem/conv2d_1_n.txt"), 
		.INITFILENAMEB     					("../test/mem/cnn_param_mem/conv2d_1_b.txt"), 
		.INITFILENAMEZ3    					("../test/mem/cnn_param_mem/conv2d_1_z3.txt"))

	conv2D_layer1	(
		.clk_i 								(clk),
		.rst_ni 							(rst_n),

		.feature_in_valid_i 				(feature_in_valid),
		.feature_in_data_i 					(feature_in_data),
		.feature_in_addr_i 					(feature_in_addr),
		.feature_in_ready_o 				(feature_in_ready),

		.feature_out_valid_o 				(feature_out_valid1),
		.feature_out_data_o 				(act_resp.data),
		.feature_out_addr_o 				(act_resp.addr),
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
				stim[k_ch][k_row][i] = fin[i];
			end 
			$display("feature in row", k_row);
			k_row += 1;
		end 
		//=============== assign down scaling factors (m0 & n) ===========================================

		// kernel_dwscaling_n [0] = 7;
		// kernel_dwscaling_n [1] = 8;
		// kernel_dwscaling_n [2] = 7;
		// kernel_dwscaling_n [3] = 7;
		// kernel_dwscaling_m0[0] = 32'b10001000010010011100100010001101;
		// kernel_dwscaling_m0[1] = 32'b11110010001111111001001000110111;
		// kernel_dwscaling_m0[2] = 32'b10011100010001011011110110111001;
		// kernel_dwscaling_m0[3] = 32'b11010110001011011111101011010001;	

		conv2d_l1 = $fopen("../test/cnn_m0_n_b/conv2d_l1_n.txt","r");
		k_row = 0;
		while(!$feof(conv2d_l1)) begin
			$fscanf(conv2d_l1, "%d ", w[0]);			
			kernel_dwscaling_n [k_row] 	= w[0];
			k_row += 1;
		end  

		conv2d_l1 = $fopen("../test/cnn_m0_n_b/conv2d_l1_b.txt","r");
		k_row = 0;
		while(!$feof(conv2d_l1)) begin
			$fscanf(conv2d_l1, "%d ", w[0]);			
			kernel_dwscaling_b [k_row] 	= w[0];
			k_row += 1;
		end 	
		
		conv2d_l1 = $fopen("../test/cnn_m0_n_b/conv2d_l1_m0.txt","r");
		k_row = 0;
		while(!$feof(conv2d_l1)) begin
			$fscanf(conv2d_l1, "%d ", w[0]);			
			kernel_dwscaling_m0 [k_row] 	= w[0];
			k_row += 1;
		end 	
		
		conv2d_l1 = $fopen("../test/cnn_m0_n_b/conv2d_l1_z3.txt","r");
		k_row = 0;
		while(!$feof(conv2d_l1)) begin
			$fscanf(conv2d_l1, "%d ", w[0]);			
			kernel_dwscaling_z3	= w[0];
			k_row += 1;
		end 	

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


    
    initial begin: acquire_block    	
        wait (rst_n);

        while (1) begin
            @(posedge clk);
			

            if (feature_out_valid1[0] ) begin
                	acq_resp_queue.push_back(act_resp);
                	mnt_resp_queue.push_back(act_resp);
                	// $display("%t : Feature out addr is %d acquire resp is %h. ", $time(), act_resp.addr, act_resp.data);
            end    			
        	
        end 
    end

    integer row,col,row0,col0 = 0;
    conv2d_t gold_val;
    // logic signed [KERNEL_WEIGHTS_RESOLUTION-1:0] gold_val [0:F_OUT_D1-1];
	initial begin: Golden_model
		// logic [FEATURE_MAP_RESOLUTION-1:0] gold_val [0:F_OUT_D1-1];
		logic gold_val_valid;
		logic signed [KERNEL_BIAS_RESOLUTION-1:0] tmp [0:F_OUT_D1-1] ;
		logic signed [2*KERNEL_BIAS_RESOLUTION-1:0] dw64 [0:F_OUT_D1-1] ;
		logic signed [KERNEL_BIAS_RESOLUTION-1:0] dw32 [0:F_OUT_D1-1] ;
		logic signed [KERNEL_WEIGHTS_RESOLUTION-1:0] max_tmp [0:F_OUT_D1-1] ;
		tmp[0]=0;
		tmp[1]=0;
		tmp[2]=0;
		tmp[3]=0;
		max_tmp[0]=0;
		max_tmp[1]=0;
		max_tmp[2]=0;
		max_tmp[3]=0;
		dw64[0]=0;
		dw64[1]=0;
		dw64[2]=0;
		dw64[3]=0;
		while(1) begin
			@(posedge clk);
			if (feature_out_valid1[0]) begin
				row = 2*(act_resp.addr/F_OUT_W1);
				col = 2*(act_resp.addr%F_OUT_W1);
				for (int r = 0; r < 2; r++) begin
					for (int c =0; c < 2; c++) begin

						for (int k = 0; k < F_OUT_D1; k++) begin 	
							for (int i = 0; i < KERNEL_SIZE; i++) begin
								for (int j = 0; j < KERNEL_SIZE; j++) begin
									tmp[k] = tmp[k] + stim[0][i+row+r][j+col+c]*k1_w[k][0][j+KERNEL_SIZE*i];
									if (act_resp.addr == 7) begin 
										// $display("stim   of channel k %d is %h", k, stim[0][i+row+r][j+col+c]);
										// $display("stim address: row %d, r %d, col/2 %d, c %d, i %d, j %d", row, r, col, c, i , j);
									end 
								end
							end
							tmp[k] = tmp[k] + k1_b[k];
						end 
						// $display("r %d and c %d : ", r, c);
						// $display(" mac output: %d, %d, %d , %d", tmp[0],tmp[1],tmp[2],tmp[3]);
						for (int i =0; i < F_OUT_D1; i++) begin
							if(tmp[i][KERNEL_BIAS_RESOLUTION-1])
								tmp[i] = 0;
							else begin
								dw64[i] = tmp[i]*(kernel_dwscaling_m0[i] >> 1);
								dw32[i] = dw64[i][2*KERNEL_BIAS_RESOLUTION-1:KERNEL_BIAS_RESOLUTION] >> kernel_dwscaling_n[i];
								if(dw32[i][7:0] > max_tmp[i])
									max_tmp[i]=dw32[i][7:0]	;
								
							end
						end
						// $display("dw  output:  %h, %h, %h , %h", dw32[0],dw32[1],dw32[2],dw32[3]);
						tmp[0]=0;
						tmp[1]=0;
						tmp[2]=0;
						tmp[3]=0;
						dw64[0]=0;
						dw64[1]=0;
						dw64[2]=0;
						dw64[3]=0;	

					end
				end
				// $display("maxpooling out %h, %h, %h , %h", max_tmp[0], max_tmp[1], max_tmp[2], max_tmp[3]);

				gold_val.data = max_tmp;
				gold_val.addr = act_resp.addr;
			// if (gold_val_valid) begin 
				exp_resp_queue.push_back(gold_val);
			// 	conv2d_task(n_stims, stim, gold_val, gold_val_valid);			
			// 	// $display("expected resp is %d at time: ", $signed(gold_val), $time() );
			end else begin 
				tmp[0]=0;
				tmp[1]=0;
				tmp[2]=0;
				tmp[3]=0;
				max_tmp[0]=0;
				max_tmp[1]=0;
				max_tmp[2]=0;
				max_tmp[3]=0;				
			end 
		end 	
	end

int fd;
initial begin: checker_block
	conv2d_t acq_resp, exp_resp;
	n_checks = 0;
	n_errs = 0;
	n_timeout = 0;
	wait(rst_n);
	while(n_checks < TOT_STIMS) begin
		@(posedge clk);
		if(acq_resp_queue.size() > 0 && exp_resp_queue.size() > 0) begin
			n_checks += 1;
			acq_resp = acq_resp_queue.pop_front();
			exp_resp = exp_resp_queue.pop_front();
			$display("at %t acquired %h, expected  %h", $time(), $signed(acq_resp.data), $signed(exp_resp.data));
			$display("at %t acquired %d, expected  %d", $time(), $signed(acq_resp.addr), $signed(exp_resp.addr));
			if(acq_resp !== exp_resp) begin
				n_errs = n_errs +1;
				$display("Mistmatch occured at %d: acquired %2d, expected  %2d", $time(), acq_resp, exp_resp);
			end
		end
	end
	fd = $fopen("../result/conv2d_L1_fm","w");
	for (int i=0; i<TOT_STIMS; i++) begin
		mnt_resp = mnt_resp_queue.pop_front();
    	$fdisplay(fd, "%d %d %d %d %d", i, mnt_resp.data[0], mnt_resp.data[1], mnt_resp.data[2], mnt_resp.data[3]);
    	$display("%d   %h %h %h %h", i, mnt_resp.data[0], mnt_resp.data[1], mnt_resp.data[2], mnt_resp.data[3]);
    end  
    $fclose();	
	$display("n errors", n_errs);
	if(n_errs > 0) begin
		$display("Test ***FAILED*** with ", n_errs, " mismatches out of ", n_checks, " checks after ",n_stims, " stimuli!");
	end else begin
		$display("Test ***PASSED*** with ", n_errs, " mismatches out of ", n_checks, " checks after ",n_stims, " stimuli.");
	end
	$stop();
end 


	//   fd = $fopen ("trial", "w");
	//   for (int i = 0; i < 5; i++) 
	//     $fdisplay (fd, "Iteration = %0d", i);
	//   $fclose(fd);

endmodule