(* DONT_TOUCH = "yes" *) // to prevent vivado removing top level ports

import pkg_parameters::*;

module Conv2D #(
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
    parameter MAXPOOLING_ENABLE = 1 //enabling max-pooling
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

    //kernel interface
    input   logic                                       kernel_weights_valid_i [0 : F_OUT_D-1][0 : F_IN_D-1], // initialize_kernel_weights_ram_i
    input   logic [KERNEL_WEIGHTS_RESOLUTION-1 : 0]     kernel_weights_data_i,// [0 : F_OUT_D-1][0 : F_IN_D-1], 
    input   logic [KERNEL_WEIGHTS_ADDRWIDE-1 : 0]       kernel_weights_addr_i,
    input   logic [KERNEL_WEIGHTS_ADDRWIDE-1 : 0]       k_index_i,
    input   logic [KERNEL_WEIGHTS_ADDRWIDE-1 : 0]       fin_index_i,
    input   logic [KERNEL_WEIGHTS_ADDRWIDE-1 : 0]       fout_index_i,

    // input   logic                                       kernel_bias_valid_i,
    input   logic [KERNEL_BIAS_RESOLUTION-1 : 0]        kernel_biases_data_i   [0 : F_OUT_D-1],
    // input   logic [KERNEL_BIAS_ADDRWIDE-1 : 0]          kernel_biases_addr_i,

    //kernel down scaling parameters
    input   logic [FEATURE_MAP_RESOLUTION-1 : 0]        kernel_dwscaling_z3_i,
    input   logic [KERNEL_BIAS_RESOLUTION-1 : 0]        kernel_dwscaling_m0_i  [0 : F_OUT_D-1],
    input   logic [4 : 0]                               kernel_dwscaling_n_i   [0 : F_OUT_D-1],
    input   logic [KERNEL_BIAS_RESOLUTION-1 : 0]        kernel_dwscaling_b_i  [0 : F_OUT_D-1],

    //Feature out interface
    output logic                                        feature_out_valid_o [0 : F_OUT_D-1],
    output logic [FEATURE_MAP_RESOLUTION-1 : 0]         feature_out_data_o  [0 : F_OUT_D-1],
    output logic [FEATURE_MAP_ADDRWIDE-1 : 0]           feature_out_addr_o,
    input  logic                                        feature_out_ready_i
);

localparam END_COL_F_IN_W = F_IN_W - KERNEL_SIZE - 2;
//ram interfaces
// logic                                       read_ram_feature_in_en;
logic                                       read_rams_kernel_fin_en_d;
logic                                       read_rams_kernel_fin_en_q;

logic [FEATURE_MAP_ADDRWIDE-1 : 0]          read_ram_feature_in_addr;
logic [FEATURE_MAP_RESOLUTION-1 : 0]        read_ram_feature_in_data[0:F_IN_D-1];

logic [KERNEL_WEIGHTS_RESOLUTION-1 : 0]     read_ram_kernel_weight_data [0 : F_OUT_D-1][0 : F_IN_D-1];
logic [KERNEL_WEIGHTS_ADDRWIDE-1 : 0]       read_ram_kernel_weight_addr, kernel_weight_addr;

logic                                       kernel_weights_valid[0:F_OUT_D-1][0:F_IN_D-1];

logic [KERNEL_BIAS_RESOLUTION-1 : 0]        kernel_biases [0 : F_OUT_D-1];

//other interfaces
// logic                                       mac_fin_and_kernel_valid; // read from kernel and feature in rams

logic                                       mac_acc_valid [0: F_OUT_D-1][0: F_IN_D-1];
logic [KERNEL_BIAS_RESOLUTION-1:0]          mac_acc_data  [0: F_OUT_D-1][0: F_IN_D-1];

logic                                       acc_dwscaling_valid [0: F_OUT_D-1];
logic [KERNEL_BIAS_RESOLUTION-1:0]          acc_dwscaling_data  [0: F_OUT_D-1];

logic                                       Int8_out_valid [0 : F_OUT_D-1];
logic [KERNEL_WEIGHTS_RESOLUTION-1 : 0]     Int8_out_data [0:F_OUT_D-1];

logic [FEATURE_MAP_RESOLUTION-1 : 0]        feature_maps_data [0: F_OUT_D-1];
logic                                       feature_maps_valid [0 : F_OUT_D-1];

