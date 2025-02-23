(* DONT_TOUCH = "yes" *) // to prevent vivado removing top level ports

import pkg_parameters::*;

module CNN 
    (
    // clk and reset
    input   logic                                         clk_i,    // Clock
    input   logic                                         rst_ni,  // Asynchronous reset active low

    // input interface
    input   logic                                         cnn_input_valid_i,
    input   logic [FEATURE_MAP_RESOLUTION-1 : 0]          cnn_input_data_i,
    input   logic [FEATURE_MAP_ADDRWIDE-1 : 0]            cnn_input_addr_i,
    output  logic                                        cnn_input_ready_o,

    // visualize featurmaps for the simulations
//   output  logic                                       conv2d1_vis_feature_map_valid_o,   
//   output  logic [FEATURE_MAP_RESOLUTION-1 : 0]        conv2d1_vis_feature_map_data_o [0: F_OUT_D1-1],
//   output  logic [FEATURE_MAP_ADDRWIDE-1 : 0]          conv2d1_vis_feature_map_addr_o,

    // densel1 visualize interface for the simulations
//   output  logic                                       dense_l1_vis_feature_map_valid_o,   
//   output  logic [FEATURE_MAP_RESOLUTION-1 : 0]        dense_l1_vis_feature_map_data_o [0: NUM_NEURONS-1],

    // output interface (cnn prediction)
    output  logic                                        cnn_prediction_valid_o,
    output  logic [FEATURE_MAP_RESOLUTION-1 : 0]         cnn_prediction_data_o[0: NUM_CLASSES-1],
    input   logic                                        cnn_prediction_ready_i
);

// interfaces 
typedef struct {
    logic                                       valid;
    logic [FEATURE_MAP_RESOLUTION-1:0]          data[0:F_IN_D1-1];
    logic [FEATURE_MAP_ADDRWIDE-1:0]            addr;
    logic                                       ready; 
} st_conv2d1_in;
st_conv2d1_in conv2d1_input;

typedef struct {
    logic                                       valid[0:F_OUT_D1-1];
    logic [FEATURE_MAP_RESOLUTION-1:0]          data[0:F_OUT_D1-1];
    logic [FEATURE_MAP_ADDRWIDE-1:0]            addr;
    logic                                       ready; 
} st_conv2d1_conv2d2;
st_conv2d1_conv2d2 conv2d1_conv2d2, conv2d1_feature_maps;

typedef struct {
    logic                                       valid;
    logic [FEATURE_MAP_RESOLUTION-1 : 0]        data [0: FLATTEN_OUT_SIZE-1];
    logic                                       ready;
} st_flatten_dense1;
st_flatten_dense1 flatten_dense1;

typedef struct {
    logic                                       valid;
    logic [FEATURE_MAP_RESOLUTION-1 : 0]        data[0 : NUM_NEURONS-1];
    logic                                       ready;
} st_dense1_dense2;
st_dense1_dense2 dense1_dense2;

generate
    assign  conv2d1_input.data[0] = cnn_input_data_i;
    assign  conv2d1_input.valid = cnn_input_valid_i;
    assign  conv2d1_input.addr = cnn_input_addr_i;
    assign  conv2d1_input.ready = cnn_input_ready_o;
    
    Conv2D_Wrapper #(
        .F_IN_W                             (F_IN_W1),
        .F_IN_H                             (F_IN_H1),
        .F_IN_D                             (F_IN_D1),
        .KERNEL_SIZE                        (KERNEL_SIZE),
        .F_OUT_W                            (F_OUT_W1),
        .F_OUT_H                            (F_OUT_H1),
        .F_OUT_D                            (F_OUT_D1),
        .INITFILENAMEWEIGHT    				(INITFILE_CONV2D_L1_WEIGHT), 
		.INITFILENAMEBIAS      				(INITFILE_CONV2D_L1_BIAS), 
		.INITFILENAMEM0    					(INITFILE_CONV2D_L1_M0), 
		.INITFILENAMEN     					(INITFILE_CONV2D_L1_N), 
		.INITFILENAMEB     					(INITFILE_CONV2D_L1_B), 
		.INITFILENAMEZ3    					(INITFILE_CONV2D_L1_Z3)
    ) conv2D_wrapper_layer1   (
        .clk_i                              (clk_i),
        .rst_ni                             (rst_ni),
        .feature_in_valid_i                 (conv2d1_input.valid),
        .feature_in_data_i                  (conv2d1_input.data),
        .feature_in_addr_i                  (conv2d1_input.addr),
        .feature_in_ready_o                 (conv2d1_input.ready),
        .feature_out_valid_o                (conv2d1_feature_maps.valid),
        .feature_out_data_o                 (conv2d1_feature_maps.data),
        .feature_out_addr_o                 (conv2d1_feature_maps.addr),
        .feature_out_ready_i                (conv2d1_feature_maps.ready)

    );

