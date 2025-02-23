(* DONT_TOUCH = "yes" *) // to prevent vivado removing top level ports

import pkg_parameters::*;

module Flatten #(
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



enum bit [3:0] {IDLE = 4'b0000, WAIT_FOR_VALID = 4'b0001, CNT_RECEIVED_PIXELS = 4'b0010, SET_OUT_VALID = 4'b0011, MOVE_TO_IDLE = 4'b0100} state, next_state;

// interfaces
bit [FEATURE_MAP_ADDRWIDE-1 : 0]                count_d, count_q, fin_d_cnt_d, fin_d_cnt_q;
logic [FEATURE_MAP_RESOLUTION-1 : 0]            feature_in_data_d [0 : F_IN_D-1];
logic [FEATURE_MAP_RESOLUTION-1 : 0]            feature_in_data_q [0 : F_IN_D-1];
logic [FEATURE_MAP_RESOLUTION-1 : 0]            flatten_data[0 : FLATTEN_OUT_SIZE-1];
bit [DENSE_WEIGHTS_ADDRWIDE-1:0]                w_col_d, w_col_q;
bit [DENSE_WEIGHTS_ADDRWIDE-1:0]                write_p;
logic                                           flatten_is_valid;

assign write_p = count_q*F_IN_D;// fin_d_cnt_q is deleted becouse it caused a failure in on-chip debugging with ILA
// so with this change it is not possible to have more than 1 channel in conv2D
// i'm going to resolve this problem in flatten_v2.sv
// assign write_p = count_q*F_IN_D + fin_d_cnt_q; //

assign flatten_data_o = flatten_data;
//assign flatten_data [write_p] = feature_in_data_d[fin_d_cnt_q];


// always_ff @(posedge clk_i or negedge rst_ni) begin : proc_state1
always_ff @(posedge clk_i) begin : proc_state1
    if(~rst_ni) begin
        state <= IDLE;
    end else begin
        state                                   <= next_state;
        count_q                                 <= count_d;
        fin_d_cnt_q                             <= fin_d_cnt_d;
        feature_in_data_q                       <= feature_in_data_d;
        flatten_data [write_p]                  <= feature_in_data_d[fin_d_cnt_q];
    end
end

always_comb begin : proc_change_state
    next_state  <= state;
    
    case (state)
        IDLE  :   begin
            count_d                     <= 0;
            flatten_valid_o             <= 1'b0;
            fin_d_cnt_d                 <= 0;
            next_state                  <= WAIT_FOR_VALID;
        end

        WAIT_FOR_VALID  :   begin
            feature_in_data_d           <= feature_in_data_i;
            flatten_valid_o             <= 1'b0;
            count_d                     <= count_q;
            if (feature_in_valid_i) begin
                next_state              <= CNT_RECEIVED_PIXELS;    
            end else begin
                next_state              <= WAIT_FOR_VALID;
            end
        end

        CNT_RECEIVED_PIXELS  :   begin    
            flatten_valid_o             <= 1'b0;          
            if (count_q < F_IN_WXH-1) begin
                    count_d             <= count_q + 1;
                    next_state          <= WAIT_FOR_VALID;
            end else begin
                    count_d             <= count_q;
                    next_state          <= SET_OUT_VALID;
            end
        end

        SET_OUT_VALID  :   begin
            next_state              <= MOVE_TO_IDLE;
            if(flatten_ready_i) 
                flatten_valid_o         <= 1'b1;

        end 

        MOVE_TO_IDLE  :   begin
            flatten_valid_o         <= 1'b0;
            next_state              <= IDLE; 
        end

        default:
                next_state                      <= IDLE;
         
    endcase    
end

 

endmodule
