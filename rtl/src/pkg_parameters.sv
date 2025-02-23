//+++++++++++++++++++++++++++++++++++++++++++++++++
//   Package Declaration
//+++++++++++++++++++++++++++++++++++++++++++++++++
package pkg_parameters;

  //=================================================
  // Clock
  //=================================================
  parameter real CLK_FREQ_MHz = 100;
  parameter NUM_CLK_RECEIVER_CYCLES = CLK_FREQ_MHz * 10**6;
  
  //=================================================
  // LED
  //=================================================
  parameter LED_OK_ON = 0; // active low
  parameter LED_OK_OFF = 1; 

  //=================================================
  // Input Sound
  //=================================================
  parameter INPUT_SOUND_RESOLUTION = 16;
  parameter SAMPLING_RATE = 48; //kHz
  parameter SAMPLE_CLOCK = 2083; // = 100Mhz / 48kHz 
  parameter INPUT_SOUND_ADDRWIDE = 12;
  
  //=================================================
  // CAR
  //=================================================
  parameter TIME_WINDOW = 10;
  parameter SOUND_SOURCE_LENGHT = SAMPLING_RATE*TIME_WINDOW;
  parameter CAR_NUM_CHANNELS = 16;
  parameter CAR_FRC_BIT_RESOLUTION = 10;
  parameter CAR_INT_BIT_RESOLUTION = 25;
  parameter CAR_NUM_BIT_RESOLUTION_PARAM = 1+CAR_FRC_BIT_RESOLUTION;
  parameter CAR_NUM_BIT_RESOLUTION_DATA = 1+CAR_INT_BIT_RESOLUTION+CAR_FRC_BIT_RESOLUTION;
  parameter CAR_ADDR_WIDTH = 6;
  
