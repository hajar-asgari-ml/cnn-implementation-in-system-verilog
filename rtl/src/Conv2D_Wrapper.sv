(* DONT_TOUCH = "yes" *) // to prevent vivado removing top level ports

import pkg_parameters::*;

module Conv2D_Wrapper #(
    parameter F_IN_W = 29,
    parameter F_IN_H = 13, 
    parameter F_IN_D = 1,   
    parameter KERNEL_SIZE = 3,
    parameter F_OUT_W = 13,
    parameter F_OUT_H = 5,
    parameter F_OUT_D = 4,
    parameter STRIDE = 1,
    parameter PADDING = 0,
    parameter RELU_ENABLE = 1, //enabling relu
    parameter MAXPOOLING_ENABLE = 1, //enabling max-pooling
    parameter INITFILENAMEWEIGHT    = "../test/mem/cnn_param_mem/conv2d_1_weights.txt",
    parameter INITFILENAMEBIAS      = "../test/mem/cnn_param_mem/conv2d_1_biases.txt",
    parameter INITFILENAMEM0        = "../test/mem/cnn_param_mem/conv2d_1_m0.txt",
    parameter INITFILENAMEN         = "../test/mem/cnn_param_mem/conv2d_1_n.txt",
    parameter INITFILENAMEB         = "../test/mem/cnn_param_mem/conv2d_1_b.txt",
    parameter INITFILENAMEZ3        = "../test/mem/cnn_param_mem/conv2d_1_z3.txt"
    )

    (
    // clk and reset
    input   logic clk_i,    // Clock
    input   logic rst_ni,  // Asynchronous reset active low

    // feature in interface
    input   logic                                       feature_in_valid_i,
    input   logic [FEATURE_MAP_RESOLUTION-1 : 0]        feature_in_data_i   [0 : F_IN_D-1],
    input   logic [FEATURE_MAP_ADDRWIDE-1 : 0]          feature_in_addr_i,
    output  logic                                       feature_in_ready_o,

    //Feature out interface
    output logic                                        feature_out_valid_o [0 : F_OUT_D-1],
    output logic [FEATURE_MAP_RESOLUTION-1 : 0]         feature_out_data_o  [0 : F_OUT_D-1],
    output logic [FEATURE_MAP_ADDRWIDE-1 : 0]           feature_out_addr_o,
    input  logic                                        feature_out_ready_i
);


//ram interfaces
localparam unsigned KERNEL_SIZEXKERNEL_SIZE = KERNEL_SIZE*KERNEL_SIZE;

logic                                       kernel_weights_valid[0 : F_OUT_D-1][0 : F_IN_D-1]; // initialize_kernel_weights_ram_i
logic [KERNEL_WEIGHTS_RESOLUTION-1 : 0]     kernel_weights_data;// [0 : F_OUT_D-1][0 : F_IN_D-1];
logic [KERNEL_WEIGHTS_RESOLUTION-1 : 0]     kernel_weights [0 : KERNEL_SIZEXKERNEL_SIZE-1];
logic [KERNEL_WEIGHTS_ADDRWIDE-1 : 0]       kernel_weights_addr;

logic                                       kernel_bias_valid;
logic [KERNEL_BIAS_RESOLUTION-1 : 0]        kernel_biases_data   [0 : F_OUT_D-1];
logic [KERNEL_BIAS_ADDRWIDE-1 : 0]          kernel_biases_addr;

logic [FEATURE_MAP_RESOLUTION-1 : 0]        kernel_dwscaling_z3;
logic [KERNEL_BIAS_RESOLUTION-1 : 0]        kernel_dwscaling_m0  [0 : F_OUT_D-1];
logic [4 : 0]                               kernel_dwscaling_n   [0 : F_OUT_D-1];
logic [KERNEL_BIAS_RESOLUTION-1 : 0]        kernel_dwscaling_b   [0 : F_OUT_D-1];
logic                                       mem_en_k,mem_en_b;

logic [KERNEL_WEIGHTS_ADDRWIDE-1:0]         cnt_k_ram, cnt_k_ram1, cnt_k_ram2;
logic [KERNEL_WEIGHTS_RESOLUTION-1 : 0]     k_d , k_q, z3;
logic [KERNEL_BIAS_ADDRWIDE-1:0]            cnt_b_ram;
logic [KERNEL_BIAS_RESOLUTION-1 : 0]        bias, m0, b;
logic [4:0]                                 n;

bit [3:0]                         cnt_k_d, cnt_k_q;
bit [KERNEL_WEIGHTS_ADDRWIDE-1:0] cnt_ch_in_d, cnt_ch_in_q;
bit [KERNEL_WEIGHTS_ADDRWIDE-1:0] cnt_ch_out_d, cnt_ch_out_q;
bit [KERNEL_WEIGHTS_ADDRWIDE-1:0] cnt1_ch_out_d, count_ch_out_q;

