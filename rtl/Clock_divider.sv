module Clock_divider(
    input logic clock_in,
    input logic reset,
    input logic [31:0] DIVISOR, 
    output logic clock_out
    );

logic [31:0] counter=32'd0;

always_ff @(posedge clock_in)
begin
 counter <= counter + 32'd1;
 if (reset)begin
     counter<= 32'd0;
     clock_out<= 1'b0;
 end
 
 else if(counter>=(DIVISOR-1))
 counter <= 32'd0;
 
clock_out <= (counter<DIVISOR/2)?1'b1:1'b0;

end
endmodule