/*
This mudule does the following tasks:
	1- calculate mean of the input acc: mqcr = acc_i/(SAMPLING_RATExTIME_WINDOW)
	2- scaling the image for the CNN : q_mqcr_o = (mqcr/s1)+z1 = (acc_i/s1xSAMPLING_RATExTIME_WINDOW) + z1
	3- extract a rectangular shape 13x29 out of the whole 35x35 image
	ps. : tasks 1 and 2 are merged in 1 combinatorial step. acc_i is multiplied by (1/s1SAMPLING_RATExTIME_WINDOW) (shift-add mult)
		  and then add by the value of the z_pint (s1). s1 and z2 extracted from cnn tflite model.
	
	// parameter unsigned SAMPLING_RATE 		= 48,
	// parameter signed Z_POINT 				= -1 (8h'FF)
	// parameter unsugned 	SCALE 				=  0.007598039228469133
	// parameter unsigned TIME_WINDOW 			= 10,
*/
(* DONT_TOUCH = "yes" *) // to prevent vivado removing top level ports

import pkg_parameters::*;

module quantized_mqcRec #(

	parameter unsigned REC_IMG_W 				= 29,
	parameter unsigned REC_IMG_H 				= 13
	) (
	input logic 										clk_i, rst_ni,
    input logic 										instant_qcRec_valid_i,
	input logic 	 									instant_qcRec_data_i [REC_IMG_H-1:0][REC_IMG_W-1:0],
	input logic 	[15:0]								count_samples_i,

   	output logic 										mqcRec_valid_o,
    output logic 	    [FEATURE_MAP_RESOLUTION-1:0]	mqcRec_data_o,
    output logic 		[FEATURE_MAP_ADDRWIDE-1:0] 		mqcRec_addr_o,
    input logic 										mqcRec_ready_i  
	);

	localparam TOTAL_PIXELS = REC_IMG_H*REC_IMG_W;
	localparam TOTAL_SAMPLES = SAMPLING_RATE*TIME_WINDOW;
	localparam MEM_ADDRWIDE = 8;
	enum int unsigned {IDLE = 0, WAIT_FOR_VALID = 1, CHECK_INSTANT_REC_ROW = 2, ACC_TASK = 3, CNT_INSTANT_REC_ADDR = 4, CNT_INPUT_SAMPLES = 5, QUANTIZATION_ADDR_CHECK = 6, QUANTIZATION_ADDR_INC = 7, SET_INITIALIZATION_VALID = 8, CHECK_ROW_INIT = 9, CNT_INIT_ADDR = 10, SET_MEM_EN_A = 11} state, next_state;

	logic 											initialization_valid;
	logic [MEM_ADDRWIDE-1:0] 						mem_addr;
	logic											mem_en_a_d, mem_en_b_d;
	logic											mem_en_a_q, mem_en_b_q;
	logic signed [2*FEATURE_MAP_RESOLUTION-1:0]		mem_data_a, mem_data_b;
	logic signed [2*FEATURE_MAP_RESOLUTION-1:0]		inc_acc_value;
	logic 											instant_qcRec_data_d[REC_IMG_H-1:0][REC_IMG_W-1:0];
	logic 											instant_qcRec_data_q[REC_IMG_H-1:0][REC_IMG_W-1:0];
	logic signed [2*FEATURE_MAP_RESOLUTION-1:0]		tmp_qcRec_data_q, tmp_qcRec_data_d;
	logic 		[FEATURE_MAP_ADDRWIDE-1:0] 			mqcRec_addr_d, mqcRec_addr_q;

	logic signed [2*FEATURE_MAP_RESOLUTION-1:0] 	acc_qcRec_data_sh2,acc_qcRec_data_sh6, acc_qcRec_data_sh7;
	logic signed [2*FEATURE_MAP_RESOLUTION-1:0] 	mqcRec_data, acc_qcRec_data_d, acc_qcRec_data_q;
	logic											mqcRec_valid_d, mqcRec_valid_q;

	int rec_col_d,rec_col_q;
	int rec_row_d,rec_row_q;

	assign acc_qcRec_data_sh2 	= acc_qcRec_data_q >>> 2 ;
	assign acc_qcRec_data_sh6 	= acc_qcRec_data_q >>> 6;
	assign acc_qcRec_data_sh7 	= acc_qcRec_data_q >>> 7;

	assign mqcRec_data 			= acc_qcRec_data_sh2 + acc_qcRec_data_sh6 + acc_qcRec_data_sh7;
	assign mqcRec_data_o 		= mqcRec_data[FEATURE_MAP_RESOLUTION-1 : 0] + 8'hFF; // +Z_POINT
	assign mqcRec_addr_d 		= rec_col_q + REC_IMG_W*rec_row_q;
	assign mqcRec_valid_o		= mqcRec_valid_q;
	assign mqcRec_addr_o		= mqcRec_addr_q;

	assign tmp_qcRec_data_d 	= mem_data_b + inc_acc_value;
	assign mem_addr 			= rec_col_q + REC_IMG_W*rec_row_q;
	assign mem_data_a 			= initialization_valid ? 0 : tmp_qcRec_data_q;
	

	
	always_ff @(posedge clk_i) begin 		
		if(~rst_ni) begin
			state 					<=	IDLE;
		end else begin
			state 					<= 	next_state;
			rec_col_q 				<= 	rec_col_d;
			rec_row_q 				<= 	rec_row_d;
			instant_qcRec_data_q 	<= 	instant_qcRec_data_d;
			tmp_qcRec_data_q 		<= 	tmp_qcRec_data_d;