enum bit [2:0] {IDLE =3'b000, INIT_RAMS_S1=3'b001, INIT_RAMS_S2=3'b010, INIT_RAMS_S3=3'b011, INIT_RAMS_DONE=3'b100} state, next_state;

    Conv2D #(
        .F_IN_W                             (F_IN_W),
        .F_IN_H                             (F_IN_H),
        .F_IN_D                             (F_IN_D),
        .KERNEL_SIZE                        (KERNEL_SIZE),
        .F_OUT_W                            (F_OUT_W),
        .F_OUT_H                            (F_OUT_H),
        .F_OUT_D                            (F_OUT_D))

    conv2D_layer   (
        .clk_i                              (clk_i),
        .rst_ni                             (rst_ni),

        .feature_in_valid_i                 (feature_in_valid_i),
        .feature_in_data_i                  (feature_in_data_i),
        .feature_in_addr_i                  (feature_in_addr_i),
        .feature_in_ready_o                 (feature_in_ready_o),

        .kernel_weights_valid_i             (kernel_weights_valid),
        .kernel_weights_data_i              (kernel_weights_data),
        .kernel_weights_addr_i              (kernel_weights_addr), 

        .kernel_biases_data_i               (kernel_biases_data),

        .kernel_dwscaling_m0_i              (kernel_dwscaling_m0), 
        .kernel_dwscaling_n_i               (kernel_dwscaling_n),
        .kernel_dwscaling_b_i               (kernel_dwscaling_b),
        .kernel_dwscaling_z3_i              (kernel_dwscaling_z3),

        .feature_out_valid_o                (feature_out_valid_o),
        .feature_out_data_o                 (feature_out_data_o),
        .feature_out_addr_o                 (feature_out_addr_o),
        .feature_out_ready_i                (feature_out_ready_i));

    ram_simple_dual_one_clock #(
        .WIDTH          (KERNEL_WEIGHTS_RESOLUTION),
        .SIZE           (KERNEL_SIZEXKERNEL_SIZE*F_OUT_D*F_IN_D),
        .ADDRWIDTH      (KERNEL_WEIGHTS_ADDRWIDE),
        .INITFILENAME   (INITFILENAMEWEIGHT))
    mem_kernels (
        .clk    (clk_i),
        .ena    (),
        .wea    (1'b0),
        .addra  (),
        .dia    (),
        .enb    (mem_en_k),
        .addrb  (cnt_k_ram),
        .dob    (k_d));
   
    ram_simple_dual_one_clock #(
        .WIDTH          (KERNEL_BIAS_RESOLUTION),
        .SIZE           (F_OUT_D),
        .ADDRWIDTH      (KERNEL_BIAS_ADDRWIDE),
        .INITFILENAME   (INITFILENAMEBIAS)) 
    mem_biases (
        .clk    (clk_i),
        .ena    (),
        .wea    (1'b0),
        .addra  (),
        .dia    (),
        .enb    (mem_en_b),
        .addrb  (cnt_b_ram),
        .dob    (bias));

    ram_simple_dual_one_clock #(
        .WIDTH          (5),
        .SIZE           (F_OUT_D),
        .ADDRWIDTH      (KERNEL_BIAS_ADDRWIDE),
        .INITFILENAME   (INITFILENAMEN)) 
    mem_n (
        .clk    (clk_i),
        .ena    (),
        .wea    (1'b0),
        .addra  (),
        .dia    (),
        .enb    (mem_en_b),
        .addrb  (cnt_b_ram),
        .dob    (n));

    ram_simple_dual_one_clock #(
        .WIDTH          (KERNEL_BIAS_RESOLUTION),
        .SIZE           (F_OUT_D),
        .ADDRWIDTH      (KERNEL_BIAS_ADDRWIDE),
        .INITFILENAME   (INITFILENAMEM0)) 
    mem_m0 (
        .clk    (clk_i),
        .ena    (),
        .wea    (1'b0),
        .addra  (),
        .dia    (),
        .enb    (mem_en_b),
        .addrb  (cnt_b_ram),
        .dob    (m0));   

    ram_simple_dual_one_clock #(
        .WIDTH          (KERNEL_BIAS_RESOLUTION),
        .SIZE           (F_OUT_D),
        .ADDRWIDTH      (KERNEL_BIAS_ADDRWIDE),
        .INITFILENAME   (INITFILENAMEB)) 
    mem_b (
        .clk    (clk_i),
        .ena    (),
        .wea    (1'b0),
        .addra  (),
        .dia    (),
        .enb    (mem_en_b),
        .addrb  (cnt_b_ram),
        .dob    (b)); 

    ram_simple_dual_one_clock #(
        .WIDTH          (KERNEL_WEIGHTS_RESOLUTION),
        .SIZE           (1),
        .ADDRWIDTH      (KERNEL_WEIGHTS_ADDRWIDE),
        .INITFILENAME   (INITFILENAMEZ3)) 
    mem_z3 (
        .clk    (clk_i),
        .ena    (),
        .wea    (1'b0),
        .addra  (),
        .dia    (),
        .enb    (mem_en_b),
        .addrb  (0),
        .dob    (z3));                  
    
always_ff @(posedge clk_i) begin : proc_read_mems    
    if(~rst_ni) begin
        cnt_k_q         <= 0;
        cnt_ch_in_q     <= 0;
        cnt_ch_out_q    <= 0;
        count_ch_out_q  <= 0;
        state           <= IDLE;        
    end else begin
        cnt_k_q         <= cnt_k_d;
        cnt_ch_in_q     <= cnt_ch_in_d;
        cnt_ch_out_q    <= cnt_ch_out_d;
        count_ch_out_q  <= cnt1_ch_out_d;
        k_q             <= k_d;
        state           <= next_state;
        if (mem_en_k) 
            kernel_weights_valid[cnt_ch_out_d][cnt_ch_in_d] <= 1'b1;
        else  
            kernel_weights_valid[cnt_ch_out_d][cnt_ch_in_d] <= 1'b0;
        kernel_weights_valid[cnt_ch_out_d][cnt_ch_in_d-1]   <= 1'b0; 

        kernel_biases_data[count_ch_out_q-1]    <= bias;
        kernel_dwscaling_m0[count_ch_out_q-1]   <= m0;
        kernel_dwscaling_n [count_ch_out_q-1]   <= n;
        kernel_dwscaling_b[count_ch_out_q-1]    <= b;
        kernel_dwscaling_z3                     <= z3;       
    end
end

assign cnt_k_ram = cnt_ch_in_q + cnt_k_ram1 + KERNEL_SIZEXKERNEL_SIZE*F_IN_D*cnt_ch_out_q;
assign cnt_b_ram = count_ch_out_q;
assign kernel_weights_data = k_q;


always_comb begin 
    next_state  <= state;
    cnt_ch_out_d    <= cnt_ch_out_q;
    cnt_ch_in_d     <= cnt_ch_in_q;

    case(state)
        IDLE  :   begin 
            cnt_k_d         <= 0;
            cnt_ch_in_d     <= 0;
            cnt_ch_out_d    <= 0;
            mem_en_k        <= 1'b1;
            mem_en_b        <= 1'b0;
            next_state      <= INIT_RAMS_S1;
        end

        INIT_RAMS_S1  :   begin
            kernel_weights_addr = cnt_k_q - 2;
            cnt_k_ram1 = F_IN_D*cnt_k_q;
            kernel_weights[cnt_k_d-1] <= k_d;    
            if (cnt_k_q < KERNEL_SIZEXKERNEL_SIZE+1) begin
                cnt_k_d                 <= cnt_k_q + 1;
                mem_en_k                <= 1'b1;
                next_state              <= INIT_RAMS_S1;
                // cnt_ch_in_d             <= cnt_ch_in_q;
                // cnt_ch_out_d            <= cnt_ch_out_q;
            end else begin 
                cnt_k_d                 <= 0;
                if (cnt_ch_in_q < F_IN_D) begin 
                    cnt_ch_in_d         <= cnt_ch_in_q + 12'b0000_0000_0001;
                    // cnt_ch_out_d        <= cnt_ch_out_q;
                    next_state          <= INIT_RAMS_S1;
                end else begin 
                    if (cnt_ch_out_q < F_OUT_D) begin
                        next_state      <= INIT_RAMS_S1; 
                        cnt_ch_out_d    <= cnt_ch_out_q + 12'b0000_0000_0001; 
                        cnt_ch_in_d     <= 0;
                        mem_en_k        <= 1'b1;                 
                    end else begin
                        next_state      <= INIT_RAMS_S2;
                        // cnt_ch_out_d    <= cnt_ch_out_q;
                        // cnt_ch_in_d     <= cnt_ch_in_q;
                        mem_en_k        <= 1'b0; 
                    end                             
                end                        
            end
        end

        INIT_RAMS_S2  :   begin
            next_state <= INIT_RAMS_S3;
        end 

        INIT_RAMS_S3  :   begin           
            if (count_ch_out_q < F_OUT_D + 2) begin
                cnt1_ch_out_d   <= count_ch_out_q + 12'b0000_0000_0001;
                mem_en_b        <= 1'b1;
                next_state      <= INIT_RAMS_S3;
            end else begin 
                mem_en_b        <= 1'b0;
                next_state      <= INIT_RAMS_DONE;
            end    
        end

        INIT_RAMS_DONE  :   begin
            next_state <= INIT_RAMS_DONE;
        end

        default:
            next_state <=IDLE;
    endcase  
end

endmodule
