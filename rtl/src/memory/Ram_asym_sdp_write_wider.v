// Asymmetric port RAM
// Write wider than Read. Write Statement in a loop.
// asym_ram_sdp_write_wider.v

module Ram_asym_sdp_write_wider (clk, weA, enaA, enaB, addrA, addrB, diA, doB);
parameter WIDTHB = 4;
parameter SIZEB = 1024;
parameter ADDRWIDTHB = 10;

parameter WIDTHA = 16;
parameter SIZEA = 256;
parameter ADDRWIDTHA = 8;

parameter INITFILENAME = "";

input clk;
input weA;
input enaA, enaB;
input [ADDRWIDTHA-1:0] addrA;
input [ADDRWIDTHB-1:0] addrB;
input [WIDTHA-1:0] diA;
output [WIDTHB-1:0] doB;

function integer log2;
input integer value;
reg [31:0] shifted;
integer res;
begin
	if (value < 2)
		log2 = value;
	else
	begin
		shifted = value-1;
		for (res=0; shifted>0; res=res+1)
			shifted = shifted>>1;
		log2 = res;
	end
end
endfunction

localparam maxSIZE = SIZEB;
localparam maxWIDTH = WIDTHA;
localparam minWIDTH = WIDTHB;

localparam RATIO = maxWIDTH / minWIDTH;
localparam log2RATIO = log2(RATIO);

reg [minWIDTH-1:0] RAM [0:maxSIZE-1];
reg [WIDTHB-1:0] readB;

initial begin
	if (INITFILENAME != "") begin
		$readmemb(INITFILENAME, RAM);
	end
end

always @(posedge clk) begin
	if (enaB) begin
		readB <= RAM[addrB];
	end
end
assign doB = readB;

always @(posedge clk)
begin : ramwrite
	integer i;
	reg [log2RATIO-1:0] lsbaddr;
	if (RATIO > 1) begin
		for (i=0; i< RATIO; i= i+ 1) begin : write1
			lsbaddr = i;
			if (enaA) begin
				if (weA)
					RAM[{addrA, lsbaddr}] <= diA[(i+1)*minWIDTH-1 -: minWIDTH];
			end
		end : write1
	end else begin
		RAM[addrA] <= diA;
	end
end

endmodule : Ram_asym_sdp_write_wider