//			count_q             	<= 	count_d;
			acc_qcRec_data_q		<= 	acc_qcRec_data_d;
			mqcRec_valid_q			<=	mqcRec_valid_d;
			mqcRec_addr_q			<=	mqcRec_addr_d;
		end
	end


	always_comb begin
		next_state 				<= 	state;
		rec_col_d 				<= 	rec_col_q;
		rec_row_d 				<= 	rec_row_q;

		case (state)
			IDLE 	: 	begin	
				rec_row_d 					<= 0;
				rec_col_d 					<= 0;
				mqcRec_valid_d 				<= 1'b0;
				next_state 					<= SET_INITIALIZATION_VALID;	
//				count_d 					<= 0;
				initialization_valid 		<= 1'b0;
				mem_en_a_d 					<= 1'b0;					
				mem_en_b_d 					<= 1'b0;
				acc_qcRec_data_d			<= 0;
			end 

			WAIT_FOR_VALID	:	begin
				rec_row_d 					<= 0;
				rec_col_d 					<= 0;
				mem_en_a_d 					<= 1'b0;					
				mem_en_b_d 					<= 1'b0;						
				initialization_valid 		<= 1'b0;
				mqcRec_valid_d 				<= 1'b0;					
				if (instant_qcRec_valid_i) begin
					next_state 				<= CHECK_INSTANT_REC_ROW;
					instant_qcRec_data_d 	<= instant_qcRec_data_i;
				end else begin
					next_state 				<= WAIT_FOR_VALID;
				end
			end

			CHECK_INSTANT_REC_ROW 	: 	begin			
				mem_en_a_d 					<= 	1'b0;
				mqcRec_valid_d 				<= 	1'b0;
				if (rec_row_q < REC_IMG_H) begin
					next_state 				<= 	ACC_TASK;
					mem_en_b_d 				<= 	1'b1;										
				end else begin
					next_state 				<= 	CNT_INPUT_SAMPLES; 
					mem_en_b_d 				<= 	1'b0;
				end
			end

			ACC_TASK 	:    begin
				next_state 				<= 	SET_MEM_EN_A;	
				mem_en_b_d 				<= 	1'b0;
				mem_en_a_d 				<= 	1'b1;	            
				if (instant_qcRec_data_q[rec_row_q][rec_col_q]) 	
						inc_acc_value 	<= 16'h0001;
				else 
						inc_acc_value 	<= 16'hFFFF;
			end	
			
			SET_MEM_EN_A :	begin
				next_state 				<= 	CNT_INSTANT_REC_ADDR;
				mem_en_b_d 				<= 	1'b0;
				mem_en_a_d 				<= 	1'b1;
			
			end

			CNT_INSTANT_REC_ADDR 	:   begin
				next_state 				<= 	CHECK_INSTANT_REC_ROW; 
				mem_en_a_d 				<= 	1'b0;
				mem_en_b_d 				<= 	1'b0;
				mqcRec_valid_d 			<= 	1'b0;  
				if (rec_col_q < REC_IMG_W-1) begin 
					rec_col_d 			<= 	rec_col_q + 1;
					rec_row_d 			<= 	rec_row_q;
				end else begin
					rec_col_d 			<= 	0;
					rec_row_d 			<= 	rec_row_q + 1;							
				end 
			end 

			CNT_INPUT_SAMPLES   :	begin
				rec_col_d <= 0;
				rec_row_d <= 0;	
				if(count_samples_i < TOTAL_SAMPLES-1) begin
					next_state <= WAIT_FOR_VALID;
				end else begin
					next_state <= QUANTIZATION_ADDR_CHECK;
				end
			end	
			
			QUANTIZATION_ADDR_CHECK 	: 	begin
				mem_en_b_d 		<= 1'b1;					
				if (rec_row_q < REC_IMG_H) begin
					next_state <= QUANTIZATION_ADDR_INC;				
				end else
					next_state <= IDLE;

			end	

			QUANTIZATION_ADDR_INC 	:   begin
				acc_qcRec_data_d <= mem_data_b;
				mem_en_b_d 		<= 1'b1;						
				mqcRec_valid_d  <= 1'b1;
				next_state 		<= QUANTIZATION_ADDR_CHECK; 
				if (rec_col_q < REC_IMG_W) begin 
					rec_col_d 		<= rec_col_q + 1;
					rec_row_d 		<= rec_row_q;
				end else begin
					rec_col_d 		<= 0;
					rec_row_d 		<= rec_row_q + 1;							
				end 
			end 
			
			SET_INITIALIZATION_VALID	:	begin
				initialization_valid 	<= 1'b1;
				next_state 				<= CHECK_ROW_INIT;
			end

			CHECK_ROW_INIT	: 	begin				
				if (rec_row_q < REC_IMG_H) begin
					next_state 			<= CNT_INIT_ADDR;				
				end else
					next_state 			<= WAIT_FOR_VALID;
			end

			CNT_INIT_ADDR 	:   begin
				next_state <= CHECK_ROW_INIT; 
				if (rec_col_q < REC_IMG_W) begin 
					rec_col_d 			<= rec_col_q + 1;
					rec_row_d 			<= rec_row_q;
				end else begin
					rec_col_d 			<= 0;
					rec_row_d 			<= rec_row_q + 1;							
				end 
			end 
				
			default : 
				next_state <= IDLE;
		endcase		
	end

	ram_simple_dual_one_clock #(
        .WIDTH          (2*FEATURE_MAP_RESOLUTION),
        .SIZE           (TOTAL_PIXELS),
		.ADDRWIDTH      (MEM_ADDRWIDE)
		) 
    mem_acc (
        .clk    (clk_i),
        .ena    ((mem_en_a_d | initialization_valid)),
        .wea    (1'b1),
        .addra  (mem_addr),
        .dia    (mem_data_a),
        .enb    (mem_en_b_d),
        .addrb  (mem_addr),
		.dob    (mem_data_b)); 
		
	// ila_q_mqcRec mqcrec (
    //     .clk    	(clk_i),
    //     .probe0 	(mqcRec_valid_o),
    //     .probe1 	(mqcRec_data_o),
	// 	.probe2 	(mqcRec_addr_o),
	// 	.probe3		(state),
	// 	.probe4		(instant_qcRec_valid_i),
	// 	.probe5		(rec_col_q),
	// 	.probe6		(rec_row_q),
	// 	.probe7		(count_samples_i),
	// 	.probe8		(rst_ni),
	// 	.probe9		(mem_addr),
	// 	.probe10	(mem_en_a_d),
	// 	.probe11	(mem_data_a),
	// 	.probe12	(mem_data_b),
	// 	.probe13	(mem_en_b_d),
	// 	.probe14	(acc_qcRec_data_d),
	// 	.probe15	(acc_qcRec_data_sh2),
	// 	.probe16	(acc_qcRec_data_sh6)
	// );

endmodule 