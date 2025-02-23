(* DONT_TOUCH = "yes" *) // to prevent vivado removing top level ports

import pkg_parameters::*;

module CNN_wrapper 
    (
    input 	logic clk_i,
    input   logic ck_rst,
    

    // input interface


    // output interface
    output logic                                            cnn_prediction_valid_o,
    output logic [FEATURE_MAP_RESOLUTION-1 : 0]             cnn_prediction_data_o[0: NUM_CLASSES-1], 
    input  logic                                            cnn_prediction_ready_i
    );
    
    localparam WAIT_BEFORE_RESETING     = 50;
    localparam WAIT_IN_RESET_STATE      = 300;

	logic 									                cnn_input_valid; 								
	logic [FEATURE_MAP_RESOLUTION-1 :0]		                cnn_input_data[0 : F_IN_D1-1];			
	logic [FEATURE_MAP_ADDRWIDE-1:0]		                cnn_input_addr; 					
	logic									                cnn_input_ready; 

    logic                                        	        cnn_prediction_valid;
    logic [FEATURE_MAP_RESOLUTION-1 : 0]         	        cnn_prediction_data [0: NUM_CLASSES-1];
    logic [FEATURE_MAP_RESOLUTION-1 : 0]         	        cnn_prediction_data_d[0: NUM_CLASSES-1];
    logic [FEATURE_MAP_RESOLUTION-1 : 0]         	        cnn_prediction_data_q[0: NUM_CLASSES-1];
    

    // logic mem_en;
    logic rst_n;
    logic [INPUT_SOUND_ADDRWIDE-1:0] cnt_pixel_d = 0;
    logic [INPUT_SOUND_ADDRWIDE-1:0] cnt_pixel_q = 0;
    logic [INPUT_SOUND_ADDRWIDE-1:0] cnt_pixel_q1 = 0;
    logic [INPUT_SOUND_ADDRWIDE-1:0] cnt_q = 0;
    logic [INPUT_SOUND_ADDRWIDE-1:0] cnt_d = 0;
    logic [FEATURE_MAP_RESOLUTION-1:0] img_arr_4000 [0:F_IN_W1*F_IN_H1-1];
    logic [FEATURE_MAP_RESOLUTION-1:0] img_arr_1000 [0:F_IN_W1*F_IN_H1-1];
    logic [FEATURE_MAP_RESOLUTION-1:0] img_arr_5000 [0:F_IN_W1*F_IN_H1-1];

    enum bit [1:0] {WAIT_IN_RESET =2'b00, SET_VALID=2'b01, SEND_IMG_PIXELS=2'b10, WAIT_FOR_PRED_VALID=2'b11} state, next_state;

    assign cnn_prediction_data_o = cnn_prediction_data_d;
    // assign cnn_prediction_valid_o = cnn_prediction_valid;
     
    always_ff @(posedge clk_i) begin                
        if(~rst_n) begin            
            cnt_pixel_q <= 0;
            state <= WAIT_IN_RESET;
            cnt_q <= 0;
        end else begin
            cnt_q                   <= cnt_d;
            state                   <= next_state;
            cnt_pixel_q             <= cnt_pixel_d;
            cnt_pixel_q1            <= cnt_pixel_q;
           cnn_prediction_data_q   <= cnn_prediction_data_d;
        end 
    end

    always_comb begin 
        next_state <= state;

        case(state)
            WAIT_IN_RESET  :   begin
                cnt_pixel_d                 <= 12'b0000_0000_0000;
                cnn_input_valid             <= 1'b0;
                if (cnt_d < WAIT_IN_RESET_STATE) begin 
                    cnt_d                   <= cnt_q + 12'b0000_0000_0001;
                    next_state              <= WAIT_IN_RESET; 
                end else begin
                    cnt_d                   <= cnt_q;
                    next_state              <= SET_VALID;                            
                end
            end

            SET_VALID  :   begin
                cnn_input_valid             <= 1'b1;
                next_state                  <= SEND_IMG_PIXELS;
                cnt_d                       <= 12'b0000_0000_0000;
            end

            SEND_IMG_PIXELS  :   begin 
                cnn_input_valid         <= 1'b1;
                if (cnt_pixel_q < F_IN_H1*F_IN_W1) begin
                    cnt_pixel_d             <= cnt_pixel_q + 12'b0000_0000_0001;                                                
                    next_state              <= SEND_IMG_PIXELS;
                end else begin
                    next_state              <= WAIT_FOR_PRED_VALID;                        
                end
            end

            WAIT_FOR_PRED_VALID  :   begin
                cnn_input_valid             <= 1'b0;
                next_state                  <= WAIT_FOR_PRED_VALID;
                if (cnn_prediction_valid_o) 
                    cnn_prediction_data_d <= cnn_prediction_data;
                // else
                //     cnn_prediction_data_d <= cnn_prediction_data_q;
                        
            end
                            
            default : 
                next_state <= WAIT_IN_RESET;
        endcase
    end

    assign cnn_input_addr = cnt_pixel_q1;

//    Internal_Reset rst 
//    (
//        .rst_ni                 (~ck_rst),
//        .clk_i                  (clk_i),
//        .rst_no                 (rst_n)
//    );

   rst_continues rst_cont (
       .clk     (clk_i),
       .out     (rst_n)
   );

    //  assign rst_n = ~ck_rst;

	CNN cnn 
	(
		.rst_ni                         (rst_n),
		.clk_i                          (clk_i),
		.cnn_input_valid_i              (cnn_input_valid), 
		.cnn_input_data_i               (cnn_input_data[0]), 
		.cnn_input_addr_i               (cnn_input_addr), 
		.cnn_input_ready_o              (cnn_input_ready), 

		.cnn_prediction_valid_o         (cnn_prediction_valid_o),
		.cnn_prediction_data_o          (cnn_prediction_data),
		.cnn_prediction_ready_i         (cnn_prediction_ready_i)

    );  
    
//    ila_0 cnn_probe (
//        .clk        (clk_i),
//        .probe0     (cnn_prediction_valid_o),
//        .probe1     (cnn_prediction_data_o[0]),
//        .probe2     (cnn_prediction_data_o[1]),
//        .probe3     (state),
//        .probe4     (cnt_pixel_q),
//        .probe5     (cnn_input_data[0]),
//        .probe6     (cnn_input_valid)
//    );

    ila_cnn_pred cnn_probe (
       .clk        (clk_i),
       .probe0     (cnn_prediction_valid_o),
       .probe1     (cnn_prediction_data_o[0]),
       .probe2     (cnn_prediction_data_o[1]),
       .probe3     (rst_n)
    );

    ram_simple_dual_one_clock #(
        .WIDTH          (FEATURE_MAP_RESOLUTION),
        .SIZE           (F_IN_W1*F_IN_H1),
        .ADDRWIDTH      (FEATURE_MAP_ADDRWIDE),
        .INITFILENAME   (INITFILE_CNN_TEST_INPUT))
    mem_img (
        .clk    (clk_i),
        .ena    (),
        .wea    (1'b0),
        .addra  (),
        .dia    (),
        .enb    (cnn_input_valid),
        .addrb  (cnt_pixel_q),
        .dob    (cnn_input_data[0]));

endmodule