(* DONT_TOUCH = "yes" *) // to prevent vivado removing top level ports

import pkg_parameters::*;

module Dense #(
    parameter INPUT_SIZE = 9,
    parameter NUM_NEURONS = 40,
    parameter INITFILENAMEWEIGHT    = "../test/mem/cnn_param_mem/dense_2_weights.txt",
    parameter INITFILENAMEBIAS      = "../test/mem/cnn_param_mem/dense_2_biases.txt",
    parameter INITFILENAMEM0        = "../test/mem/cnn_param_mem/dense_2_m0.txt",
    parameter INITFILENAMEN         = "../test/mem/cnn_param_mem/dense_2_n.txt",
    parameter INITFILENAMEB         = "../test/mem/cnn_param_mem/dense_2_b.txt",
    parameter INITFILENAMEZ3        = "../test/mem/cnn_param_mem/dense_2_z3.txt"    
    )

    (
    // clk and reset
    input   logic                                       clk_i,    // Clock
    input   logic                                       rst_ni,  // Asynchronous reset active low

    // feature in interface
    input   logic                                       dense_valid_i,
    input   logic [FEATURE_MAP_RESOLUTION-1 : 0]        dense_data_i [0 : INPUT_SIZE-1],
    output  logic                                       dense_ready_o,

    //Output interface
    output logic                                        dense_valid_o,
    output logic [FEATURE_MAP_RESOLUTION-1 : 0]         dense_data_o[0 : NUM_NEURONS-1],
    input  logic                                        dense_ready_i
);

    typedef struct{
        logic                                                valid;
        logic [DENSE_BIAS_RESOLUTION-1:0]                    data;
        logic                                                ready;
    } st_vdr32;
    st_vdr32 mac_dwscaling;

    typedef struct{
        logic                                                valid;
        logic [FEATURE_MAP_RESOLUTION-1:0]                    data;
        logic                                                ready;
    } st_vdr8;    
    st_vdr8 Int8_out; 

    typedef struct packed{
        logic [FEATURE_MAP_RESOLUTION-1 : 0]    z3;
        logic [DENSE_BIAS_RESOLUTION-1 : 0]     m0;
        logic [4:0]                             n;
        logic [DENSE_BIAS_RESOLUTION-1 : 0]     b;
    } st_dw_param;
    st_dw_param dwscaling;

    logic [FEATURE_MAP_RESOLUTION-1 : 0]        dense_data_in_d [0 : INPUT_SIZE-1];
    logic [FEATURE_MAP_RESOLUTION-1 : 0]        dense_data_in_q [0 : INPUT_SIZE-1];
    logic                                       mac_din_and_kernel_valid;
    logic [FEATURE_MAP_RESOLUTION-1 : 0]        mac_din_data;

    // //kernel biases interface
    logic [DENSE_BIAS_RESOLUTION-1 : 0]         dense_biases_data[0 : NUM_NEURONS-1];

    logic                                       mem_k_en_d, mem_k_en_q, mem_b_en_d, mem_b_en_q;
    logic [DENSE_WEIGHTS_ADDRWIDE-1:0]          cnt_k;
    logic [KERNEL_WEIGHTS_RESOLUTION-1 : 0]     mac_kernel_data_d , z3;
    logic [KERNEL_BIAS_ADDRWIDE-1:0]            cnt_b;
    logic [KERNEL_BIAS_RESOLUTION-1 : 0]        bias, m0, b;
    logic [4:0]                                 n;
    bit [DENSE_WEIGHTS_ADDRWIDE-1:0]            i_input_d;
    bit [DENSE_WEIGHTS_ADDRWIDE-1:0]            i_input_q;
    bit [DENSE_WEIGHTS_ADDRWIDE-1:0]            i_neuron_d;
    bit [DENSE_WEIGHTS_ADDRWIDE-1:0]            i_neuron_q;

    enum bit [2:0] {IDLE =3'b000, WAIT_FOR_VALID=3'b001, CHECK_NEURON_ID=3'b010, CHECK_INPUT_ADDR=3'b011, WAIT_FOR_INT8_CALC=3'b100, S5=3'b101} state, next_state;


    ram_simple_dual_one_clock #(
        .WIDTH          (KERNEL_WEIGHTS_RESOLUTION),
        .SIZE           (INPUT_SIZE*NUM_NEURONS),
        .ADDRWIDTH      (DENSE_WEIGHTS_ADDRWIDE),
        .INITFILENAME   (INITFILENAMEWEIGHT))
    mem_kernels (
        .clk    (clk_i),
        .ena    (),
        .wea    (1'b0),
        .addra  (),
        .dia    (),
        .enb    (mem_k_en_d),
        .addrb  (cnt_k),
        .dob    (mac_kernel_data_d));

    
    ram_simple_dual_one_clock #(
        .WIDTH          (KERNEL_BIAS_RESOLUTION),
        .SIZE           (NUM_NEURONS),
        .ADDRWIDTH      (DENSE_BIAS_ADDRWIDE),
        .INITFILENAME   (INITFILENAMEBIAS)) 
    mem_biases (
        .clk    (clk_i),
        .ena    (),
        .wea    (1'b0),
        .addra  (),
        .dia    (),
        .enb    (mem_b_en_d),
        .addrb  (cnt_b),
        .dob    (bias));

    ram_simple_dual_one_clock #(
        .WIDTH          (5),
        .SIZE           (1),
        .ADDRWIDTH      (KERNEL_BIAS_ADDRWIDE),
        .INITFILENAME   (INITFILENAMEN)) 
    mem_n (
        .clk    (clk_i),
        .ena    (),
        .wea    (1'b0),
        .addra  (),
        .dia    (),
        .enb    (mem_b_en_d),
        .addrb  (0),
        .dob    (dwscaling.n));

    ram_simple_dual_one_clock #(
        .WIDTH          (KERNEL_BIAS_RESOLUTION),
        .SIZE           (1),
        .ADDRWIDTH      (KERNEL_BIAS_ADDRWIDE),
        .INITFILENAME   (INITFILENAMEM0)) 
    mem_m0 (
        .clk    (clk_i),
        .ena    (),
        .wea    (1'b0),
        .addra  (),
        .dia    (),
        .enb    (mem_b_en_d),
        .addrb  (0),
        .dob    (dwscaling.m0));   

    ram_simple_dual_one_clock #(
        .WIDTH          (KERNEL_BIAS_RESOLUTION),
        .SIZE           (NUM_NEURONS),
        .ADDRWIDTH      (KERNEL_BIAS_ADDRWIDE),
        .INITFILENAME   (INITFILENAMEB)) 
    mem_b (
        .clk    (clk_i),
        .ena    (),
        .wea    (1'b0),
        .addra  (),
        .dia    (),
        .enb    (mem_b_en_d),
        .addrb  (cnt_b),
        .dob    (dwscaling.b)); 

    ram_simple_dual_one_clock #(
        .WIDTH          (KERNEL_WEIGHTS_RESOLUTION),
        .SIZE           (1),
        .ADDRWIDTH      (KERNEL_BIAS_ADDRWIDE),
        .INITFILENAME   (INITFILENAMEZ3)) 
    mem_z3 (
        .clk    (clk_i),
        .ena    (),
        .wea    (1'b0),
        .addra  (),
        .dia    (),
        .enb    (mem_b_en_d),
        .addrb  (0),
        .dob    (dwscaling.z3));  

    assign cnt_k = i_input_d + INPUT_SIZE*i_neuron_d;
    assign cnt_b = i_neuron_d;


    // always_ff @(posedge clk_i or negedge rst_ni) begin : proc_read_mems
    always_ff @(posedge clk_i) begin : proc_read_mems        
        if(~rst_ni) begin
            i_neuron_q                                  <= 0;
            i_input_q                                   <= 0;
            state                                       <= IDLE;
        end else begin
            mem_b_en_q                                   <= mem_b_en_d;
            mem_k_en_q                                  <= mem_k_en_d;
            i_neuron_q                                  <= i_neuron_d;
            i_input_q                                   <= i_input_d;
            state                                       <= next_state;
            dense_data_in_q                             <= dense_data_in_d;
            mac_din_data                                <= dense_data_in_d[i_input_d];

            if(Int8_out.valid) 
                if (i_neuron_q < NUM_NEURONS)
                    dense_data_o[i_neuron_d] <= Int8_out.data; 
            
        end
    end

    always_comb begin 
        next_state                      <= state;
        dense_data_in_d                 <= dense_data_in_q;
        i_neuron_d                      <= i_neuron_q;
        mem_b_en_d                      <= mem_b_en_q;
        mem_k_en_d                      <= mem_k_en_q;
        i_input_d                       <= i_input_q;

        case(state)
            IDLE  :   begin
                i_neuron_d                      <= 12'b0000_0000_0000;
                i_input_d                       <= 12'b0000_0000_0000;
                mem_k_en_d                      <= 1'b0;
                mem_b_en_d                      <= 1'b0;
                dense_valid_o                   <= 1'b0;                               
                next_state                      <= WAIT_FOR_VALID;   
            end

            WAIT_FOR_VALID  :   begin
                i_neuron_d                      <= 12'b0000_0000_0000;
                i_input_d                       <= 12'b0000_0000_0000;
                // dense_valid_o                   <= 1'b0;
                
                if (dense_valid_i) begin                            
                    mem_b_en_d                  <= 1'b1;  
                    mem_k_en_d                  <= 1'b1;
                    mac_din_and_kernel_valid    <= 1'b1;
                    next_state                  <= CHECK_INPUT_ADDR;
                    dense_data_in_d             <= dense_data_i;
                end else begin
                    next_state                  <= WAIT_FOR_VALID;
                    mem_k_en_d                  <= 1'b0; 
                    mem_b_en_d                  <= 1'b0;
                    mac_din_and_kernel_valid    <= 1'b0;
                end
            end                 
    
            CHECK_NEURON_ID  :   begin
                i_input_d                       <= 12'b0000_0000_0000;
                if (i_neuron_q < NUM_NEURONS) begin
                    i_neuron_d                  <= i_neuron_q + 12'b0000_0000_0001;
                    mac_din_and_kernel_valid    <= 1'b1;
                    // dense_valid_o               <= 1'b0;                            
                    next_state                  <= CHECK_INPUT_ADDR;
                end else begin
                    dense_valid_o               <= 1'b1;
                    next_state                  <= IDLE; 
                    mac_din_and_kernel_valid    <= 1'b0;
                    i_neuron_d                  <= 0;
                end

            end 
    
            CHECK_INPUT_ADDR  :   begin
                if(i_input_q < INPUT_SIZE) begin
                    mac_din_and_kernel_valid    <= 1'b1;
                    i_input_d                   <= i_input_q + 12'b0000_0000_0001;    
                    next_state                  <= CHECK_INPUT_ADDR;                
                end else begin
                    mac_din_and_kernel_valid    <= 1'b0;
                    i_input_d                   <= 12'b0000_0000_0000;
                    next_state                  <= WAIT_FOR_INT8_CALC;
                end
            end

            WAIT_FOR_INT8_CALC  :   begin
                if(Int8_out.valid)
                    next_state                  <= CHECK_NEURON_ID;
                else
                    next_state                  <= WAIT_FOR_INT8_CALC;
            end

            default :
                next_state <= IDLE;
        endcase
    end 

    genvar i;
    generate 

        MAC_v4 #(
            .INPUT_BIT_RESOLUTION               (DENSE_WEIGHTS_RESOLUTION),
            .OUTPUT_BIT_RESOLUTION              (DENSE_BIAS_RESOLUTION))
        mac_neurons (
            .clk_i                              (clk_i),
            .rst_ni                             (rst_ni),
            .mac_fin_and_kernel_valid_i         (mac_din_and_kernel_valid),
            .mac_fin_data_i                     (mac_din_data),
            .mac_kernel_data_i                  (mac_kernel_data_d), 
            .mac_kernel_bias_i                  (bias),
            .mac_valid_o                        (mac_dwscaling.valid),
            .mac_data_o                         (mac_dwscaling.data),
            .mac_ready_i                        (1'b1)
            );

        Int32_to_Int8_out #(
            .DWSCALING_IN_RESOLUTION                (DENSE_BIAS_RESOLUTION),
            .DWSCALING_OUT_RESOLUTION               (DENSE_WEIGHTS_RESOLUTION))
        Int32_to_Int8 (
                .clk_i                              (clk_i),
                .rst_ni                             (rst_ni), 
                .dwscaling_valid_i                  (mac_dwscaling.valid), 
                .dwscaling_data_i                   (mac_dwscaling.data),
                .dwscaling_z3_i                     (dwscaling.z3),  
                .dwscaling_m0_i                     (dwscaling.m0), 
                .dwscaling_n_i                      (dwscaling.n),
                .dwscaling_b_i                      (dwscaling.b), 
                .dwscaling_valid_o                  (Int8_out.valid), 
                .dwscaling_data_o                   (Int8_out.data), 
                .dwscaling_ready_i                  (1'b1)
                );
                
    //    ila_2   dense_ila (
    //        .clk        (clk_i),
    //        .probe0     (mac_din_and_kernel_valid),
    //        .probe1     (mac_din_data),
    //        .probe2     (mac_kernel_data_d),
    //        .probe3     (mac_dwscaling.valid),
    //        .probe4     (mac_dwscaling.data),
    //        .probe5     (Int8_out.valid),
    //        .probe6     (Int8_out.data),
    //        .probe7     (i_input_d),
    //        .probe8     (i_neuron_d),
    //        .probe9     (state),
    //        .probe10    (cnt_k),
    //        .probe11    (bias)
    //    );  

    // ila_5 (
    //     .clk    (clk_i),
    //     .probe0 (dense_valid_o),
    //     .probe1 (state),
    //     .probe2 (i_neuron_d)
    // );

    endgenerate
endmodule