logic                                       load_mx_valid;
logic                                       exe_mx_ready_d, exe_mx_ready_q;

logic                                       mx_valid[0:F_OUT_D-1];
logic [FEATURE_MAP_RESOLUTION-1 : 0]        mx_data[0:F_OUT_D-1];

enum int unsigned {IDLE=0 , RECEIVE_COMPLETE_IMG=1, CHECK_F_COL=2, CHECK_MX_ROW=3, CHECK_KERNEL_ADDR=4, WAIT_ONE_CLOCK=5, TRANSOTION_BASED_ON_MX_STATUS=6, CHECK_F_ROW=7, MOVE_TO_IDLE=8, INC_F_ROW=9} state, next_state;

bit [FEATURE_MAP_ADDRWIDE-1:0]               count_d, count_q;
bit [FEATURE_MAP_ADDRWIDE-1:0]               pointer_f_out;
bit [FEATURE_MAP_ADDRWIDE-1:0]               pointer_f_in;
bit [FEATURE_MAP_ADDRWIDE-1:0]               pointer_f_in_p1_d, pointer_f_in_p1_q;
bit [FEATURE_MAP_ADDRWIDE-1:0]               pointer_f_in_p2_d, pointer_f_in_p2_q;
bit [FEATURE_MAP_ADDRWIDE-1:0]               k_row_d, k_col_d;
bit [FEATURE_MAP_ADDRWIDE-1:0]               k_row_q, k_col_q;
bit [FEATURE_MAP_ADDRWIDE-1:0]               f_row_d, f_col_d;
bit [FEATURE_MAP_ADDRWIDE-1:0]               f_row_q, f_col_q;
bit [FEATURE_MAP_ADDRWIDE-1:0]               mx_row_d, mx_col_d;
bit [FEATURE_MAP_ADDRWIDE-1:0]               mx_row_q, mx_col_q;

always_ff @(posedge clk_i) begin    
    if(~rst_ni) begin
        state <= IDLE;
    end else begin
        state                       <=      next_state;
        count_q                     <=      count_d;
        k_col_q                     <=      k_col_d;
        k_row_q                     <=      k_row_d;
        f_col_q                     <=      f_col_d;
        f_row_q                     <=      f_row_d;
        mx_col_q                    <=      mx_col_d;
        mx_row_q                    <=      mx_row_d;
        exe_mx_ready_q              <=      exe_mx_ready_d; 
        pointer_f_in_p1_q           <=      pointer_f_in_p1_d;
        pointer_f_in_p2_q           <=      pointer_f_in_p2_d;   
        read_rams_kernel_fin_en_q   <=      read_rams_kernel_fin_en_d; 
    end
end

