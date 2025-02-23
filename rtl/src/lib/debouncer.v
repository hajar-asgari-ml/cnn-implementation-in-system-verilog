// reference: https://community.intel.com/t5/Programmable-Devices/Debouncer-verilog-code/td-p/90838

module debouncer (noisy,clk_i,debounced);
input wire clk_i, noisy;
output wire debounced;
reg  [3:0]cnt;
//counter: waits that button is pressed at least 10ms 
always @ (posedge clk_i) 
begin
    if (noisy) cnt <= cnt + 4'b0001;
    else cnt <= 0;
end
assign debounced = (cnt==4'b1010) ? 1'b1 : 1'b0;
endmodule