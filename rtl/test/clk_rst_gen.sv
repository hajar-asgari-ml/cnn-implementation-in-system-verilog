module clk_rst_gen
 # (parameter time  CLK_PERIOD = 50ns,
    parameter RST_CLK_CYCLES = 1000)
   
  (output logic clk_o,
   output logic rst_no);

   timeunit 1ns;
   timeprecision 1ps;
   
   initial     clk_o = 1;

   always #CLK_PERIOD clk_o = ~clk_o;
   
   initial begin
      integer cycle_count;
      cycle_count = 0;
      rst_no = 0;
      $display("initial rst", rst_no);
      forever begin
         @(posedge clk_o)
         cycle_count += 1;
         if (cycle_count == RST_CLK_CYCLES) begin
            rst_no = 1;
         end
      end      
   end

endmodule 
   
   
   
   
   
   
   
		    
