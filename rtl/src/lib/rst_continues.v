module rst_continues (
    input clk,
    output out
  );

  localparam CTR_SIZE = 32;
  reg [CTR_SIZE-1:0] ctr_d = {CTR_SIZE{1'b0}};
  reg [CTR_SIZE-1:0] ctr_q = {CTR_SIZE{1'b0}};
 
 
  assign out = (ctr_q == {CTR_SIZE{1'b1}}) ? 1'b0 : 1'b1;
 
  always @(*) begin
    ctr_d = ctr_q + 1'b1; 
  end
 
  always @(posedge clk) begin
    ctr_q <= ctr_d;
  end
 
endmodule