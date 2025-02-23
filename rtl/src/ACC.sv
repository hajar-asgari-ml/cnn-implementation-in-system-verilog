(* DONT_TOUCH = "yes" *) // to prevent vivado removing top level ports
import pkg_parameters::*;

module ACC #(
    parameter ACC_RESOLUTION = 32,
    parameter ACC_DATA_DEPTH = 8
)

    (
    // clk and reset
    input logic clk_i,    // Clock
    input logic rst_ni,  // Asynchronous reset active low

    //input interface
    input logic acc_valid_i[0 : ACC_DATA_DEPTH-1],
    input logic [ACC_RESOLUTION-1 : 0] acc_data_i[0 : ACC_DATA_DEPTH-1],
    input logic [ACC_RESOLUTION-1 :0] kernel_bias_i,

    //output interface
    output logic acc_valid_o,
    output logic [ACC_RESOLUTION-1 : 0]acc_data_o,
    input logic acc_ready_i
);

    enum bit [1:0] {IDLE = 2'b00, INC_INDEX = 2'b01, SET_OUT_VALID = 2'b10} state, next_state;

    logic [ACC_RESOLUTION-1 : 0]    acc_data_d, acc_data_q;
    logic [ACC_RESOLUTION-1 : 0]    a_sadder, b_sadder;
    
    bit [4:0] index_d, index_q;

    always_ff @(posedge clk_i) begin : proc_state1
        if(~rst_ni) begin
            state <= IDLE;
            acc_data_q <= 0; 
            index_q <= 0;
        end else begin
            state <= next_state;
            acc_data_q <= acc_data_d;
            index_q <= index_d;
        end
    end

    signed_add #(
        .INOUT_BIT_RESOLUTION   (ACC_RESOLUTION)
    ) 
    s_add (
        .a                  (a_sadder), 
        .b                  (b_sadder), 
        .out                (acc_data_d)        
    );

    always_comb begin : proc_change_state
        next_state  <= state;
        
        case (state)
            IDLE :    begin
                acc_valid_o     <= 1'b0;
                b_sadder        <= 0;
                if (acc_valid_i[0]) begin
                    next_state  <= INC_INDEX;
                    a_sadder    <= acc_data_i[index_q];
                    index_d     <= 5'b00001;                  
                end else begin
                    next_state  <= IDLE;
                    a_sadder    <= 0;                        
                    index_d     <= 5'b00000;
                end
            end

            INC_INDEX :    begin
                acc_valid_o <= 1'b0;
                if (index_q < ACC_DATA_DEPTH) begin
                    next_state  <= INC_INDEX;
                    a_sadder    <= acc_data_i[index_q];
                    b_sadder    <= acc_data_q;
                    index_d     <= index_q +  5'b00001;
                end else begin
                    next_state  <= SET_OUT_VALID;
                    a_sadder    <= kernel_bias_i;
                    b_sadder    <= acc_data_q;
                    index_d     <= index_q;
                end
            end

            SET_OUT_VALID :    begin
                next_state <= IDLE;
                if (acc_ready_i) begin
                    acc_valid_o <= 1'b1;
                    acc_data_o <= acc_data_q;
                end else begin
                    acc_valid_o <= 1'b0;
                    acc_data_o <= 0;
                end
            end

            default : next_state <= IDLE;
        endcase      
    end  
endmodule
