`default_nettype none
module SubCore (
    start,
    reset,
    finish,

     CLOCK_50, // inputs

     secret_key,
	  keyfound,
	  start_done
);

input logic start;
input logic CLOCK_50; // inputs
input logic [23:0] secret_key;
input logic reset;


output logic finish;
output logic keyfound;  //outputs
output logic start_done;

logic CLK_50M;
assign CLK_50M = CLOCK_50;

//internal wires
logic[7:0] modulo;
logic swapjvalflag,swapivalflag,f_en;
reg[7:0] decrypted_message; 
reg[7:0] j,f; 
reg [7:0] i;
reg [4:0]k;
reg[7:0] swapival,swapjval;
logic [7:0] iplusj;
logic [7:0] secret_key_byte;




//state declerations
reg [11:0] state;     //incase i need 4095 states
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
parameter failed_state =12'b0000_0011_0100;


//S RAM
reg[7:0] data, address;
logic wren;
logic[7:0] q;
s_memory s_memory_inst(
	.address(address),
	.clock(CLK_50M),
	.data(data),
	.wren(wren),
	.q(q)
	);

// Encrypted Message ROM
reg [4:0] address_m;
reg [7:0] q_m;

e_memory	e_memory_inst (
    .address ( address_m ),
    .clock ( CLK_50M),
    .q (q_m)
     );
	 
//Decrypted message RAM
reg [7:0] data_d;
reg [4:0]address_d;
logic wren_d;
logic [7:0] q_d;
d_memory d_memory_inst(
    .address(address_d),
	.clock(CLK_50M),
	.data(data_d),
	.wren(wren_d),
	.q(q_d)
	);



    //secret_key[i%3]
     assign secret_key_byte = (modulo==8'd2)?secret_key[7:0]:(modulo==8'd1)?secret_key[15:8]:secret_key[23:16];
     //[i % 3]
     assign modulo = ((i)%3); 
    //constand assignment of address_m and address_d to k
     assign address_m = k;
     assign address_d = k;
    //constant assignment of s[i]+s[j]
     assign iplusj = swapjval+swapival;

//load enable flipflop for s[j]
always_ff@(posedge CLK_50M, posedge reset) begin
    if (reset)
	 swapjval<=8'b0;
	 else if(swapjvalflag) swapjval <= q;
end
//load enable flipflop for s[i]
always_ff@(posedge CLK_50M, posedge reset) begin
    if (reset)
	 swapival<=8'b0;
     else if (swapivalflag) swapival <=q;
end
//load enable flipflop for f
always_ff@(posedge CLK_50M, posedge reset) begin
    if (reset)
	 f<=8'b0;
     else if (f_en) f <=q ;
end


//FSM for sub_core
	always_ff @(posedge CLK_50M, posedge reset) begin
	if (reset) begin
        
		state <= initial_state; //asynchronous reset
		i <= 8'b0;
		finish <= 1'b0;
	end 
	else begin
		case (state)
			initial_state: begin
                wren_d <=1'b0;
                wren <=1'b0;
					finish <=1'b0;
               keyfound <=1'b0; //initialize all variables
					start_done <=1'b0;
				if(start) state<= task1_init;
				else state <= initial_state;
			end 
			
			task1_init: begin 
				i <= 8'b0;
				state <= task1_write1;
				wren <= 1'b0; //initialize task 1
                start_done <=1'b1;
			end 
            task1_write1: begin
                state <= task1_inc1;
                address <= i[7:0];
				data <= i[7:0];
                wren <= 1'b1;
					 start_done <=1'b1;
            end
            task1_inc1: begin
                
               
                if (i == 8'd255) begin state <= task2_init ; i<=8'b0; j<=8'b0; // if all values filled then initialize task 2
                end
				else state <= task1_increment; 
				start_done <=1'b1;
            end
			
			task1_increment: begin
                state <= task1_write1;
                wren <= 1'b0;
                i[7:0] <=  (i[7:0] + 8'd1); //increment i for task 1
				start_done <=1'b0;
				end
			
				task1_done: begin 
                    state <= task2_init; //no longer using this state
                    wren <= 1'b0;
		            
							end
                task2_init: begin
					i <= 8'b0;
					j <= 8'b0; // initialize i and j to 0 for task 2
					state <= task2_si;
				end

                task2_si: begin
                    state <= task2_secretkey;
                    wren <=1'b0;
                    address <= i[7:0]; //read value for s[i]
                    swapivalflag <= 1'b0;
                   
                    
                end

                task2_secretkey: begin
                    state <= task2_j1;
                    address <= i[7:0];
                    swapivalflag <= 1'b1;
                    
                    
                end

                task2_j1: begin
                    state <= task2_j2;
                    address <= i[7:0];
                    j[7:0] <= (j[7:0] + q + secret_key_byte); //calculate j
                    swapivalflag <= 1'b1;
                    
                    
                end

                task2_j2: begin
                    state <= task2_s_j;
                    address <= j[7:0];
                    swapjvalflag <= 1'b0; //read value of s[j]
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
					 state <= task2_write1; //write s[i] into s[j]
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
                    state <= task2_swap_step2;//write s[j] into s[i]
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
                    
                    if (i == 8'd255) state <= task2a_done; //when the whole s memory is filled then go to task 2b
                    else state <= task2_increment;
                end


                task2_increment: begin 
                    state <= task2_si;
                    i <= (i + 8'b1);  //increment i for task 2a
                end


                task2a_done: begin
                    
                    state <= task2b_init;
                end
/////////////////////////////////////////////////////////////// task2b
                task2b_init: begin
                    i<=8'b0;
                    j<=8'b0;
                    k<=8'b0;
                    state <= task2b_inc_i; //initialize i,j,k to 0

                end
                task2b_inc_i: begin
                    i <=i+8'd1;
                    state <= task2b_inc_j1;
                    wren <= 1'b0;            //i = i+1;
					swapivalflag <= 1'b0;
                    
                end
                task2b_inc_j1: begin
                    address <=i;
                    swapivalflag <= 1'b0;
                    state <= task2b_wait1;
                  
                end
                task2b_wait1: begin
                    address <=i[7:0];
                    state <= task2b_inc_j2; //save value of s[i]
                    swapivalflag <= 1'b0;
                end
                task2b_inc_j2: begin
							address <=i[7:0];
                    j <=( j + q ); //calculate value of j
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
                    swapjvalflag <= 1'b1;  //get save of s[j] and save it 
                    state <= task2b_swap_step6;
                end

                task2b_swap_step6: begin
				  
                  state <= task2b_swap_step7;
                  address <= j;
                  swapjvalflag <= 1'b0;
                end

                task2b_swap_step7: begin 
                    state <= task2b_write1;
                    address <= j;  //put value of s[i] in s[j]
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
                    address <=i;//put value of s[j] in s[i]
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
                    address <= iplusj;//read value of s[s[i]+s[j]]
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
                   decrypted_message[7:0] <= q_m ^ f; //xor value of s[i] with encrypted message at k
                   state<= task2b_write_decrypted_message;
                   f_en <= 1'b0;
                   wren_d <= 1'b0;
            end
            task2b_write_decrypted_message: begin
                //address_m <= k[7:0];
                
                data_d <= decrypted_message; //write decrypted message into RAM D
                wren_d <= 1'b1;
                state <=task2b_write_decrypted_message2;
            end
            
            task2b_write_decrypted_message2: begin
                wren_d <= 1'b0;
					 if((decrypted_message >= 8'd97 && decrypted_message <= 8'd122) || decrypted_message == 8'd32  ) begin 
						state <= task2b_inc1; //if in the range or space check next letter
						end
                else state <=failed_state;//if letter is outside the range of allowed range or a space then this iteration failed
            end

            task2b_inc1: begin
                if (k == 8'd31) begin state <= task2b_done ; //if k is at at address 31 then key is found and iteration is correct 
                end
				else state <= task2b_incrementk; //else increment k
            end
			
			task2b_incrementk: begin
                state <= task2b_inc_i;
                k[4:0] <=  k + 1; //increment k
				end

                task2b_done: begin
                    state <= task2b_done;
                        finish<=1'b1; //success state
						 keyfound <= 1'b1; //set flag keyfound to 1
                end
					failed_state: begin 
					finish <= 1'b1; //if failed then iteration finished 
					state <= failed_state;
					keyfound <= 1'b0; // set keyfound is 0 for this iteration
					end

				default: state<= initial_state;
		endcase
		end
		end
    
endmodule