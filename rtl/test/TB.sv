module TB();
   localparam unsigned MAX_WIDTH = 4;
logic [2:0] TB_0_L = 3'd1;
logic [2:0] TB_1_L = 3'd5;
string dialog = "Hello";

 

// logic [2:0] GX1F_BK [0:3];
string GX1F_BK [0:3];
generate 
    for(genvar bg=0; bg<MAX_WIDTH; bg=bg+1) begin
       assign GX1F_BK[bg] = {"TB_", $sformatf("%0d",bg), "_L"} ;
       // GX1F_BK[bg] =  bg[7:0];
    end
endgenerate
initial begin
   $display("%s", dialog);  
   $display("%s",GX1F_BK[0]);
end

endmodule