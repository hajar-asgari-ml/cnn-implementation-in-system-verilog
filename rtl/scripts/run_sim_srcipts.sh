#!/bin/bash
xvlog -sv -work worklib ../src/pkg_parameters.sv\
						../src/memory/ram_simple_dual_one_clock.sv\
						../src/validready_if.sv\
						../src/MAC_v4.sv\
						../src/CNN.sv\
						../src/Conv2D_v2.sv\
						../src/Conv2D_Wrapper.sv\
						../src/ACC.sv\
						../src/MaxPooling2D_signed.sv\
						../src/Dense.sv\
						../src/Int32_to_Int8_out.sv\
						../src/CAR.sv\
						../src/CAR_compute_v1.sv\
						../src/CochleaProcessing.sv\
						../src/ACC_QCorr.sv\
						../src/Q_Mqcr_Rec.sv\
						../src/SoundSourceLocalizer.sv\
						../src/SSL_wrapper.sv\
						../src/CNN_wrapper.sv\
						../src/Flatten.sv\
						../src/lib/signed_mult.v\
						../src/lib/signed_add.v\
						../test/clk_rst_gen.sv\
						../test/Conv2D_tb.sv\
						../test/Conv2D_Wrapper_tb.sv\
						../test/MAC_v3_tb.sv\
						../test/CNN_tb.sv\
						../test/Int32_to_Int8_out_tb.sv\
						../test/CAR_compute_tb.sv\
						../test/CAR_tb.sv\
						../test/CochleaProcessing_tb.sv\
						../test/Q_Mqcr_Rec_tb.sv\
						../test/SoundSourceLocalizer_tb.sv\
						../test/SSL_wrapper_tb.sv\

					
### run with gui
xelab -relax worklib.CNN_tb  -debug typical -incremental 
###****-relax is added to prevent this error: doesn't have a timescale but at least one module in design has a timescale.
xsim worklib.CNN_tb  --gui -wdb simulate_xsim.wdb 

### run without gui
# xelab -relax worklib.Conv2D_tb_v1 -debug typical -incremental 
# xsim worklib.Conv2D_tb_v1 --r *


