module MAC_v4_tb();

	timeunit 1ns;
	timeprecision 1ps;

	localparam time CLK_PERIOD			= 100ns;
	localparam unsigned RST_CLK_CYCLES  = 10;
	localparam unsigned MAC_INPUT_BIT_RESOLUTION = 8;
	localparam unsigned MAC_OUTPUT_BIT_RESOLUTION = 32;
	localparam unsigned KERNEL_SIZE = 3;
	localparam unsigned ACQ_DELAY = 30ns;
	localparam unsigned APPL_DELAY = 10ns;
	localparam unsigned TOT_STIMS = 1000;

	integer n_stims,
			n_checks,
			n_errs,
			n_timeout,
			n_data;

	typedef struct packed {
		logic signed [MAC_INPUT_BIT_RESOLUTION-1:0] i,w;
		logic signed [MAC_OUTPUT_BIT_RESOLUTION-1:0] b;
	} mac_t;

	mac_t 	stim;

	// input interface
	logic clk, rst_n;
	logic mac_i_w_valid, mac_i_w_valid_d;

	// output interface
	logic mac_valid_o;
	logic [MAC_OUTPUT_BIT_RESOLUTION-1:0] 	act_resp, acq_resp_queue[$], exp_resp_queue[$];
	logic mac_ready_i;

	
	clk_rst_gen #(
		.CLK_PERIOD 				(CLK_PERIOD),
		.RST_CLK_CYCLES 			(RST_CLK_CYCLES)
	)	i_clk_rst_gen (

		.clk_o 						(clk),
		.rst_no 					(rst_n)
	);

	MAC_v5  #(
		.INPUT_BIT_RESOLUTION 			(MAC_INPUT_BIT_RESOLUTION),
		.OUTPUT_BIT_RESOLUTION  		(MAC_OUTPUT_BIT_RESOLUTION)
	)	dut (
		.clk_i 							(clk),
		.rst_ni 						(rst_n),
		.mac_fin_and_kernel_valid_i		(mac_i_w_valid),
		.mac_fin_data_i 				(stim.i),
		.mac_kernel_data_i				(stim.w),
		.mac_kernel_bias_i 				(stim.b),
		.mac_valid_o 					(mac_valid_o),
		.mac_data_o 					(act_resp),
		.mac_ready_i					(mac_ready_i)
	);


initial begin: randomizing_MAC_input
	mac_i_w_valid = 0;
	stim.i = 0;
	stim.w = 0;
	stim.b = 0;
	mac_ready_i = 1;
	n_stims = 0;
	n_data = 0;
	wait(rst_n);
	stim.b = $urandom_range(-4096,4096);
	mac_i_w_valid = 1;
	while(n_stims < TOT_STIMS) begin	
		@(posedge clk);	
		mac_i_w_valid_d = mac_i_w_valid;
		if (mac_valid_o) begin
			// @(posedge clk);
			mac_i_w_valid = 1;
			stim.b = $urandom_range(-4096,4096);
			n_data = 0;
			n_stims = n_stims + 1;
		end else begin 
			if (n_data < KERNEL_SIZE*KERNEL_SIZE) begin
				stim.i = $urandom_range(-128,127);
				stim.w = $urandom_range(-128,127);
				n_data = n_data + 1;
			end else begin
				mac_i_w_valid = 0;

			end
		end  
	end
	// $stop();
end 

initial begin: acquire_response
	wait(rst_n);
	while(1) begin
		@(posedge clk);
		if(mac_valid_o) begin 
			acq_resp_queue.push_back(act_resp);
			// $display("acquire resp is %d at time: ", $signed(act_resp), $time() );
		end 
	end 	
end	

initial begin: Golden_model
	logic [MAC_OUTPUT_BIT_RESOLUTION-1:0] gold_val;
	logic gold_val_valid;
	while(1) begin
		@(posedge clk);
		if (mac_i_w_valid_d) begin
			mac_task(n_stims, stim, gold_val, gold_val_valid);
		end 
		if (gold_val_valid) begin 
			exp_resp_queue.push_back(gold_val);
			mac_task(n_stims, stim, gold_val, gold_val_valid);			
			// $display("expected resp is %d at time: ", $signed(gold_val), $time() );
		end 
	end 	
end


initial begin: checker_block
	logic [MAC_OUTPUT_BIT_RESOLUTION-1:0] acq_resp, exp_resp;
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
			// $display("at %t acquired %d, expected  %d", $time(), $signed(acq_resp), $signed(exp_resp));
			if(acq_resp !== exp_resp) begin
				n_errs = n_errs +1;
				$display("Mistmatch occured at %d: acquired %2d, expected  %2d", $time(), acq_resp, exp_resp);
			end
		end
	end
	$display("n errors", n_errs);
	if(n_errs > 0) begin
		$display("Test ***FAILED*** with ", n_errs, " mismatches out of ", n_checks, " checks after ",n_stims, " stimuli!");
	end else begin
		$display("Test ***PASSED*** with ", n_errs, " mismatches out of ", n_checks, " checks after ",n_stims, " stimuli.");
	end
	$stop();
end 

task mac_task (
	input integer n_stims,
	input mac_t mac_i,
	output signed [MAC_OUTPUT_BIT_RESOLUTION-1 : 0] mac_o,
	output mac_o_valid
	);
	const integer KERNEL_SIZE = KERNEL_SIZE;
	integer n_data = 0;
	logic signed [MAC_OUTPUT_BIT_RESOLUTION-1:0] bias_val = 0;
	logic signed [MAC_OUTPUT_BIT_RESOLUTION-1:0] mac_tmp = 0;	
	begin
		if (mac_o_valid) 
			mac_o_valid = 0;
		else 
			if (n_data<KERNEL_SIZE*KERNEL_SIZE) begin
				mac_tmp =  mac_tmp +  mac_i.i*mac_i.w;
				// $display("input: %d === weight: %d === bias: %d ", $signed(mac_i.i), $signed(mac_i.w), $signed(mac_i.b));
				// $display("n_data inside task %d", n_data);
				// $display("mac_tmp : %d", $signed(mac_tmp));
		
				n_data = n_data + 1;
				mac_o_valid = 0;
				bias_val = mac_i.b;
			end else begin
				mac_o = mac_tmp + bias_val;
				mac_o_valid = 1;
				mac_tmp = 0;
				n_data = 0;
				// $display("Golden result of MAC %d in n_stim %d at time %t with biase %d", $signed(mac_o), n_stims-1, $time, $signed(bias_val));
			end
		// $display("Golden result of MAC %d in n_stim %d", $signed(mac_o), n_stims);

	end
endtask

endmodule // MAC_tb
