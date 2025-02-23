// Simple Dual-Port Block RAM with One Clock
// File: simple_dual_one_clock.v

module Ram_simple_dual_one_clock_dist (clk,wea,addra,addrb,dia,dob);

    parameter WIDTH = 4;
    parameter SIZE = 256;
    parameter ADDRWIDTH = 8;
    parameter  INITFILENAME = "";

    input clk,wea;
    input [ADDRWIDTH - 1:0] addra,addrb;
    input [WIDTH - 1:0] dia;
    output [WIDTH - 1:0] dob;
    reg	[WIDTH - 1:0] ram [SIZE - 1:0];

    initial begin
        if (INITFILENAME != "") begin
            $readmemb(INITFILENAME, ram);
        end
    end

    always @ (posedge clk) begin
        if (wea)
            ram[addra] <= dia;
    end

    assign dob = ram[addrb];

endmodule : Ram_simple_dual_one_clock_dist