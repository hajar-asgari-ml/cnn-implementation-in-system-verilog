(* DONT_TOUCH = "yes" *) // to prevent vivado removing top level ports



import pkg_parameters::*;

module CountSamples#(

	parameter unsigned SAMPLING_RATE 			= 48,
	parameter unsigned TIME_WINDOW 				= 10
	) (
    input logic clk_i,
    input logic rst_ni,
    input logic sound_valid_i,
    output logic [15:0] count_samples_o,
    output logic reset_car_rams_o
);

localparam TOTAL_SAMPLES = SAMPLING_RATE*TIME_WINDOW;

enum int unsigned {IDLE =0, WAIT_FOR_VALID=1, CHECK_CRITERIA=2} state, next_state;

logic [15:0] count_samples_d, count_samples_q;

assign count_samples_o = count_samples_q;


always_ff @(posedge clk_i) begin 
    if (!rst_ni) begin
        state <= IDLE;
    end else begin
        state <= next_state;
        count_samples_q <= count_samples_d;
    end
end


always_comb begin
    next_state <= state;
    count_samples_d <= count_samples_q;

    case (state)
        IDLE    :   begin
            count_samples_d <= 0;
            next_state <= WAIT_FOR_VALID;
            reset_car_rams_o <= 1'b0;
        end

        WAIT_FOR_VALID :    begin
            if (sound_valid_i) begin
                count_samples_d <= count_samples_q + 16'h0001;
                next_state <= CHECK_CRITERIA;
            end else begin
                next_state <= WAIT_FOR_VALID;
            end

        end

        CHECK_CRITERIA :    begin
            if (count_samples_q < TOTAL_SAMPLES) begin
                next_state <= WAIT_FOR_VALID;
                reset_car_rams_o <= 1'b0;
            end else begin
                next_state <= IDLE;
                reset_car_rams_o <= 1'b1;
            end
        end
        
    endcase
end



// ila_cnt_smpl ila_cnt_smpl1 (
//     .clk(clk_i),
//     .probe0 (sound_valid_i),
//     .probe1 (count_samples_o),
//     .probe2 (state),
//     .probe3 (count_samples_q),
//     .probe4 (reset_car_rams_o)
// );
    
endmodule
