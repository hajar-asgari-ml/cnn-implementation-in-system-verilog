(* DONT_TOUCH = "yes" *) // to prevent vivado removing top level ports

import pkg_parameters::*;

module ACC_QCorr #(
	parameter SAMPLING_RATE = 48,
	parameter TIME_WINDOW = 10
) (
	input logic 										clk_i, rst_ni,
	input logic 										qcorr_valid_i,
	input logic 										qcorr_data_i,
//	output logic 										qcorr_ready_o,

	output logic 										acc_qcorr_valid_o,
	output logic signed [2*	FEATURE_MAP_RESOLUTION-1:0] acc_qcorr_data_o,
	output logic signed [2*	FEATURE_MAP_RESOLUTION-1:0] acc_data_q_o,
	input  logic 										acc_qcorr_ready_i 
);

	localparam TOTAL_SAMPLES = SAMPLING_RATE*TIME_WINDOW;

	enum bit [2:0] {S0 =3'b000 , S1=3'b001 , S2=3'b010 , S3=3'b011, S4=3'b100, S5=3'b101} state, next_state;
	bit [15:0] count_d, count_q;
	
	logic	 										qcorr_data_d, qcorr_data_q;

    logic signed [2*FEATURE_MAP_RESOLUTION-1 : 0]   acc_data_d, acc_data_q;

	assign acc_data_q_o = acc_data_q;

	always_ff @(posedge clk_i) begin : proc_state1
	// always_ff @(posedge clk_i or negedge rst_ni) begin : proc_state1
	    if(~rst_ni) begin
	        state <= S0;
	        // count_q <= 0;
	        // acc_data_q <= 0;
	    end else begin
	        state               <= 	next_state;
	        count_q             <= 	count_d;	
			acc_data_q 			<= 	acc_data_d; 
			qcorr_data_q		<= 	qcorr_data_d;      
	    end
	end


	always_comb begin
		case (state)
			S0 	: 	begin
			             count_d <= 0;
						 acc_data_d <= 0;		
						 acc_qcorr_valid_o <= 0;  
						 acc_qcorr_data_o	<= 0;
						 next_state <= S1;						                        	             
			end
				    
			S1 	:	begin 
						count_d <= count_q;
						acc_data_d <= acc_data_q;
						if (qcorr_valid_i) begin
							next_state <= S2;
							qcorr_data_d <= qcorr_data_i;
						end else begin
							next_state <= S1;
						end
            end		
                    	
			S2 	:    begin
						next_state = S3;
						count_d <= count_q;			            
			            if (qcorr_data_q) 	
							acc_data_d <= acc_data_q + 16'h0001;
                        else 
                            acc_data_d <= acc_data_q + 16'hFFFF;
			end
			 	
			S3   :	begin	
						acc_data_d <= acc_data_q;
						if(count_q < TOTAL_SAMPLES-1) begin
							next_state <= S1;
							count_d <= count_q + 1;
						end else begin
							next_state <= S4;
							count_d <= count_q;
						end
			end
		

			S4 	: 	begin
						acc_qcorr_valid_o <= 1'b1;
						acc_qcorr_data_o <= acc_data_q;
						next_state <= S5; // CHANGE FROM S0 to S5 FOR ILA DEBUGGING
			end

			S5 	: 	begin // ADDED FOR ILA DEBUGGING
						acc_qcorr_valid_o <= 1'b0;
						next_state <= S0;
			end
		
			 default : next_state <= S0;
		endcase
	end
	// assign acc_qcorr_data_o = acc_data_q;
endmodule

