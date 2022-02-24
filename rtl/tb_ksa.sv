`default_nettype none
module tb_Core;
    reg CLOCK_50;
    reg[3:0]KEY;
    reg [9:0]SW;
    
    
    wire [9:0] LEDR; 
    wire [6:0] HEX5, HEX4, HEX3, HEX2, HEX1, HEX0;
       
    Core DUT(
        .CLOCK_50(CLOCK_50), 
        .KEY(KEY), 
        .SW(SW), 
        .LEDR(LEDR), 
        .HEX5(HEX5), 
        .HEX4(HEX4), 
        .HEX3(HEX3), 
        .HEX2(HEX2), 
        .HEX1(HEX1), 
        .HEX0(HEX0) 
          );


initial begin 
    CLOCK_50 = 1'b0;
    KEY = 4'b1111;
   

    forever begin
        #20 CLOCK_50 = ~CLOCK_50;
    end
end

endmodule