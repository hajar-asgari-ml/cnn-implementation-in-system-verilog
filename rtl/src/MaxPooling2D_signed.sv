(* DONT_TOUCH = "yes" *) // to prevent vivado removing top level ports

import pkg_parameters::*;

module MaxPooling2D_signed #(
    parameter MX_RESOLUTION = 8
)

(
    // clk and reset
    input logic                         clk_i,    // Clock
    input logic                         rst_ni,  // Asynchronous reset active low

    //input interface
    input logic                         load_mx_valid_i,
    input logic [MX_RESOLUTION-1:0]     load_mx_data_i,

    //output interface
    output logic                        exe_mx_valid_o,
    output logic [MX_RESOLUTION-1 : 0]  exe_mx_data_o,
    input logic                         exe_mx_ready_i
);

    enum bit [2:0] {IDLE =3'b000, TRANSITON_BASED_ON_MX_STATUS=3'b001, CALC_CURRENT_MAX=3'b010, SET_OUT_VALID=3'b011, S4=3'b100} state, next_state;

    logic [MX_RESOLUTION-1:0] current_max_d, current_max_q;
    logic [MX_RESOLUTION-1:0] load_mx_data_q;
    logic [2:0] cnt_mx_q, cnt_mx_d;

    // always_ff @(posedge clk_i or negedge rst_ni) begin : proc_state1
    always_ff @(posedge clk_i) begin : proc_state1        
        if(~rst_ni) begin
            state <= IDLE;
            current_max_q <= 8'hFF;
            cnt_mx_q <= 0;
        end else begin
            state <= next_state;
            current_max_q <= current_max_d;
            load_mx_data_q <= load_mx_data_i;  
            cnt_mx_q <= cnt_mx_d;          
        end
    end



    always_comb begin : proc_change_state
        next_state  <= state;
        
        case (state)
            IDLE  :   begin 
                current_max_d <= 8'hFF;
                exe_mx_data_o <= 8'b0;
                exe_mx_valid_o <= 1'b0;
                cnt_mx_d <= 0;
                next_state <= TRANSITON_BASED_ON_MX_STATUS;
                exe_mx_valid_o <= 1'b0;
            end

            TRANSITON_BASED_ON_MX_STATUS :    begin 
                current_max_d <= current_max_q;
                if (load_mx_valid_i) begin
                    next_state <= CALC_CURRENT_MAX;
                    cnt_mx_d <= cnt_mx_q + 1;               
                end else if (exe_mx_ready_i) begin
                    next_state <= SET_OUT_VALID;
                    cnt_mx_d <= cnt_mx_q;
                end else begin
                    next_state <= TRANSITON_BASED_ON_MX_STATUS;
                    cnt_mx_d <= cnt_mx_q;
                end 
            end               

            CALC_CURRENT_MAX :    begin 
                if (cnt_mx_q == 1) 
                    current_max_d <= load_mx_data_q;
                else 
                    if (!current_max_q[MX_RESOLUTION-1] && load_mx_data_q[MX_RESOLUTION-1])
                        current_max_d <= current_max_q;
                    else if (current_max_q[MX_RESOLUTION-1] && !load_mx_data_q[MX_RESOLUTION-1])
                        current_max_d <= load_mx_data_q;
                    else 
                        if (current_max_q < load_mx_data_q) 
                            current_max_d <= load_mx_data_q;
                        else 
                            current_max_d <= current_max_q;
                next_state <= TRANSITON_BASED_ON_MX_STATUS;
                cnt_mx_d <= cnt_mx_q;
            end 

            SET_OUT_VALID  :   begin 
                next_state <= IDLE;
                exe_mx_data_o <= current_max_q;
                exe_mx_valid_o <= 1'b1;
            end

            default : next_state <= TRANSITON_BASED_ON_MX_STATUS;
        endcase      
    end    
endmodule
