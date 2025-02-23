
import pkg_parameters::*;
module CNN_v2_tb();
	timeunit 1ns;
	timeprecision 1ps;

	localparam time CLK_PERIOD = 50ns;
	localparam unsigned RST_CLK_CYCLES = 10;
	
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

	//----------------------------------------------------------------------------
	// output interfaces
	//----------------------------------------------------------------------------
	logic                                   cnn_prediction_valid;
    logic [FEATURE_MAP_RESOLUTION-1 : 0]    cnn_prediction_data[0: NUM_CLASSES-1];
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

	CNN_v2 #( 
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
		.cnn_input_data_i              (cnn_input_data[0]), 
		.cnn_input_addr_i              (cnn_input_addr), 
		.cnn_input_ready_o             (cnn_input_ready), 

		.conv2d1_vis_feature_map_valid_o (act_resp_conv2d_L1.valid), 
		.conv2d1_vis_feature_map_data_o (act_resp_conv2d_L1.data), 
		.conv2d1_vis_feature_map_addr_o (act_resp_conv2d_L1.addr), 

		.conv2d2_vis_feature_map_valid_o (act_resp_conv2d_L2.valid), 
		.conv2d2_vis_feature_map_data_o (act_resp_conv2d_L2.data), 
		.conv2d2_vis_feature_map_addr_o (act_resp_conv2d_L2.addr),

		.cnn_prediction_valid_o        (cnn_prediction_valid), 
		// .cnn_prediction_data_o         (cnn_prediction_data), 
		.cnn_prediction_ready_i        (cnn_prediction_ready)
		);
	
	//----------------------------------------------------------------------------
	// Read kernels and feature in form files
	//----------------------------------------------------------------------------

	int k_ch;
	int k_row;
	int feature_in_file;

	bit [KERNEL_BIAS_RESOLUTION-1:0] 						w [0:k-1];


	bit [FEATURE_MAP_RESOLUTION-1:0] 						fin[0:F_IN_W1-1];
	bit [FEATURE_MAP_RESOLUTION-1:0] 						feature_in[0:F_IN_D1-1][0:F_IN_W1*F_IN_H1-1];
	event 													event_read_file_fin;
	event 													event_load_w_b_rams;
	int 													count;
	
	initial begin
		//=============== import input feature (feature_in) =============================================
		feature_in_file = $fopen("/home/hasgari/ownCloud2/Institution/INI/AVATronic/ini_avatronic_anc_project/hdl_design/test/feature_ins/quantized_feature_in0.txt","r");
		// feature_in_file = $fopen("/home/hasgari/ownCloud2/Institution/INI/AVATronic/ini_avatronic_anc_project/hdl_design/result/Cochlea_v1_proc_mqcRec_AVA_data_B_L_python.txt","r");
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
		#20 -> event_read_file_fin;
		$display("Feature in is ready to be processed.",);	
	end

	initial begin: application_block
		cnn_input_valid = 1'b0;
		@(event_read_file_fin);
		$display("Feature in is ready to be processed.",);			
		# 500000;
		$display("Feature in is ready to be processed.",);		
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
            	$display("n_checks_l1 : %d", n_checks_l1);
            end  
            if (act_resp_conv2d_L2.valid) begin
            	mnt_resp_conv2d_L2_queue.push_back(act_resp_conv2d_L2);
            	n_checks_l2 = n_checks_l2 + 1;
            	$display("n_checks_l2 : %d", n_checks_l2);
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
		fd1 = $fopen("/home/hasgari/ownCloud2/Institution/INI/AVATronic/ini_avatronic_anc_project/hdl_design/result/conv2d_L1_fm","w");
		for (int i=0; i<n_checks_l1; i++) begin
			mnt_resp_l1 = mnt_resp_conv2d_L1_queue.pop_front();
	    	$fdisplay(fd1, "%d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d", i, mnt_resp_l1.data[0], mnt_resp_l1.data[1], mnt_resp_l1.data[2], mnt_resp_l1.data[3],
	    										mnt_resp_l1.data[4], mnt_resp_l1.data[5], mnt_resp_l1.data[6], mnt_resp_l1.data[7],
	    										mnt_resp_l1.data[8], mnt_resp_l1.data[9], mnt_resp_l1.data[10], mnt_resp_l1.data[11],
	    										mnt_resp_l1.data[12], mnt_resp_l1.data[13], mnt_resp_l1.data[14]);
	    	$display("%d   %h %h %h %h", i, mnt_resp_l1.data[0], mnt_resp_l1.data[1], mnt_resp_l1.data[2], mnt_resp_l1.data[3]);
	    end  
		$fclose();
		while(n_checks_l2 < F_OUT_W2*F_OUT_H2) begin
    		@(posedge clk);
    		// $display("ACQUIRING CONV2D L2 RESPONSE! %d", n_checks_l2);
    	end 
		fd2 = $fopen("/home/hasgari/ownCloud2/Institution/INI/AVATronic/ini_avatronic_anc_project/hdl_design/result/conv2d_L2_fm","w");
		for (int i=0; i<n_checks_l2; i++) begin
			mnt_resp_l2 = mnt_resp_conv2d_L2_queue.pop_front();
	    	$fdisplay(fd2, " %d %d %d %d %d %d %d %d %d %d  %d %d %d %d %d %d %d %d %d %d %d ", i, mnt_resp_l2.data[0],  mnt_resp_l2.data[1],  mnt_resp_l2.data[2],  mnt_resp_l2.data[3], mnt_resp_l2.data[4],  mnt_resp_l2.data[5],  
	    																						mnt_resp_l2.data[6],  mnt_resp_l2.data[7] , mnt_resp_l2.data[8],  mnt_resp_l2.data[9],  mnt_resp_l2.data[10],  mnt_resp_l2.data[11], mnt_resp_l2.data[12],  mnt_resp_l2.data[13],
	    																						mnt_resp_l2.data[14],  mnt_resp_l2.data[15],  mnt_resp_l2.data[16],  mnt_resp_l2.data[17], mnt_resp_l2.data[18],  mnt_resp_l2.data[19]);
	    	$display("%d   %h %h %h %h %h %h %h ", i, mnt_resp_l2.data[0], mnt_resp_l2.data[1], mnt_resp_l2.data[2], mnt_resp_l2.data[3], mnt_resp_l2.data[4], mnt_resp_l2.data[5], mnt_resp_l2.data[6], mnt_resp_l2.data[7]);
	    end  
		$fclose(); 
		#100;    	
    end

endmodule