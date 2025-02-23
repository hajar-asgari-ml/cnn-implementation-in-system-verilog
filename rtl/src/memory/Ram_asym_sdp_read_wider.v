// Asymmetric port RAM
// Read Wider than Write. Read Statement in loop
//asym_ram_sdp_read_wider.v

module Ram_asym_sdp_read_wider (clk, enaA, weA, enaB, addrA, addrB, diA, doB);

parameter WIDTHA = 16;
parameter SIZEA = 1024;
parameter ADDRWIDTHA = 10;

parameter WIDTHB = 64;
parameter SIZEB = 256;
parameter ADDRWIDTHB = 8;

parameter INITFILENAME = "";

input clk;
input weA;
input enaA, enaB;
input [ADDRWIDTHA-1:0] addrA;
input [ADDRWIDTHB-1:0] addrB;
input [WIDTHA-1:0] diA;
output [WIDTHB-1:0] doB;

`define max(a,b) {(a) > (b) ? (a) : (b)}
`define min(a,b) {(a) < (b) ? (a) : (b)}

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

localparam maxSIZE = SIZEA;
localparam maxWIDTH = WIDTHB;
localparam minWIDTH = WIDTHA;

localparam RATIO = maxWIDTH / minWIDTH;
localparam log2RATIO = log2(RATIO);

reg [minWIDTH-1:0] RAM [0:maxSIZE-1];
reg [WIDTHB-1:0] readB;

initial begin
	if (INITFILENAME != "") begin
		$readmemb(INITFILENAME, RAM);
	end
end

always @(posedge clk)
begin
	if (enaA) begin 
		if (weA)
			RAM[addrA] <= diA;
	end		
end


always @(posedge clk)
begin : ramread
	integer i;
	reg [log2RATIO-1:0] lsbaddr;
	if (enaB) begin
		if (RATIO > 1) begin
			for (i = 0; i < RATIO; i = i+1) begin
				lsbaddr = i;
				readB[(i+1)*minWIDTH-1 -: minWIDTH] <= RAM[{addrB, lsbaddr}];
			end
		end else begin
			readB <= RAM[addrB];
		end
	end
end
assign	doB = readB;

endmodule : Ram_asym_sdp_read_wider

