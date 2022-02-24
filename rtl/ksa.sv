`default_nettype none
module ksa(CLOCK_50, KEY, SW, LEDR, HEX5, HEX4, HEX3, HEX2, HEX1, HEX0);

input                       CLOCK_50;

//////////// LED //////////
output           [9:0]      LEDR;

//////////// KEY //////////
input            [3:0]      KEY;

//////////// SW //////////
input            [9:0]      SW;

//////////// SEG7 //////////
output           [6:0]      HEX0;
output           [6:0]      HEX1;
output           [6:0]      HEX2;
output           [6:0]      HEX3;
output           [6:0]      HEX4;
output           [6:0]      HEX5;

//hex display inputs
reg [3:0]inHEX0;
reg [3:0]inHEX1;
reg [3:0]inHEX2;
reg [3:0]inHEX3;
reg [3:0]inHEX4;
reg [3:0]inHEX5;
logic CLK_50M, reset;

//reset
assign reset = ~KEY[3];
// Input and output declarations
logic CLK_50M;
logic  [9:0] LED;
assign CLK_50M =  CLOCK_50;
assign LEDR[9:0] = LED[9:0];


//Seven Segment 
SevenSegmentDisplayDecoder U0(HEX0, inHEX0);
SevenSegmentDisplayDecoder U1(HEX1, inHEX1);
SevenSegmentDisplayDecoder U2(HEX2, inHEX2);
SevenSegmentDisplayDecoder U3(HEX3, inHEX3);
SevenSegmentDisplayDecoder U4(HEX4, inHEX4);
SevenSegmentDisplayDecoder U5(HEX5, inHEX5);
logic [7:0] data, address;
reg [7:0] i;
logic wren;
logic [7:0] q;
s_memory s_memory_inst(
	.address(address),
	.clock(CLOCK_50),
	.data(data),
	.wren(wren),
	.q(q)
	);

assign inHEX0 = 4'h0;
assign inHEX1 = 4'h1;
assign inHEX2 = 4'h2;
assign inHEX3 = 4'h3;
assign inHEX4 = 4'h4;
assign inHEX5 = 4'h5;
logic [3:0] state;

parameter initial_state = 4'b0000;
parameter task1_init = 4'b0001;
parameter task1_increment = 4'b0010;
parameter task1_done = 4'b0011;
parameter task1_increment_interm = 4'b0100;


	always_ff @(posedge CLOCK_50, posedge reset) begin
	if (reset) begin
		state <= initial_state;
		i <= 8'b0;
	end 
	else begin
		case (state)
			initial_state: begin
				LED[9:0] <= 10'b0;
				state <= task1_init;
			end 
			
			task1_init: begin 
				i <= 8'b0;
				state <= task1_increment;
				wren <= 1'b1;
			end 
			
			task1_increment: begin
				address <= i[7:0];
				data <= i[7:0];
				wren <= 1'b1;
				i <=  i + 8'd1;
				LED[9:0] <= 10'b1111_0000_00;
				if (i == 255) begin
					state <= task1_done;
				end
				else begin state <= task1_increment_interm;
				end
				end
				
				task1_increment_interm: state<= task1_increment;
				task1_done: begin state <= task1_done;
										wren <= 1'b0;
										LED[9:0] <= 10'b1111_0000_00;
										end
				
				
				default: state<= initial_state;
		endcase
		end
		end
endmodule

