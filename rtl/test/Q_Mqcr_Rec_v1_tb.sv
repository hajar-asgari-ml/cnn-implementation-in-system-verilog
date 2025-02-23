module Q_Mqcr_Rec_v1_tb ();
    
    timeunit 1ns;
    timeprecision 1ps;

    localparam time CLK_PERIOD              = 5ns;
    localparam unsigned RST_CLK_CYCLES      = 10;

    localparam unsigned ACQ_DELAY           = 3ns;
    localparam unsigned APPL_DELAY          = 1ns;
    localparam unsigned NUM_CAR_CHANNELS    = 35;
    localparam unsigned REC_IMAGE_H = 13;
    localparam unsigned REC_IMAGE_W = 29;  
    localparam unsigned TOT_STIMS = REC_IMAGE_W*REC_IMAGE_H + REC_IMAGE_H; 

    typedef struct {
     logic                                           valid[NUM_CAR_CHANNELS-1:0][NUM_CAR_CHANNELS-1:0];
        logic signed [2*FEATURE_MAP_RESOLUTION-1:0]    data[NUM_CAR_CHANNELS-1:0][NUM_CAR_CHANNELS-1:0];
        logic [FEATURE_MAP_ADDRWIDE-1:0]             addr;
        logic                                        ready;
    } st_accqc_r;    
    st_accqc_r acc_qcR;    
    
    typedef struct packed {
     logic                                           valid;
        logic signed [FEATURE_MAP_RESOLUTION-1:0]    data;
        logic [FEATURE_MAP_ADDRWIDE-1:0]             addr;
        logic                                        ready;
    } st_mqc_rec;
    st_mqc_rec mqcRec, mnt_mqcRec_queue[$]; 


    logic                                         clk_i, rst_n;
    bit   signed       [2*FEATURE_MAP_RESOLUTION-1:0]     fin[0:NUM_CAR_CHANNELS-1];    

    int i,j, n_checks, fd; 
    int n_row, n_col; 


    clk_rst_gen #(
        .CLK_PERIOD                 (CLK_PERIOD),
        .RST_CLK_CYCLES             (RST_CLK_CYCLES)
    )   i_clk_rst_gen (

        .clk_o                      (clk),
        .rst_no                     (rst_n)
    );

    Q_Mqcr_Rec_v1 #(
        .NUM_CAR_CHANNELS   (NUM_CAR_CHANNELS), 
        .F_IN_H             (REC_IMAGE_H),
        .F_IN_W             (REC_IMAGE_W), 
        .START_ROW          (6)
    ) qm_qcorr ( 
        .clk_i         (clk), 
        .rst_ni        (rst_n),
        .acc_qcR_data_i (acc_qcR.data),
        .acc_qcR_valid_i (acc_qcR.valid),

        .mqcRec_valid_o (mqcRec.valid), 
        .mqcRec_data_o  (mqcRec.data),
        .mqcRec_addr_o  (mqcRec.addr),
        .mqcRec_ready_i (mqcRec.ready)
    );

    initial begin : application_block
        acc_qcR.valid[0][0] = 1'b0;
        fd = $fopen("../result/Cochlea_v1_proc_acc_qcR_AVA_data_B_L","r");
        n_row = 0;
        n_col = 0;
        while(!$feof(fd)) begin
            $fscanf(fd, " %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d ", fin[0], fin[1], fin[2], fin[3], fin[4], fin[5], fin[6], fin[7], fin[8], fin[9], fin[10], fin[11], fin[12], fin[13], fin[14], fin[15], fin[16], fin[17], fin[18], fin[19], fin[20], fin[21], fin[22], fin[23], fin[24], fin[25], fin[26], fin[27], fin[28]);            
            for (int i = 0; i<NUM_CAR_CHANNELS; i++) begin
                acc_qcR.data[n_row][i] = fin[i];
            end 
            $display("feature in row", n_row);
            n_row += 1;
        end
   
        acc_qcR.valid[0][0] = 1'b1;
        # 10000;
        $stop();

    end

    initial begin: acquire_block 
    st_mqc_rec mnt_mqcRec;
    n_checks = 0;  
        wait (rst_n);
        while (n_checks < TOT_STIMS) begin
            @(posedge clk); 
            if (mqcRec.valid) begin
                    mnt_mqcRec_queue.push_back(mqcRec);
                    n_checks = n_checks + 1;
                    $display("n_checks : %d %d", n_checks, mqcRec.data);
            end              
        end 
        fd = $fopen("../result/Q_Mqcr_Rec_v1_mqcR_AVA_data_B_L","w");
        for (int i=0; i<n_checks ; i++) begin
            mnt_mqcRec = mnt_mqcRec_queue.pop_front();
            $fdisplay(fd, "%d %d ", mnt_mqcRec.addr, mnt_mqcRec.data);        
        end
        #100;
        $fclose();
    end    


endmodule
