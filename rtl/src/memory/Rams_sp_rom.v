// Simple Dual-Port Block RAM with One Clock
// File: simple_dual_one_clock.v

module Rams_sp_rom (clk,en,addr,dout);

    parameter WIDTH = 16;
    parameter SIZE = 256;
    parameter ADDRWIDTH = 8;
    parameter  INITFILENAME = "";

    input clk,en;
    input [ADDRWIDTH - 1:0] addr;
    output [WIDTH - 1:0] dout;
    reg	[WIDTH - 1:0] ram [SIZE - 1:0];
    reg	[WIDTH - 1:0] data;

    initial begin
        if (INITFILENAME != "") begin
            $readmemb(INITFILENAME, ram);
        end
    end

    always @ (posedge clk) begin
        if (en)
            data <= ram[addr];
    end

    assign dout = data;

endmodule : Rams_sp_rom