//    assign cnn_prediction_valid_o = conv2d1_feature_maps.valid[0];
//    assign cnn_prediction_data_o[0] = conv2d1_feature_maps.data[0];
//    assign cnn_prediction_data_o[1] = conv2d1_feature_maps.addr[7:0];

//assign conv2d1_vis_feature_map_valid_o = conv2d1_feature_maps.valid[0];
//assign conv2d1_vis_feature_map_data_o = conv2d1_feature_maps.data;
//assign conv2d1_vis_feature_map_addr_o = conv2d1_feature_maps.addr;

     Flatten #(
         .F_IN_W                             (F_OUT_W1), 
         .F_IN_H                             (F_OUT_H1), 
         .F_IN_D                             (F_OUT_D1), 
         .FLATTEN_OUT_SIZE                   (FLATTEN_OUT_SIZE))
     flatten ( 
         .clk_i                              (clk_i), 
         .rst_ni                             (rst_ni), 
         .feature_in_valid_i                 (conv2d1_feature_maps.valid[0]),
         .feature_in_data_i                  (conv2d1_feature_maps.data), 
         .feature_in_addr_i                  (conv2d1_feature_maps.addr), 
         .flatten_valid_o                    (flatten_dense1.valid), 
         .flatten_data_o                     (flatten_dense1.data), 
         .flatten_ready_i                    (1'b1)
         );
    
    // ila_flatten flatten_probe (
    //     .clk            (clk_i),
    //     // flatten outputs
    //     .probe0         (flatten_dense1.valid),
    //     .probe1         (flatten_dense1.data[0]),
    //     .probe2         (flatten_dense1.data[1]),
    //     .probe3         (flatten_dense1.data[2]),
    //     .probe4         (flatten_dense1.data[3]),
    //     .probe5         (flatten_dense1.data[4]),
    //     .probe6         (flatten_dense1.data[5]),
    //     .probe7         (flatten_dense1.data[6]),
    //     .probe8         (flatten_dense1.data[7]),
    //     .probe9         (flatten_dense1.data[8]),
    //     .probe10        (flatten_dense1.data[9]),
    //     .probe11        (flatten_dense1.data[10]),
    //     .probe12        (flatten_dense1.data[11]),
    //     .probe13        (flatten_dense1.data[12]),
    //     .probe14        (flatten_dense1.data[13]),
    //     .probe15        (flatten_dense1.data[14])
    // );

     Dense #(
         .NUM_NEURONS                        (NUM_NEURONS), 
         .INPUT_SIZE                         (FLATTEN_OUT_SIZE),
         .INITFILENAMEWEIGHT    				(INITFILE_DENSE_L1_WEIGHT), 
	 	.INITFILENAMEBIAS      				(INITFILE_DENSE_L1_BIAS), 
	 	.INITFILENAMEM0    					(INITFILE_DENSE_L1_M0), 
	 	.INITFILENAMEN     					(INITFILE_DENSE_L1_N), 
	 	.INITFILENAMEB     					(INITFILE_DENSE_L1_B), 
	 	.INITFILENAMEZ3    					(INITFILE_DENSE_L1_Z3)   
     ) dense_l1 ( 
         .clk_i                              (clk_i), 
         .rst_ni                             (rst_ni), 
         .dense_valid_i                      (flatten_dense1.valid),
         .dense_data_i                       (flatten_dense1.data),
         .dense_ready_o                      (flatten_dense1.ready), 
         .dense_valid_o                      (dense1_dense2.valid), 
         .dense_data_o                       (dense1_dense2.data), 
         .dense_ready_i                      (1'b1)
         ); 

// // //    assign dense_l1_vis_feature_map_valid_o = dense1_dense2.valid;
// // //    assign dense_l1_vis_feature_map_data_o  = dense1_dense2.data;
        // dense_l1 output
    // ila_18   probe_dense_l1(
    //     .clk            (clk_i),
    //     .probe0         (dense1_dense2.valid),
    //     .probe1         (dense1_dense2.data[0]),
    //     .probe2         (dense1_dense2.data[1]),
    //     .probe3         (dense1_dense2.data[2]),
    //     .probe4         (dense1_dense2.data[3]),
    //     .probe5         (dense1_dense2.data[4]),
    //     .probe6         (dense1_dense2.data[5]),
    //     .probe7         (dense1_dense2.data[6]),
    //     .probe8         (dense1_dense2.data[7]),
    //     .probe9         (dense1_dense2.data[8]),
    //     .probe10        (dense1_dense2.data[9]),
    //     .probe11        (dense1_dense2.data[10]),
    //     .probe12        (dense1_dense2.data[11]),
    //     .probe13        (dense1_dense2.data[12]),
    //     .probe14        (dense1_dense2.data[13]),
    //     .probe15        (dense1_dense2.data[14])
    // );        

    // ila_18   probe_dense_l11(
    //     .clk            (clk_i),
    //     .probe0         (dense1_dense2.valid),
    //     .probe1         (dense1_dense2.data[15]),
    //     .probe2         (dense1_dense2.data[16]),
    //     .probe3         (dense1_dense2.data[17]),
    //     .probe4         (dense1_dense2.data[18]),
    //     .probe5         (dense1_dense2.data[19]),
    //     .probe6         (dense1_dense2.data[20]),
    //     .probe7         (dense1_dense2.data[21]),
    //     .probe8         (dense1_dense2.data[22]),
    //     .probe9         (dense1_dense2.data[23]),
    //     .probe10        (dense1_dense2.data[24]),
    //     .probe11        (dense1_dense2.data[25]),
    //     .probe12        (dense1_dense2.data[26]),
    //     .probe13        (dense1_dense2.data[27]),
    //     .probe14        (dense1_dense2.data[28]),
    //     .probe15        (dense1_dense2.data[29])
    // ); 

     Dense #(
         .NUM_NEURONS                        (NUM_CLASSES), 
         .INPUT_SIZE                         (NUM_NEURONS),
         .INITFILENAMEWEIGHT    				(INITFILE_DENSE_L2_WEIGHT), 
	 	.INITFILENAMEBIAS      				(INITFILE_DENSE_L2_BIAS), 
	 	.INITFILENAMEM0    					(INITFILE_DENSE_L2_M0), 
	 	.INITFILENAMEN     					(INITFILE_DENSE_L2_N), 
	 	.INITFILENAMEB     					(INITFILE_DENSE_L2_B), 
	 	.INITFILENAMEZ3    					(INITFILE_DENSE_L2_Z3)   
     ) dense_output ( 
         .clk_i                              (clk_i), 
         .rst_ni                             (rst_ni), 
         .dense_valid_i                      (dense1_dense2.valid),
         .dense_data_i                       (dense1_dense2.data),
         .dense_ready_o                      (dense1_dense2.ready),   
         .dense_valid_o                      (cnn_prediction_valid_o), 
         .dense_data_o                       (cnn_prediction_data_o), 
         .dense_ready_i                      (1'b1)
         );   
        
endgenerate 
    
endmodule