always_comb begin : proc_change_state
    next_state                  <= state;
    count_d                     <= count_q;
    f_row_d                     <= f_row_q; 
    f_col_d                     <= f_col_q;
    mx_col_d                    <= mx_col_q;
    mx_row_d                    <= mx_row_q; 
    pointer_f_in_p1_d           <= pointer_f_in_p1_q;
    pointer_f_in_p2_d           <= pointer_f_in_p2_q;
    read_rams_kernel_fin_en_d   <= read_rams_kernel_fin_en_q; 

    case (state)
        IDLE  :     begin
            count_d                     <= 0;                    
            read_rams_kernel_fin_en_d   <= 1'b0;                  
            load_mx_valid               <= 1'b0;
            exe_mx_ready_d              <= 1'b0; 
            pointer_f_in_p1_d           <= 0;
            pointer_f_in_p2_d           <= 0;
            if (feature_in_valid_i) begin
                next_state                  <= RECEIVE_COMPLETE_IMG;
            end else begin
                next_state                  <= IDLE;
            end
        end

        RECEIVE_COMPLETE_IMG  :   begin
            f_col_d                     <= 0;
            k_row_d                     <= 0;
            k_col_d                     <= 0; 
            f_row_d                     <= 0;
            mx_row_d                    <= 0;
            mx_col_d                    <= 0; 
            kernel_weight_addr          <= 0;
            load_mx_valid               <= 1'b0;
            exe_mx_ready_d              <= 1'b0; 
            if (count_q < F_IN_H*F_IN_W-1) begin
                next_state              <= RECEIVE_COMPLETE_IMG;
                if (feature_in_valid_i) begin
                    count_d             <= count_q + 1;
                end else 
                    count_d             <= count_q;
            end else begin 
                count_d                 <= 0;
                next_state              <= CHECK_MX_ROW;  
                              
            end 
        end

        CHECK_F_COL  :   begin
            k_row_d                     <= 0;
            k_col_d                     <= 0;
            mx_row_d                    <= 0;
            mx_col_d                    <= 0;                     
            load_mx_valid               <= 1'b0;
            exe_mx_ready_d              <= 1'b0; 
            count_d                     <= count_q + 1;
            pointer_f_in_p1_d           <= f_col_d+mx_col_d;                  
            pointer_f_in_p2_d           <= (f_row_d+mx_row_d) * F_IN_W;
            kernel_weight_addr          <= k_col_d + KERNEL_SIZE*k_row_d;            
            if (f_col_q  + 12'b000000000010 < F_IN_W - KERNEL_SIZE )  begin
                f_col_d                 <= f_col_q + 12'b0000_0000_0010;
                next_state              <= CHECK_MX_ROW;
            end else begin
                f_col_d                 <= 0;
                next_state              <= INC_F_ROW;              
            end
        end

        INC_F_ROW  :   begin
            f_row_d                     <= f_row_q + 12'b0000_0000_0010;
            pointer_f_in_p2_d           <= (f_row_d+mx_row_d) * F_IN_W;
            pointer_f_in_p1_d           <= pointer_f_in_p1_q;
            next_state                  <= CHECK_MX_ROW;
        end

        CHECK_MX_ROW  :   begin                                                   
            if (f_row_q < F_IN_H-KERNEL_SIZE+1) begin
                if (mx_row_q < 2) begin
                    next_state          <= CHECK_KERNEL_ADDR;
                    exe_mx_ready_d      <= 1'b0;                        
                end else begin 
                    next_state          <= TRANSOTION_BASED_ON_MX_STATUS;
                    exe_mx_ready_d      <= 1'b1;  
                end
            end else 
                next_state              <= MOVE_TO_IDLE; 
        end     

        CHECK_KERNEL_ADDR  :   begin
            read_rams_kernel_fin_en_d   <= 1'b1;
            if (k_row_q < KERNEL_SIZE) begin
                next_state              <= CHECK_KERNEL_ADDR;
                if (k_col_q < KERNEL_SIZE-1) begin
                    k_row_d             <= k_row_q;                                    
                    k_col_d             <= k_col_q + 1; 
                end else begin
                    k_row_d             <= k_row_q + 1;
                    k_col_d             <= 0;                            
                end             
            end else begin 
                next_state              <= WAIT_ONE_CLOCK;                               
            end
        end

        WAIT_ONE_CLOCK  :   begin 
            next_state                  <= TRANSOTION_BASED_ON_MX_STATUS;
            read_rams_kernel_fin_en_d   <= 1'b0;                 
        end                

        TRANSOTION_BASED_ON_MX_STATUS  :   begin                    
            if (Int8_out_valid[0]) begin // 
                next_state              <= CHECK_F_ROW;                    
                load_mx_valid           <= 1'b1;
            end else if (exe_mx_ready_q) begin
                next_state              <= CHECK_F_COL;
                load_mx_valid           <= 1'b0;
            end else begin
                next_state              <= TRANSOTION_BASED_ON_MX_STATUS;  
                load_mx_valid           <= 1'b0;                 
            end 
        end 

        CHECK_F_ROW  :   begin
            if (f_row_q < F_IN_H-KERNEL_SIZE) begin
                if (mx_row_q < 2) begin
                    next_state          <= CHECK_MX_ROW;
                    if ((mx_col_q < 1)  ) begin
                        mx_col_d        <= mx_col_q + 1;
                        mx_row_d        <= mx_row_q;
                    end else begin
                        mx_col_d        <= 0;
                        mx_row_d        <= mx_row_q + 1;
                    end                                                                         
                end else begin
                    next_state          <= CHECK_F_COL;                                                 
                end
            end else begin 
                next_state              <= MOVE_TO_IDLE; 
                mx_col_d                <= 0;
                mx_row_d                <= mx_row_q;                           
            end
            k_row_d                     <= 0;
            k_col_d                     <= 0;  
            load_mx_valid               <= 1'b0;
            pointer_f_in_p1_d           <= f_col_d+mx_col_d;                  
            pointer_f_in_p2_d           <= (f_row_d+mx_row_d) * F_IN_W; 
            // read_rams_kernel_fin_en_d   <= read_rams_kernel_fin_en_q;                                                                           
        end

        MOVE_TO_IDLE  :   begin
            next_state <= IDLE;
        end

        default :
            next_state <= IDLE;
    endcase    
end


assign read_ram_kernel_weight_addr      = k_col_q + KERNEL_SIZE*k_row_q;
assign pointer_f_in                     = pointer_f_in_p1_d + pointer_f_in_p2_d;
assign pointer_f_out                    = pointer_f_in - ((KERNEL_SIZE-1) * f_row_q);
assign read_ram_feature_in_addr         = pointer_f_in + (k_row_q * F_IN_W) + k_col_q;

    genvar i,j,k, l, m, n, o;
    generate
         for (k = 0; k < F_OUT_D; k=k+1) begin
            for (l = 0; l < F_IN_D; l = l+1) begin
                ram_simple_dual_one_clock #(
                    .WIDTH                              (KERNEL_WEIGHTS_RESOLUTION),
                    .SIZE                               (KERNEL_SIZE * KERNEL_SIZE),
                    .ADDRWIDTH                          (KERNEL_WEIGHTS_ADDRWIDE))
                kernel_weight_memory (
                    .clk                                (clk_i),
                    .ena                                (kernel_weights_valid_i[k][l]),
                    .wea                                (1'b1),
                    .addra                              (kernel_weights_addr_i),
                    .dia                                (kernel_weights_data_i),//[fout_index_i][fin_index_i]),
                    .enb                                (read_rams_kernel_fin_en_d),
                    .addrb                              (read_ram_kernel_weight_addr),
                    .dob                                (read_ram_kernel_weight_data[k][l])
                    );
            end
        end

            // /////biases
        assign kernel_biases = kernel_biases_data_i;

            // // feature in memory 
        for (m=0; m<F_IN_D; m=m+1) begin
            ram_simple_dual_one_clock #(
                    .WIDTH                              (FEATURE_MAP_RESOLUTION),
                    .SIZE                               (F_IN_W*F_IN_H),
                    .ADDRWIDTH                          (FEATURE_MAP_ADDRWIDE) )
            feature_in_memory (
                    .clk                                (clk_i),
                    .ena                                (feature_in_valid_i),
                    .wea                                (1'b1),
                    .addra                              (feature_in_addr_i),
                    .dia                                (feature_in_data_i[m]),
                    .enb                                (read_rams_kernel_fin_en_d),
                    .addrb                              (read_ram_feature_in_addr),
                    .dob                                (read_ram_feature_in_data[m])               
                    );
        end

        for (i=0; i<F_OUT_D; i=i+1) begin
            for (j=0; j<F_IN_D; j=j+1) begin
                MAC_v4 #(
                    .INPUT_BIT_RESOLUTION               (KERNEL_WEIGHTS_RESOLUTION),
                    .OUTPUT_BIT_RESOLUTION              (KERNEL_BIAS_RESOLUTION))
                macs_s1 (
                    .clk_i                              (clk_i),
                    .rst_ni                             (rst_ni),
                    .mac_fin_and_kernel_valid_i         (read_rams_kernel_fin_en_d),
                    .mac_fin_data_i                     (read_ram_feature_in_data[j]),
                    .mac_kernel_data_i                  (read_ram_kernel_weight_data[i][j]),
                    .mac_kernel_bias_i                  (0),
                    .mac_valid_o                        (mac_acc_valid[i][j]),
                    .mac_data_o                         (mac_acc_data[i][j]),
                    .mac_ready_i                        (1'b1)
                    );
            end 
        end

        for (n=0; n<F_OUT_D; n=n+1) begin
            ACC #(
                .ACC_RESOLUTION                         (KERNEL_BIAS_RESOLUTION),
                .ACC_DATA_DEPTH                         (F_IN_D))
            acc_feature_maps (
                    .clk_i                              (clk_i),
                    .rst_ni                             (rst_ni),
                    .acc_valid_i                        (mac_acc_valid[n]),
                    .acc_data_i                         (mac_acc_data [n]),
                    .kernel_bias_i                      (kernel_biases[n]),
                    .acc_valid_o                        (acc_dwscaling_valid[n]),
                    .acc_data_o                         (acc_dwscaling_data[n]),
                    .acc_ready_i                        (1'b1)
                    );
        end 

        for (n=0; n<F_OUT_D; n=n+1) begin
            Int32_to_Int8_out #(
                .DWSCALING_IN_RESOLUTION                (KERNEL_BIAS_RESOLUTION),
                .DWSCALING_OUT_RESOLUTION               (KERNEL_WEIGHTS_RESOLUTION))
            Int32_to_Int8 (
                    .clk_i                              (clk_i),
                    .rst_ni                             (rst_ni), 
                    .dwscaling_valid_i                  (acc_dwscaling_valid[n]), 
                    .dwscaling_data_i                   (acc_dwscaling_data[n]),
                    .dwscaling_z3_i                     (kernel_dwscaling_z3_i),  
                    .dwscaling_m0_i                     (kernel_dwscaling_m0_i[n]), 
                    .dwscaling_n_i                      (kernel_dwscaling_n_i[n]),
                    .dwscaling_b_i                      (kernel_dwscaling_b_i[n]), 
                    .dwscaling_valid_o                  (Int8_out_valid[n]), 
                    .dwscaling_data_o                   (Int8_out_data[n]), 
                    .dwscaling_ready_i                  (1'b1)
                    );
        end    

        for (o=0; o<F_OUT_D; o=o+1) begin
            // assign feature_maps_valid [o]               = Int8_out_valid[o];
            // assign feature_maps_data [o]                = Int8_out_data [o];

            MaxPooling2D_signed #( 
                    .MX_RESOLUTION                          (KERNEL_WEIGHTS_RESOLUTION))
            mx ( 
                    .clk_i                              (clk_i), 
                    .rst_ni                             (rst_ni), 
                    .load_mx_valid_i                    (load_mx_valid), 
                    .load_mx_data_i                     (Int8_out_data [o]), 
                    .exe_mx_valid_o                     (mx_valid[o]), 
                    .exe_mx_data_o                      (mx_data[o]), 
                    .exe_mx_ready_i                     (exe_mx_ready_d)
                    );

            if (MAXPOOLING_ENABLE == 1) begin
                assign feature_out_data_o[o]            = mx_data[o];
                // assign feature_out_valid_o[o]           = mx_valid[o];                
            end else begin
                assign feature_out_data_o[o]            = feature_maps_data[o];
                // assign feature_out_valid_o[o]           = feature_maps_valid[o];                
            end
            // assign feature_out_data_o[o]                = mx_data[o];
            // assign feature_out_valid_o[o]               = mx_valid[o];
        end 
        // there is a bug in producing mx_valid while reading it as feature_out_valid_o so temporary I use exe_mx_ready_q as output 
        assign feature_out_valid_o[0]               = exe_mx_ready_q;

        if (MAXPOOLING_ENABLE == 1) begin
            assign feature_out_addr_o                   = count_d;
        end else begin
            assign feature_out_addr_o                   = pointer_f_out;
        end

        // ila_0  conv2D_prob (
        //     .clk        (clk_i),
        //     .probe0     (acc_dwscaling_valid[0]),
        //     .probe1     (acc_dwscaling_data[0]),
        //     .probe2     (Int8_out_valid[0]),
        //     .probe3     (Int8_out_data[0]),
        //     .probe4     (mx_valid[0]),
        //     .probe5     (mx_data[0]),
        //     .probe6     (exe_mx_ready_q),
        //     .probe7     (mac_acc_valid[0][0]),
        //     .probe8     (mac_acc_data[0][0]),
        //     .probe9     (read_ram_feature_in_data[0]),
        //     .probe10    (read_ram_kernel_weight_data[0][0]),
        //     .probe11    (read_rams_kernel_fin_en_d),
        //     .probe12    (state),
        //     .probe13    (f_row_d),
        //     .probe14    (f_col_d),
        //     .probe15    (mx_row_d),
        //     .probe16    (mx_col_d),
        //     .probe17    (pointer_f_in_p1_d),
        //     .probe18    (pointer_f_in_p2_d),
        //     .probe19    (k_row_d),
        //     .probe20    (k_col_d),
        //     .probe21    (count_d)
        //  );
        
    endgenerate
endmodule
