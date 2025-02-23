// Simple Dual-Port Block RAM with One Clock
// File: simple_dual_one_clock.v
(* DONT_TOUCH = "yes" *) // to prevent vivado removing top level ports
module ram_simple_dual_one_clock #(
  parameter WIDTH = 4,
  parameter SIZE = 256,
  parameter ADDRWIDTH = 8,
  parameter  INITFILENAME = "")
  (
  input logic clk,
  input logic ena,enb, wea,
  input logic [ADDRWIDTH - 1:0] addra, addrb,
  input logic [WIDTH - 1:0] dia,
  output logic [WIDTH - 1:0] dob
  );

(* ram_style = "block" *) logic	[WIDTH - 1:0] ram [SIZE - 1:0];
// logic	[WIDTH - 1:0] doa,dob;

initial begin
  if (INITFILENAME != "") begin
    $readmemb(INITFILENAME, ram);
    $display("READ RAM FROM FILE.");
  end
end

always_ff @ (posedge clk) begin
  if (ena) begin
    if (wea)
        ram[addra] <= dia;
  end
  if (enb)
    dob <= ram[addrb];
end

endmodule : ram_simple_dual_one_clock