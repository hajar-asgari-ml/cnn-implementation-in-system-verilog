(* DONT_TOUCH = "yes" *) // to prevent vivado removing top level ports

import pkg_parameters::*;

module Flatten_v2 #(
    parameter F_IN_D = 8,
    parameter F_IN_H = 5,
    parameter F_IN_W = 1,
    parameter F_IN_WXH = F_IN_H*F_IN_W,
    parameter FLATTEN_OUT_SIZE = F_IN_WXH*F_IN_D
    )

    (
    // clk and reset
    input   logic                                       clk_i,    // Clock
    input   logic                                       rst_ni,  // Asynchronous reset active low

    // feature in interface
    input   logic                                       feature_in_valid_i,
    input   logic [FEATURE_MAP_RESOLUTION-1 : 0]        feature_in_data_i [0 : F_IN_D-1],
    input   logic [FEATURE_MAP_ADDRWIDE-1 : 0]          feature_in_addr_i,
    output  logic                                       feature_in_ready_o,


    //Flatten interface
    output logic                                        flatten_valid_o,
    output logic [FEATURE_MAP_RESOLUTION-1 : 0]         flatten_data_o[0 : FLATTEN_OUT_SIZE-1],
    input  logic                                        flatten_ready_i
);



enum bit [3:0] {S0 = 4'b0000, S1 = 4'b0001, S2 = 4'b0010, S3 = 4'b0011, S4 = 4'b0100, S5 = 4'b0101} state, next_state;

// interfaces
bit [FEATURE_MAP_ADDRWIDE-1 : 0]                count_d, count_q, fin_d_cnt_d, fin_d_cnt_q;
logic [FEATURE_MAP_RESOLUTION-1 : 0]            feature_in_data_d [0 : F_IN_D-1];
logic [FEATURE_MAP_RESOLUTION-1 : 0]            feature_in_data_q [0 : F_IN_D-1];
logic [FEATURE_MAP_RESOLUTION-1 : 0]            flatten_data[0 : FLATTEN_OUT_SIZE-1];
bit [DENSE_WEIGHTS_ADDRWIDE-1:0]                w_col_d, w_col_q;
bit [DENSE_WEIGHTS_ADDRWIDE-1:0]                write_p;
logic                                           flatten_is_valid;


assign write_p = count_q*F_IN_D + fin_d_cnt_q; 
assign flatten_data_o = flatten_data;



always_ff @(posedge clk_i) begin : proc_state1
    if(~rst_ni) begin
        state <= S0;
    end else begin
        state                                   <= next_state;
        count_q                                 <= count_d;
        fin_d_cnt_q                             <= fin_d_cnt_d;
        feature_in_data_q                       <= feature_in_data_d;
        flatten_data [write_p]                  <= feature_in_data_d[fin_d_cnt_q];
    end
end

always_comb begin : proc_change_state
    case (state)
        S0  :   begin
                    count_d                     <= 0;
                    flatten_valid_o             <= 1'b0;
                    fin_d_cnt_d                 <= 0;
                    next_state                  <= S1;
                end

        S1  :   begin
                    feature_in_data_d           <= feature_in_data_i;
                    flatten_valid_o             <= 1'b0;
                    count_d                     <= count_q;
                    if (feature_in_valid_i) begin
                        next_state              <= S2;    
                    end else begin
                        next_state              <= S1;
                    end
                end

        S2  :   begin    
                    flatten_valid_o             <= 1'b0;  
                    fin_d_cnt_d                 <= 0;        
                    if (count_q < F_IN_WXH-1) begin
                            count_d             <= count_q + 1;
                            next_state          <= S5;
                    end else begin
                            count_d             <= count_q;
                            next_state          <= S3;
                    end
                end

        S3  :   begin
                    // flatten_valid_o             <= 1'b0;
                    next_state              <= S4;
                    if(flatten_ready_i) 
                        flatten_valid_o         <= 1'b1;

                end 
// S4 is a temporary state and need to be deleted after connecting ready signal from the next stage
        S4  :   begin
                    flatten_valid_o         <= 1'b0;
                    next_state              <= S0; 
                end
        
        S5  :   begin
            count_d             <= count_q;
            feature_in_data_d   <= feature_in_data_q;
            if (fin_d_cnt_q < F_IN_D) begin
                fin_d_cnt_d <= fin_d_cnt_q + 1;
                next_state <= S5;
            end else begin
                next_state <= S1;
            end
        end

        default:
                next_state                      <= S0;
         
    endcase    
end

 

endmodule
