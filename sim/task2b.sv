`default_nettype none
module task2b(CLOCK_50, KEY, SW, LEDR, HEX5, HEX4, HEX3, HEX2, HEX1, HEX0 
  //  GPIO_0,
  //  GPIO_1
    );

input   logic                    CLOCK_50;

//////////// LED //////////
output     logic      [9:0]      LEDR;

//////////// KEY //////////
input   logic         [3:0]      KEY;

//////////// SW //////////
input    logic        [9:0]      SW;

//////////// SEG7 //////////
output      logic     [6:0]      HEX0;
output  logic         [6:0]      HEX1;
output   logic        [6:0]      HEX2;
output    logic       [6:0]      HEX3;
output    logic       [6:0]      HEX4;
output    logic       [6:0]      HEX5;

//////////// GPIO //////////
//inout           [35:0]      GPIO_0;
//inout           [35:0]      GPIO_1;

//hex display inputs
logic [3:0]inHEX0;
logic [3:0]inHEX1;
logic [3:0]inHEX2;
logic [3:0]inHEX3;
logic [3:0]inHEX4;
logic [3:0]inHEX5;
logic reset;


//reset
assign reset = ~KEY[3];
// Input and output declarations
//logic CLK_50M;
logic CLK_50M;
logic  [9:0] LED;
assign CLK_50M =  CLOCK_50;
assign LEDR[9:0] = LED[9:0];

//Decrypted message RAM
reg [7:0] data_d, address_d;
logic wren_d;
logic [7:0] q_d;
// Encrypted Message ROM
reg [7:0] address_m;
reg [7:0] q_m;

logic [7:0] placeholder;
logic [7:0] placeholder2;

//Seven Segment 
SevenSegmentDisplayDecoder U0(HEX0, inHEX0);
SevenSegmentDisplayDecoder U1(HEX1, inHEX1);
SevenSegmentDisplayDecoder U2(HEX2, inHEX2);
SevenSegmentDisplayDecoder U3(HEX3, inHEX3);
SevenSegmentDisplayDecoder U4(HEX4, inHEX4);
SevenSegmentDisplayDecoder U5(HEX5, inHEX5);
//S RAM
reg[7:0] data, address;
reg [7:0] i,k;
logic wren;
logic[7:0] q;
reg[7:0] swapival,swapjval;

logic [7:0] iplusj;
wire debug_clk;
Clock_divider clk1(
     .clock_in(CLOCK_50),
    .reset(reset),
    .DIVISOR(32'd500000), 
    .clock_out(debug_clk)
    );

assign iplusj = swapjval+swapival;
s_memory s_memory_inst(
	.address(address),
	.clock(debug_clk),
	.data(data),
	.wren(wren),
	.q(q)
	);

d_memory d_memory_inst(
    .address(address_d),
	.clock(debug_clk),
	.data(data_d),
	.wren(wren_d),
	.q(q_d)
	);

 e_memory	e_memory_inst (
    .address ( address_m ),
    .clock ( debug_clk),
    .q (q_m)
     );
    

reg[7:0] decrypted_message;
   reg[7:0] j,f;

assign inHEX0 = decrypted_message[3:0];
assign inHEX1 = decrypted_message[7:4];
assign inHEX2 = address_m[3:0];
assign inHEX3 = address_m[7:4];
assign inHEX4 = f[3:0];
assign inHEX5 = f[7:4];

reg[11:0] state;     //incase i need 4095 states
logic[7:0] modulo;
logic[23:0] secret_key;

assign placeholder2 = (modulo==8'd2)?secret_key[7:0]:(modulo==8'd1)?secret_key[15:8]:secret_key[23:16];
assign modulo = ((i)%3); //[i % 3]

logic swapjvalflag,swapivalflag,f_en;


parameter initial_state = 12'b0000_0000_0000;
parameter task1_init = 12'b0000_0000_0001;
parameter task1_increment = 12'b0000_0000_0010;
parameter task1_increment_interm = 12'b0000_0000_0011;
parameter task1_done = 12'b0000_0000_0100;
parameter task2_init = 12'b0000_0000_0101;
parameter task2_si = 12'b0000_0000_0110;
parameter task2_secretkey = 12'b0000_0000_0111;
parameter task2_j1 = 12'b0000_0000_1000;
parameter task2_j2 = 12'b0000_0000_1001;
parameter task2_s_j = 12'b0000_0000_1011;
parameter task2_s_i = 12'b0000_0000_1100;
parameter task2_swap_step1 = 12'b0000_0000_1101;
parameter task2_swap_step2 = 12'b0000_0000_1110;
parameter task2_increment = 12'b0000_0000_1111;
parameter task2a_done = 12'b0000_0001_0000;
parameter task2_wait1 = 12'b0000_0001_0001;
parameter task2_wait2 = 12'b0000_0001_0010;
parameter task2_wait3 = 12'b0000_0001_0011;
parameter task1_write1 = 12'b0000_0001_0100;
parameter task1_write2 =12'b0000_0001_0101;
parameter task2_write1 = 12'b0000_0001_0110;
parameter task2_write2 = 12'b0000_0001_0111;
parameter task2a_done2 = 12'b0000_0001_1000;
parameter task1_inc1 = 12'b0000_0001_1001;
///////////////////////////////////////////////
parameter task2b_init = 12'b0000_0001_1010;
parameter task2b_inc_i = 12'b0000_0001_1011;
parameter task2b_inc_j1 = 12'b0000_0001_1100;
parameter task2b_inc_j2 = 12'b0000_0001_1101;
parameter task2b_swap_step1 = 12'b0000_0001_1110;
parameter task2b_swap_step2 = 12'b0000_0001_1111;
parameter task2b_swap_step3 = 12'b0000_0010_0000;
parameter task2b_swap_step5 = 12'b0000_0010_0001;
parameter task2b_swap_step6 = 12'b0000_0010_0010;
parameter task2b_swap_step7 = 12'b0000_0010_0011;
parameter task2b_write1 = 12'b0000_0010_0100;
parameter task2b_wait2 =12'b0000_0010_0101;
parameter task2b_swap_step8 = 12'b0000_0010_0110;
parameter task2b_swap_step9 = 12'b0000_0010_0111;
parameter task2b_f1 = 12'b0000_0010_1000;
parameter task2b_f2 = 12'b0000_0010_1001;
parameter task2b_f3 = 12'b0000_0010_1010;
parameter task2b_read_decrypt = 12'b0000_0010_1011;
parameter task2b_read_decrypt2 = 12'b0000_0010_1100;
parameter task2b_write_decrypted_message = 12'b0000_0010_1101;
parameter task2b_write_decrypted_message2 = 12'b0000_0010_1110;
parameter task2b_inc1 = 12'b0000_0010_1111;
parameter task2b_incrementk = 12'b0000_0011_0000;
parameter task2b_done = 12'b0000_0011_0001;
parameter task2b_wait1 =12'b0000_0011_0010;
parameter task2b_wait4 =12'b0000_0011_0011;

assign address_m = k;
assign address_d = k;


assign secret_key[23:0] = {14'b0,SW[9:0]};


always_ff@(posedge debug_clk, posedge reset) begin
    if (reset)
	 swapjval<=8'b0;
	 else if(swapjvalflag) swapjval <= q;
     
    
end
always_ff@(posedge debug_clk, posedge reset) begin
    if (reset)
	 swapival<=8'b0;
     else if (swapivalflag) swapival <=q;
    
end

always_ff@(posedge debug_clk, posedge reset) begin
    if (reset)
	 f<=8'b0;
     else if (f_en) f <=q ;
    
end
//always_ff@(posedge CLK_50M, posedge reset) begin
//    if (reset)
//	 q_message<=8'b0;
//     else if (q_m_en) q_message <=q_m ;
    
//end



	always_ff @(posedge debug_clk, posedge reset) begin
	if (reset) begin
        
		state <= initial_state;
		i <= 8'b0;
	end 
	else begin
		case (state)
			initial_state: begin
                wren_d <=1'b0;
                wren <=1'b0;

				LED[9:0] <= 10'b0;
				state <= task1_init;
			end 
			
			task1_init: begin 
				i <= 8'b0;
				state <= task1_write1;
				wren <= 1'b0;
			end 
            task1_write1: begin
                state <= task1_inc1;
                address <= i[7:0];
				data <= i[7:0];
                wren <= 1'b1;
            end
            task1_inc1: begin
                
               
                if (i == 8'd255) begin state <= task2_init ; i<=8'b0; j<=8'b0;
                end
				else state <= task1_increment;
                
               
               
            end
			
			task1_increment: begin
                state <= task1_write1;
                wren <= 1'b0;
                i[7:0] <=  (i[7:0] + 8'd1);
				
				end
			
				task1_done: begin 
                    state <= task2_init;
                    wren <= 1'b0;
		            LED[9:0] <= 10'b1111_0000_00;
							end
                task2_init: begin
					i <= 8'b0;
					j <= 8'b0;
					state <= task2_si;
				end

                task2_si: begin
                    state <= task2_secretkey;
                    wren <=1'b0;
                    address <= i[7:0];
                    swapivalflag <= 1'b0;
                   
                    
                end

                task2_secretkey: begin
                    state <= task2_j1;
                    address <= i[7:0];
                    //swapival <= q;
                    swapivalflag <= 1'b1;
                    placeholder <= q;
                    
                end

                task2_j1: begin
                    state <= task2_j2;
                    address <= i[7:0];
                    j[7:0] <= (j[7:0] + q + placeholder2);
                    swapivalflag <= 1'b1;
                    
                    
                end

                task2_j2: begin
                    state <= task2_s_j;
                    address <= j[7:0];
                    swapjvalflag <= 1'b0;
                    swapivalflag <= 1'b0;
                end

                task2_s_j: begin 
                    address <= j[7:0];
                    //swapjval <= q;
                    swapjvalflag <= 1'b1;
                    state <= task2_s_i;
                end

                task2_s_i: begin
				  
                  state <= task2_wait1;
                  address <= j[7:0];
                  swapjvalflag <= 1'b0;
                  //swapjvalflag <= 1'b0;
                end

                task2_wait1: begin 
					 state <= task2_write1;
                    address <= j[7:0];
                    data <= swapival;
                    wren <=1'b1;
					 end
                
                task2_write1:begin
                    state <=  task2_swap_step1;
                    wren <= 1'b0;
                    
                end
                    
				task2_swap_step1: begin   
                    state <= task2_wait2;
                    address <= i[7:0];
                    
                end

                task2_wait2: begin
                    state <= task2_swap_step2;
                   // address <= j;
                    data <= swapjval;
                    address <=i[7:0];
                    wren<=1'b1;
                    
					 end
                
                task2_swap_step2: begin
                    wren <= 1'b0;
					
                    state <= task2_wait3;
                    
                end

 
                task2_wait3: begin 
                    
                    if (i == 8'd255) state <= task2a_done;
                    else state <= task2_increment;
                end


                task2_increment: begin 
                    state <= task2_si;
                    i <= (i + 8'b1);
                end


                task2a_done: begin
                    
                    state <= task2b_init;
                end
/////////////////////////////////////////////////////////////// task2b
                task2b_init: begin
                    i<=8'b0;
                    j<=8'b0;
                    k<=8'b0;
                    state <= task2b_inc_i;

                end
                task2b_inc_i: begin
                    i <=i+8'd1;
                    state <= task2b_inc_j1;
                    wren <= 1'b0;
					swapivalflag <= 1'b0;
                    
                end
                task2b_inc_j1: begin
                    address <=i;
                    swapivalflag <= 1'b0;
                    state <= task2b_wait1;
                  
                end
                task2b_wait1: begin
                    address <=i[7:0];
                    state <= task2b_inc_j2;
                    swapivalflag <= 1'b0;
                end
                task2b_inc_j2: begin
							address <=i[7:0];
                    j <=( j + q );
                    state <= task2b_swap_step1;
                    swapivalflag <= 1'b1; // only line changes
                end

               
                ///////////////////////////////////////////////////////////repeat of swap above
                task2b_swap_step1: begin
                    state <= task2b_swap_step2;
                    wren <=1'b0;
                    address <= i;
                    swapivalflag <= 1'b0;
                end

                task2b_swap_step2: begin
                    state <= task2b_swap_step3;
                    address <= i;
                    swapivalflag <= 1'b0;
                   
                    
                end

                task2b_swap_step3: begin
                    state <= task2b_swap_step5;
                    address <= j;
                    swapjvalflag <= 1'b0;
                    swapivalflag <= 1'b0;
                end

                task2b_swap_step5: begin 
                    address <= j;
                    swapjvalflag <= 1'b1;
                    state <= task2b_swap_step6;
                end

                task2b_swap_step6: begin
				  
                  state <= task2b_swap_step7;
                  address <= j;
                  swapjvalflag <= 1'b0;
                end

                task2b_swap_step7: begin 
                    state <= task2b_write1;
                    address <= j;
                    data <= swapival;
                    wren <=1'b1;
					 end
                
                task2b_write1:begin
                    state <=  task2b_swap_step8;
                    wren <= 1'b0;
                    
                end
                    
				task2b_swap_step8: begin   
                    state <= task2b_wait2;
                    address <= i;
                    
                end

                task2b_wait2: begin
                    state <= task2b_swap_step9;
                   // address <= j;
                    data <= swapjval;
                    address <=i;
                    wren<=1'b1;
                    
					 end
                
                task2b_swap_step9: begin
                    wren <= 1'b0;
					
                    state <= task2b_f1;
                    
                end
        ///////////////////////////////////////////////////////////////////////

                task2b_f1: begin
                    state <= task2b_f2;
                    //address <= iplusj;
                    f_en <= 1'b0;
                end

                task2b_f2: begin
                    state <= task2b_f3;
                    address <= iplusj;//changed too
                    f_en <= 1'b0;
                end

                task2b_f3: begin
					 state <= task2b_read_decrypt;
					 address <= iplusj;
                f_en <= 1'b1;
                end
                
                task2b_read_decrypt: begin
                state <= task2b_read_decrypt2;
                f_en <= 1'b0;
                end

                task2b_wait4: begin
                    state <= task2b_read_decrypt2;
                    
                end
                task2b_read_decrypt2: begin
                    //address_m <= k[7:0];
                   decrypted_message[7:0] <= q_m ^ f;
                   state<= task2b_write_decrypted_message;
                   f_en <= 1'b0;
                   wren_d <= 1'b0;
            end
            task2b_write_decrypted_message: begin
                //address_m <= k[7:0];
                
                data_d <= decrypted_message;
                wren_d <= 1'b1;
                state <=task2b_write_decrypted_message2;
            end
            
            task2b_write_decrypted_message2: begin
                wren_d <= 1'b0;
                state <=task2b_inc1;
            end

            task2b_inc1: begin
                if (k == 8'd31) begin state <= task2b_done ; 
                end
				else state <= task2b_incrementk;
            end
			
			task2b_incrementk: begin
                state <= task2b_inc_i;
                k[7:0] <=  k + 1;
				end

                task2b_done: begin
                    state <= task2b_done;
                    LED[9:0] <= 10'b1111_1111_11;
                end

				default: state<= initial_state;
		endcase
		end
		end
    
endmodule