//  parameter REC_EXTRACT_START_ROW = 5; // int(np.ceil(REC_IMG_H*rec_factor)-1)        
  parameter REC_IMG_H = 9;
  parameter REC_IMG_W = 12;
  parameter REC_EXTRACT_START_ROW = (REC_IMG_H-1)/2;        


  //=================================================
  // CNN:: Hyper parameters
  //=================================================   
  parameter F_IN_W1             = REC_IMG_W;
  parameter F_IN_H1             = REC_IMG_H;
  parameter F_IN_D1             = 1;
  parameter F_OUT_W1            = (F_IN_W1-2)/2;
  parameter F_OUT_H1            = (F_IN_H1-2)/2;
  parameter F_OUT_D1            = 1;
  // parameter F_IN_W2             = F_OUT_W1;
  // parameter F_IN_H2             = F_OUT_H1;
  // parameter F_IN_D2             = F_OUT_D1;
  // parameter F_OUT_W2            = 5;
  // parameter F_OUT_H2            = 1;
  // parameter F_OUT_D2            = 10; 
  parameter KERNEL_SIZE         = 3;
  parameter STRIDE              = 2;
  parameter PADDING             = 0;
  parameter NUM_NEURONS         = 65; 
  parameter NUM_CLASSES         = 2;
  parameter FLATTEN_IN_WXH      = F_OUT_W1*F_OUT_H1;
  parameter FLATTEN_OUT_SIZE    = FLATTEN_IN_WXH*F_OUT_D1;  
  
  //=================================================
  // CNN:: Conv2D Resolutions
  //================================================= 
  parameter RELU_ENABLE = 0;
  parameter MAXPOOLING_ENABLE = 1;
  parameter INPUT_BIT_RESOLUTION = 8;
  parameter FEATURE_MAP_RESOLUTION = 8;
  parameter FEATURE_MAP_ADDRWIDE = 12;  
  parameter KERNEL_WEIGHTS_RESOLUTION = 8;
  parameter KERNEL_WEIGHTS_ADDRWIDE = 12;
  parameter KERNEL_BIAS_RESOLUTION = 32;
  parameter KERNEL_BIAS_ADDRWIDE = 12;

  //=================================================
  // CNN:: Dense layer Resolutions
  //=================================================
  parameter DENSE_WEIGHTS_RESOLUTION = 8;
  parameter DENSE_WEIGHTS_ADDRWIDE = 12;
  parameter DENSE_BIAS_RESOLUTION = 32;
  parameter DENSE_BIAS_ADDRWIDE = 12;


  // //========================================================
  // // RAM INIT FILE LOCATIONS FOR BEHAVIOURAL SIMULATIONS
  // //========================================================
  // parameter INITFILE_Z1_INIT               = "../test/mem/para_mem_FRC10/z1_init.txt";
  // parameter INITFILE_Z2_INIT               = "../test/mem/para_mem_FRC10/z2_init.txt";
  // parameter INITFILE_Y_INIT                = "../test/mem/para_mem_FRC10/y_init.txt";
  // parameter INITFILE_A0                    = "../test/mem/para_mem_FRC10/a0.txt";
  // parameter INITFILE_C0                    = "../test/mem/para_mem_FRC10/c0.txt";
  // parameter INITFILE_R                     = "../test/mem/para_mem_FRC10/r.txt";
  // parameter INITFILE_G                     = "../test/mem/para_mem_FRC10/g.txt";
  // parameter INITFILE_H                     = "../test/mem/para_mem_FRC10/h.txt";
  // parameter INITFILE_CONV2D_L1_WEIGHT      = "../test/mem/cnn_param_mem/conv2d_1_weights.txt";
  // parameter INITFILE_CONV2D_L1_BIAS        = "../test/mem/cnn_param_mem/conv2d_1_biases.txt";
  // parameter INITFILE_CONV2D_L1_M0          = "../test/mem/cnn_param_mem/conv2d_1_m0.txt";
  // parameter INITFILE_CONV2D_L1_N           = "../test/mem/cnn_param_mem/conv2d_1_n.txt";
  // parameter INITFILE_CONV2D_L1_B           = "../test/mem/cnn_param_mem/conv2d_1_b.txt";
  // parameter INITFILE_CONV2D_L1_Z3          = "../test/mem/cnn_param_mem/conv2d_1_z3.txt";
  // parameter INITFILE_DENSE_L1_WEIGHT       = "../test/mem/cnn_param_mem/dense_1_weights.txt";
  // parameter INITFILE_DENSE_L1_BIAS         = "../test/mem/cnn_param_mem/dense_1_biases.txt";
  // parameter INITFILE_DENSE_L1_M0           = "../test/mem/cnn_param_mem/dense_1_m0.txt";
  // parameter INITFILE_DENSE_L1_N            = "../test/mem/cnn_param_mem/dense_1_n.txt";
  // parameter INITFILE_DENSE_L1_B            = "../test/mem/cnn_param_mem/dense_1_b.txt";
  // parameter INITFILE_DENSE_L1_Z3           = "../test/mem/cnn_param_mem/dense_1_z3.txt";
  // parameter INITFILE_DENSE_L2_WEIGHT       = "../test/mem/cnn_param_mem/dense_2_weights.txt";
  // parameter INITFILE_DENSE_L2_BIAS         = "../test/mem/cnn_param_mem/dense_2_biases.txt";
  // parameter INITFILE_DENSE_L2_M0           = "../test/mem/cnn_param_mem/dense_2_m0.txt";
  // parameter INITFILE_DENSE_L2_N            = "../test/mem/cnn_param_mem/dense_2_n.txt";
  // parameter INITFILE_DENSE_L2_B            = "../test/mem/cnn_param_mem/dense_2_b.txt";
  // parameter INITFILE_DENSE_L2_Z3           = "../test/mem/cnn_param_mem/dense_2_z3.txt";
  // parameter SIM_FILEPATH                   = "..";
  // parameter INITFILE_SOUND_M1              = "../datasets/AVA_dataset/test/mem/1000_ADI_PINK_D1D2_02_sound_m1.txt";
  // parameter INITFILE_SOUND_M2              = "../datasets/AVA_dataset/test/mem/1000_ADI_PINK_D1D2_02_sound_m2.txt";    
  // parameter INITFILE_CNN_TEST_INPUT        = "../result/test_data/mem/CochleaProcessing_mqcRec_1_ADI_PINK_D1D2_02_imp.txt";

  //==================================================================
  //RAM INIT FILE LOCATIONS FOR IMPLEMENTATION and POST-IMP SIMULATION
  //==================================================================
  parameter INITFILE_Z1_INIT               = "../../../../test/mem/para_mem_FRC10/z1_init.txt";
  parameter INITFILE_Z2_INIT               = "../../../../test/mem/para_mem_FRC10/z2_init.txt";
  parameter INITFILE_Y_INIT                = "../../../../test/mem/para_mem_FRC10/y_init.txt";
  parameter INITFILE_A0                    = "../../../../test/mem/para_mem_FRC10/a0.txt";
  parameter INITFILE_C0                    = "../../../../test/mem/para_mem_FRC10/c0.txt";
  parameter INITFILE_R                     = "../../../../test/mem/para_mem_FRC10/r.txt";
  parameter INITFILE_G                     = "../../../../test/mem/para_mem_FRC10/g.txt";
  parameter INITFILE_H                     = "../../../../test/mem/para_mem_FRC10/h.txt";
  parameter INITFILE_CONV2D_L1_WEIGHT      = "../../../../test/mem/cnn_param_mem/conv2d_1_weights.txt";
  parameter INITFILE_CONV2D_L1_BIAS        = "../../../../test/mem/cnn_param_mem/conv2d_1_biases.txt";
  parameter INITFILE_CONV2D_L1_M0          = "../../../../test/mem/cnn_param_mem/conv2d_1_m0.txt";
  parameter INITFILE_CONV2D_L1_N           = "../../../../test/mem/cnn_param_mem/conv2d_1_n.txt";
  parameter INITFILE_CONV2D_L1_B           = "../../../../test/mem/cnn_param_mem/conv2d_1_b.txt";
  parameter INITFILE_CONV2D_L1_Z3          = "../../../../test/mem/cnn_param_mem/conv2d_1_z3.txt";
  parameter INITFILE_DENSE_L1_WEIGHT       = "../../../../test/mem/cnn_param_mem/dense_1_weights.txt";
  parameter INITFILE_DENSE_L1_BIAS         = "../../../../test/mem/cnn_param_mem/dense_1_biases.txt";
  parameter INITFILE_DENSE_L1_M0           = "../../../../test/mem/cnn_param_mem/dense_1_m0.txt";
  parameter INITFILE_DENSE_L1_N            = "../../../../test/mem/cnn_param_mem/dense_1_n.txt";
  parameter INITFILE_DENSE_L1_B            = "../../../../test/mem/cnn_param_mem/dense_1_b.txt";
  parameter INITFILE_DENSE_L1_Z3           = "../../../../test/mem/cnn_param_mem/dense_1_z3.txt";
  parameter INITFILE_DENSE_L2_WEIGHT       = "../../../../test/mem/cnn_param_mem/dense_2_weights.txt";
  parameter INITFILE_DENSE_L2_BIAS         = "../../../../test/mem/cnn_param_mem/dense_2_biases.txt";
  parameter INITFILE_DENSE_L2_M0           = "../../../../test/mem/cnn_param_mem/dense_2_m0.txt";
  parameter INITFILE_DENSE_L2_N            = "../../../../test/mem/cnn_param_mem/dense_2_n.txt";
  parameter INITFILE_DENSE_L2_B            = "../../../../test/mem/cnn_param_mem/dense_2_b.txt";
  parameter INITFILE_DENSE_L2_Z3           = "../../../../test/mem/cnn_param_mem/dense_2_z3.txt";
  parameter SIM_FILEPATH                   = "../../../../../../..";
  // parameter INITFILE_SOUND_M1              = "../../../../datasets/AVA_dataset/test/mem/200_ADI_PINK_D2_02_sound_m1.txt";
  // parameter INITFILE_SOUND_M2              = "../../../../datasets/AVA_dataset/test/mem/200_ADI_PINK_D2_02_sound_m2.txt";
  parameter INITFILE_SOUND_M1              = "../../../../datasets/AVA_dataset/test/mem/5xtw_0_ADI_PINK_D1D2_02_sound_m1.txt";
  parameter INITFILE_SOUND_M2              = "../../../../datasets/AVA_dataset/test/mem/5xtw_0_ADI_PINK_D1D2_02_sound_m2.txt";   
  // parameter INITFILE_CNN_TEST_INPUT        = "../../../../result/test_data/mem/CochleaProcessing_mqcRec_2_ADI_PINK_D1_02_imp.txt";
  // parameter INITFILE_CNN_TEST_INPUT        = "../../../../test/feature_ins/mem/fixed_input.txt";
  parameter INITFILE_CNN_TEST_INPUT        = "../../../../test/feature_ins/mem/quantized_xtest_all7000.txt";

  
endpackage 