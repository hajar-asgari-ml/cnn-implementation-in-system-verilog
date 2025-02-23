/*
With the final value of the int32 accumulator, there remain three things left
to do: scale down to the final scale used by the 8-bit output activations, 
cast down to uint8 and 
apply the activation function to yield the final 8-bit output activation. 
This module does all the 3 steps: 
first down scaling by multiply the input by M.
Then implement relu function in state WAIT_FOR_VALID,
and then implement saturatin cast in state MULT_TASK.
ref title: "Quantization and Training of Neural Networks for Efficient Integer-Arithmetic-Only Inference"
*/
(* DONT_TOUCH = "yes" *) // to prevent vivado removing top level ports
import pkg_parameters::*;

module Int32_to_Int8_out #(
    parameter DWSCALING_IN_RESOLUTION = 32,
    parameter DWSCALING_OUT_RESOLUTION = 8
)

(
    // clk and reset
    input logic clk_i,    // Clock
    input logic rst_ni,  // Asynchronous reset active low

    //input interface
    input logic                                         dwscaling_valid_i,
    input logic signed [DWSCALING_IN_RESOLUTION-1 : 0]  dwscaling_data_i,
    input logic [DWSCALING_OUT_RESOLUTION-1 : 0]        dwscaling_z3_i,
    input logic [DWSCALING_IN_RESOLUTION-1 : 0]         dwscaling_m0_i,
    input logic signed [DWSCALING_IN_RESOLUTION-1 : 0]  dwscaling_b_i,
    input logic [4 : 0]                                 dwscaling_n_i, 


    //output interface
    output logic dwscaling_valid_o,
    output logic [DWSCALING_OUT_RESOLUTION-1 : 0] dwscaling_data_o,
    input logic dwscaling_ready_i
);

    enum bit [2:0] {IDLE = 3'b000, WAIT_FOR_VALID = 3'b001, MULT_TASK = 3'b010, SATURATING_CAST = 3'b011, SET_OUT_VALID = 3'b100} state, next_state;

    logic [2*DWSCALING_IN_RESOLUTION-1 : 0]     mult_data_d, mult_data_q;
    logic signed [DWSCALING_IN_RESOLUTION-1 : 0]       a_smult_q, b_smult_q;
    logic signed [DWSCALING_IN_RESOLUTION-1 : 0]       a_smult_d, b_smult_d;
    logic [DWSCALING_IN_RESOLUTION-1 : 0]       to_saturating_cast_d, to_saturating_cast_q;
    logic signed [DWSCALING_IN_RESOLUTION-1 : 0] sum_in_and_B;

    assign sum_in_and_B = dwscaling_data_i - dwscaling_b_i;

    always_ff @(posedge clk_i) begin : proc_state1        
        if(~rst_ni) begin
            state                   <= IDLE;
        end else begin
            state                   <= next_state;
            mult_data_q             <= mult_data_d;
            to_saturating_cast_q    <= to_saturating_cast_d;
            a_smult_q               <= a_smult_d;
            b_smult_q               <= b_smult_d;
        end
    end

    always_comb begin : proc_change_state
        next_state  <= state;
        
        case (state)

            IDLE  :   begin   
                next_state <= WAIT_FOR_VALID;
                a_smult_d <= 0;
                b_smult_d <= 0;  
                mult_data_d <= 0;                  
                dwscaling_valid_o <= 1'b0;
                to_saturating_cast_d <= 0;
                dwscaling_data_o <= 0;
            end 
    
            WAIT_FOR_VALID :    begin
                if (dwscaling_valid_i) begin
                    next_state <= MULT_TASK;
                    if (sum_in_and_B[DWSCALING_IN_RESOLUTION-1])
                        a_smult_d <= 0;
                    else
                        a_smult_d <= sum_in_and_B;
                    b_smult_d <= dwscaling_m0_i>>1;            
                end else begin
                    next_state <= WAIT_FOR_VALID;

                end
            end

            MULT_TASK  :   begin
                mult_data_d <= a_smult_q*b_smult_q;
                next_state <= SATURATING_CAST;
            end
                
            SATURATING_CAST  :   begin
                next_state <= SET_OUT_VALID;       
                to_saturating_cast_d <= mult_data_q[2*DWSCALING_IN_RESOLUTION-1 : DWSCALING_IN_RESOLUTION] >> dwscaling_n_i-1;                            
            end 

            SET_OUT_VALID :    begin
                next_state <= IDLE;
                if (dwscaling_ready_i) begin
                    if (to_saturating_cast_q[DWSCALING_OUT_RESOLUTION-1:0] < 8'hFF) begin
                        dwscaling_data_o <= to_saturating_cast_q[DWSCALING_OUT_RESOLUTION-1:0] + dwscaling_z3_i;
                    end else begin 
                        dwscaling_data_o <= 8'b1111_1111;
                    end 
                    dwscaling_valid_o <= 1'b1;
                 end else begin
                    dwscaling_valid_o <= 1'b0;
                    dwscaling_data_o <= 32'b0;    
                end
            end

            default :   
                next_state <= IDLE;
        endcase      
    end

//  ila_3 dw_probe (
//      .clk   (clk_i),
//      .probe0    (a_smult),
//      .probe1    (mult_data_q),
//      .probe2    (to_saturating_cast_d),
//      .probe3    (dwscaling_valid_o),
//      .probe4    (dwscaling_data_o),
//      .probe5    (dwscaling_data_i),
//      .probe6    (sum_in_and_B),
//      .probe7    (b_smult),
//      .probe8    (dwscaling_b_i),
//      .probe9    (mult_data_d),
//      .probe10   (1'b1)
//  );
    
endmodule
