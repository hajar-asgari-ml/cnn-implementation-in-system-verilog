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

module Q_Mqcr_Rec #(

	parameter unsigned REC_IMG_W 				= 29,
	parameter unsigned REC_IMG_H 				= 13
	) (
	input logic 										clk_i, rst_ni,
    input logic 										acc_qcR_valid_i,
    input logic signed [2*FEATURE_MAP_RESOLUTION-1:0]	acc_qcR_data_i[REC_IMG_H-1:0][REC_IMG_W-1:0],
    input logic 		[FEATURE_MAP_ADDRWIDE-1:0] 		acc_qcR_addr_i,
    input logic 										acc_qcR_ready_i,

   	output logic 										mqcRec_valid_o,
    output logic 	    [FEATURE_MAP_RESOLUTION-1:0]	mqcRec_data_o,
    output logic 		[FEATURE_MAP_ADDRWIDE-1:0] 		mqcRec_addr_o,
    input logic 										mqcRec_ready_i  
	);

	
	enum bit [1:0] {S0 = 2'b00, S1 = 2'b01, S2 = 2'b10, S3 = 2'b11} state, next_state;
	logic signed [2*FEATURE_MAP_RESOLUTION-1:0]		acc_qcR_data_d[REC_IMG_H-1:0][REC_IMG_W-1:0];
	logic signed [2*FEATURE_MAP_RESOLUTION-1:0]		acc_qcR_data_q[REC_IMG_H-1:0][REC_IMG_W-1:0];
	logic signed [2*FEATURE_MAP_RESOLUTION-1:0] 	acc_qcR_data_sh2,acc_qcR_data_sh6, acc_qcR_data_sh7;
	logic signed [2*FEATURE_MAP_RESOLUTION-1:0] 	mqcRec_data, acc_qcR_data;
	int rec_col_d,rec_col_q;
	int rec_row_d,rec_row_q;

	assign acc_qcR_data_sh2 = acc_qcR_data >>> 2 ;
	assign acc_qcR_data_sh6 = acc_qcR_data >>> 6;
	assign acc_qcR_data_sh7 = acc_qcR_data >>> 7;
	assign mqcRec_data = acc_qcR_data_sh2 + acc_qcR_data_sh6 + acc_qcR_data_sh7;
	assign mqcRec_data_o = mqcRec_data[FEATURE_MAP_RESOLUTION-1 : 0] + 8'hFF; // +Z_POINT
	assign mqcRec_addr_o = rec_col_q + REC_IMG_W*rec_row_q;


	// always_ff @(posedge clk_i or negedge rst_ni) begin 
	always_ff @(posedge clk_i) begin 		
		if(~rst_ni) begin
			state 		<=	S0;
		end else begin
			state 			<= next_state;
			rec_col_q 		<= rec_col_d;
			rec_row_q 		<= rec_row_d;
			acc_qcR_data_q	<= acc_qcR_data_d;
			// acc_qcR_data <= acc_qcR_data_q[rec_row_d][rec_col_d];
		end
	end


	always_comb begin
		case (state)
			S0 	: 	begin	
						rec_row_d 		<= 0;
						rec_col_d 		<= 0;
						mqcRec_valid_o <= 1'b0;
						next_state <= S1;

			end 

			S1	:	begin
						if (acc_qcR_valid_i) begin
							next_state <= S2;
							acc_qcR_data_d <= acc_qcR_data_i;
						end else begin
							next_state <= S1;
						end
			end

			S2 	: 	begin
						acc_qcR_data <= acc_qcR_data_q[rec_row_q][rec_col_q];
						rec_col_d	<=	rec_col_q;
						rec_row_d	<= 	rec_row_q;
						mqcRec_valid_o <= 1'b1; 
						if (rec_row_q < REC_IMG_H) begin
							next_state <= S3;				
						end else
							next_state <= S0;
			end

			S3 	:   begin
						next_state <= S2; 
						if (rec_col_q < REC_IMG_W) begin 
							rec_col_d 		<= rec_col_q + 1;
							rec_row_d 		<= rec_row_q;
						end else begin
							rec_col_d 		<= 0;
							rec_row_d 		<= rec_row_q + 1;							
						end 
			end 			
				
			default : next_state <= S0;
		endcase		
	end

	// ila_mqcrec mqcrec (
    //     .clk    	(clk_i),
    //     .probe0 	(rst_ni),
    //     .probe1 	(mqcRec_data_o),
	// 	.probe2 	(mqcRec_addr_o),
	// 	.probe3		(state),
	// 	.probe4		(acc_qcR_valid_i),
	// 	.probe5		(acc_qcR_data_i[0][0])
	// 	// .probe6		(acc_qcR_data_i[1][0])
	// 	// .probe7		(acc_qcR_data_i[2][0]),
	// 	// .probe8		(acc_qcR_data_i[3][0]),
	// 	// .probe9		(acc_qcR_data_i[4][0]),
	// 	// .probe10	(acc_qcR_data_i[5][    0]),
	// 	// .probe11	(acc_qcR_data_i[6][0]),
	// 	// .probe12	(acc_qcR_data_i[7][0]),
	// 	// .probe13	(acc_qcR_data_i[8][0])
	// );

	// ila_mqcrec1 mqcrec (
    //    .clk    	(clk_i),
    //    .probe0 	(rst_ni),
	// 	.probe4		(acc_qcR_valid_i),
	// 	.probe5		(acc_qcR_data_i[0][0])
	// 	// .probe6		(acc_qcR_data_i[1][0])
	// 	// .probe7		(acc_qcR_data_i[2][0]),
	// 	// .probe8		(acc_qcR_data_i[3][0]),
	// 	// .probe9		(acc_qcR_data_i[4][0]),
	// 	// .probe10	(acc_qcR_data_i[5][0]),
	// 	// .probe11	(acc_qcR_data_i[6][0]),
	// 	// .probe12	(acc_qcR_data_i[7][0]),
	// 	// .probe13	(acc_qcR_data_i[8][0])
	// );
	
endmodule 