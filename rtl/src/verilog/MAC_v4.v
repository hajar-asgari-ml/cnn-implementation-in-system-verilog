
(* DONT_TOUCH = "yes" *) // to prevent vivado removing top level ports

module MAC_v4 #(
    parameter INPUT_BIT_RESOLUTION = 8,
    parameter OUTPUT_BIT_RESOLUTION = 32
)

(
    // clk and reset
    input wire clk_i,    // Clock
    input wire rst_ni,  // Asynchronous reset active low

    //input interface
    input wire                                     mac_fin_and_kernel_valid_i,
    input wire [INPUT_BIT_RESOLUTION-1 : 0]        mac_fin_data_i,
    input wire [INPUT_BIT_RESOLUTION-1 : 0]        mac_kernel_data_i,
    input wire [OUTPUT_BIT_RESOLUTION-1 :0]        mac_kernel_bias_i,

    //output interface
    output reg                                    mac_valid_o,
    output reg [OUTPUT_BIT_RESOLUTION-1 : 0]      mac_data_o,
    input  wire                                    mac_ready_i
);
//    `include "parameters.v"
    
    localparam IDLE = 0,
               RECEIV_MAC_INPUTS = 1,
               SET_MAC_VALID = 2,
               WAIT_FOR_IN_VALID = 3;
               
    reg [2:0] state, next_state;

    wire [2*INPUT_BIT_RESOLUTION-1:0]                          mult_result;
    wire [OUTPUT_BIT_RESOLUTION-2*INPUT_BIT_RESOLUTION-1:0]    extend_mult_result;
    reg [OUTPUT_BIT_RESOLUTION-1 : 0]                         mac_data_d, mac_data_q;
    reg signed [OUTPUT_BIT_RESOLUTION-1 : 0]                  a_sadder_d, b_sadder_d;
    reg signed [OUTPUT_BIT_RESOLUTION-1 : 0]                  a_sadder_q, b_sadder_q;
    reg [OUTPUT_BIT_RESOLUTION-1 : 0]                         signed_add_result;    
    
    integer count;

    signed_mult #(
            .INPUT_BIT_RESOLUTION   (INPUT_BIT_RESOLUTION)) 
    mult    (
            .a             (mac_fin_data_i),
            .b             (mac_kernel_data_i),
            .out           (mult_result)   
            );

    assign extend_mult_result = mult_result[2*INPUT_BIT_RESOLUTION-1]? ~0 : 0; 

    // signed_add  #(
    //         .INOUT_BIT_RESOLUTION (OUTPUT_BIT_RESOLUTION))
    // s_add   (
    //         .a                  (a_sadder_d), 
    //         .b                  (b_sadder_d), 
    //         .out                (signed_add_result)        
    //         );

    // always_ff @(posedge clk_i or negedge rst_ni) begin : proc_state1
    always @(posedge clk_i) begin : proc_state1
        if(~rst_ni) begin
            state <= IDLE;
            mac_data_q <= 0; 
        end else begin
            state <= next_state;
            mac_data_q <= mac_data_d;
            a_sadder_q <= a_sadder_d;
            b_sadder_q <= b_sadder_d;
        end
    end

    always @* begin : proc_change_state
        next_state  <= state;

        case (state)
            IDLE :    begin
                mac_data_d      <= 0;
                mac_valid_o     <= 1'b0;
                a_sadder_d      <= 0;
                b_sadder_d      <= 0;
                if (mac_fin_and_kernel_valid_i) begin
                    next_state  <= RECEIV_MAC_INPUTS;                 
                end else begin
                    next_state  <= IDLE;
                end
            end         

            RECEIV_MAC_INPUTS :     begin
                if (mac_fin_and_kernel_valid_i) begin
                    next_state      <= RECEIV_MAC_INPUTS;
                    mac_data_d      <= {extend_mult_result, mult_result} + mac_data_q;
                    a_sadder_d      <= 0;
                    b_sadder_d      <= 0;                    
                end else begin
                    next_state      <= SET_MAC_VALID;
                    mac_data_d      <= mac_data_q;
                    a_sadder_d      <= mac_data_q;
                    b_sadder_d      <= mac_kernel_bias_i;                    
                end
            end

            SET_MAC_VALID :    begin
                next_state <= IDLE;
                // a_sadder_d <= a_sadder_q;
                // b_sadder_d <= b_sadder_q;
                if (mac_ready_i) begin
                    mac_valid_o <= 1'b1;
                    mac_data_o  <= a_sadder_q + b_sadder_q;
                end else begin
                    mac_valid_o <= 1'b0;
                    mac_data_o  <= ~0;
                end
            end

            default : next_state <= IDLE;

        endcase
    
    
    end

    // ila_4 mac_probe (
    //     .clk    (clk_i),
    //     .probe0 (a_sadder_d),
    //     .probe1 (b_sadder_d),
    //     .probe2 (mult_result),
    //     .probe3 (mac_data_d),
    //     .probe4 (mac_valid_o),
    //     .probe5 (mac_data_o),
    //     .probe6 (mac_kernel_bias_i)
    // );
 
    
endmodule
