`default_nettype none
module ksatask2(CLOCK_50, KEY, SW, LEDR, HEX5, HEX4, HEX3, HEX2, HEX1, HEX0 
  //  GPIO_0,
  //  GPIO_1
    );

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
logic [7:0] data_d, address_d;
logic wren_d;
logic [7:0] q_d;
// Encrypted Message ROM
logic [7:0] address_m;
logic [7:0] q_m;

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
reg [7:0] i;
logic wren;
logic[7:0] q;
reg [7:0]swapival,swapjval;

s_memory s_memory_inst(
	.address(address),
	.clock(CLK_10Hz),
	.data(data),
	.wren(wren),
	.q(q)
	);

    Clock_divider clk1(
    .clock_in(CLOCK_50),
    .reset(1'b0),               // Clock divider for 1Hz 
    .DIVISOR(32'd5000), 
    .clock_out(CLK_10Hz)
    );
wire CLK_10Hz;
assign inHEX0 = i[3:0];
assign inHEX1 = i[7:4];
assign inHEX2 = swapjval[3:0];
assign inHEX3 = swapjval[7:4];
assign inHEX4 = placeholder2[3:0];
assign inHEX5 = placeholder2[7:4];

reg[11:0] state;
logic[7:0] modulo;
logic[23:0] secret_key;
reg[7:0] j;
assign placeholder2 = (modulo==8'd2)?secret_key[7:0]:(modulo==8'd1)?secret_key[15:8]:secret_key[23:16];
assign modulo = ((i)%3); //[i % 3]

logic swapjvalflag,swapivalflag;


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


assign secret_key[23:0] = {14'b0,SW[9:0]};


always_ff@(posedge CLK_10Hz, posedge reset) begin
    if (reset)
	 swapjval<=8'b0;
	 else if(swapjvalflag) swapjval <= q;
     
    
end
always_ff@(posedge CLK_10Hz, posedge reset) begin
    if (reset)
	 swapival<=8'b0;
     else if (swapivalflag) swapival <=q;
    
end


	always_ff @(posedge CLK_10Hz, posedge reset) begin
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
                    
                   // if (modulo == 8'd2) placeholder2 <= secret_key[7:0];
                    
                   // else if (modulo == 8'd1) placeholder2 <= secret_key[15:8];
                    
                   // else placeholder2 <= secret_key[23:16];
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

                task2_wait1: begin state <= task2_write1;
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
                    state <= task2a_done;
                end
                
        
				default: state<= initial_state;
		endcase
		end
		end

/*
//=====================================================================================
//
// LCD Scope Acquisition Circuitry Wire Definitions                 
//
//=====================================================================================
        parameter scope_info_bytes = 16;
        parameter scope_info_bits_per_byte = 8;


        wire allow_run_LCD_scope;
        wire [15:0] scope_channelA, scope_channelB;
        (* keep = 1, preserve = 1 *)wire scope_clk;
        reg user_scope_enable_trigger;
        wire user_scope_enable;
        wire user_scope_enable_trigger_path0, user_scope_enable_trigger_path1;
        wire scope_enable_source = SW[8];
        wire choose_LCD_or_SCOPE = SW[9];
        
        wire  [scope_info_bits_per_byte-1:0] scope_info0, scope_info1, scope_info2,
     scope_info3, scope_info4, scope_info5, scope_info6, scope_info7, scope_info8, 
     scope_info9, scope_info10, scope_info11, scope_info12, scope_info13, 
     scope_info14, scope_info15;
                
        doublesync user_scope_enable_sync1(.indata(scope_enable_source),
                          .outdata(user_scope_enable),
                          .clk(CLK_50M),
                          .reset(1'b1)); 
        
        //Generate the oscilloscope clock
         Clock_divider clk2(
    .clock_in(CLOCK_50),
    .reset(1'b0),               // Clock divider for 1Hz 
    .DIVISOR(32'd10000000), 
    .clock_out(scope_clk)
    );
        
        //Scope capture channels
        //Scope capture channels
        
        (* keep = 1, preserve = 1 *) logic ScopeChannelASignal;
        (* keep = 1, preserve = 1 *) logic ScopeChannelBSignal;
        
        assign ScopeChannelASignal = scope_clk;
        assign ScopeChannelBSignal = SW[1];
        //Scope capture channels
        
        scope_capture LCD_scope_channelA(
        .clk(scope_clk),
        .the_signal(ScopeChannelASignal),
        .capture_enable(allow_run_LCD_scope & user_scope_enable), 
        .captured_data(j), //Insert your channel B signal here
        .reset(1'b1));
        
        scope_capture LCD_scope_channelB
        (
        .clk(scope_clk),
        .the_signal(ScopeChannelBSignal),
        .capture_enable(allow_run_LCD_scope & user_scope_enable), 
        .captured_data(q), //Insert your channel A signal here
        .reset(1'b1));
        
        //The LCD scope and display
        LCD_Scope_Encapsulated_pacoblaze_wrapper LCD_LED_scope(
                                //LCD control signals
                                .lcd_d(GPIO_0[7:0]),
                                .lcd_rs(GPIO_0[8]),
                                .lcd_rw(GPIO_0[9]),
                                .lcd_e(GPIO_0[10]),
                                .clk(CLK_50M),
                        
                                //LCD Display values
                              .InH(8'hAA),
                              .InG(8'hBB),
                              .InF(8'h01),
                               .InE(8'h23),
                              .InD(8'h45),
                              .InC(8'h67),
                              .InB(8'h89),
                             .InA(8'h00),
                                  
                             //LCD display information signals
                                 .InfoH({scope_info15,scope_info14}),
                                  .InfoG({scope_info13,scope_info12}),
                                  .InfoF({scope_info11,scope_info10}),
                                  .InfoE({scope_info9,scope_info8}),
                                  .InfoD({scope_info7,scope_info6}),
                                  .InfoC({scope_info5,scope_info4}),
                                  .InfoB({scope_info3,scope_info2}),
                                  .InfoA({scope_info1,scope_info0}),
                                  
                          //choose to display the values or the oscilloscope
                                  .choose_scope_or_LCD(choose_LCD_or_SCOPE),
                                  
                          //scope channel declarations
                                  .scope_channelA(scope_channelA), //don't touch
                                  .scope_channelB(scope_channelB), //don't touch
                                  
                          //scope information generation
                                  .ScopeInfoA({character_J,character_space,character_I,character_lowercase_i}),
                                  .ScopeInfoB({character_D,character_A,character_T,character_A}),
                                  
                         //enable_scope is used to freeze the scope just before capturing 
                         //the waveform for display (otherwise the sampling would be unreliable)
                                  .enable_scope(allow_run_LCD_scope) //don't touch
                                  
            );  
       //Character definitions

//numbers
parameter character_0 =8'h30;
parameter character_1 =8'h31;
parameter character_2 =8'h32;
parameter character_3 =8'h33;
parameter character_4 =8'h34;
parameter character_5 =8'h35;
parameter character_6 =8'h36;
parameter character_7 =8'h37;
parameter character_8 =8'h38;
parameter character_9 =8'h39;


//Uppercase Letters
parameter character_A =8'h41;
parameter character_B =8'h42;
parameter character_C =8'h43;
parameter character_D =8'h44;
parameter character_E =8'h45;
parameter character_F =8'h46;
parameter character_G =8'h47;
parameter character_H =8'h48;
parameter character_I =8'h49;
parameter character_J =8'h4A;
parameter character_K =8'h4B;
parameter character_L =8'h4C;
parameter character_M =8'h4D;
parameter character_N =8'h4E;
parameter character_O =8'h4F;
parameter character_P =8'h50;
parameter character_Q =8'h51;
parameter character_R =8'h52;
parameter character_S =8'h53;
parameter character_T =8'h54;
parameter character_U =8'h55;
parameter character_V =8'h56;
parameter character_W =8'h57;
parameter character_X =8'h58;
parameter character_Y =8'h59;
parameter character_Z =8'h5A;

//Lowercase Letters
parameter character_lowercase_a= 8'h61;
parameter character_lowercase_b= 8'h62;
parameter character_lowercase_c= 8'h63;
parameter character_lowercase_d= 8'h64;
parameter character_lowercase_e= 8'h65;
parameter character_lowercase_f= 8'h66;
parameter character_lowercase_g= 8'h67;
parameter character_lowercase_h= 8'h68;
parameter character_lowercase_i= 8'h69;
parameter character_lowercase_j= 8'h6A;
parameter character_lowercase_k= 8'h6B;
parameter character_lowercase_l= 8'h6C;
parameter character_lowercase_m= 8'h6D;
parameter character_lowercase_n= 8'h6E;
parameter character_lowercase_o= 8'h6F;
parameter character_lowercase_p= 8'h70;
parameter character_lowercase_q= 8'h71;
parameter character_lowercase_r= 8'h72;
parameter character_lowercase_s= 8'h73;
parameter character_lowercase_t= 8'h74;
parameter character_lowercase_u= 8'h75;
parameter character_lowercase_v= 8'h76;
parameter character_lowercase_w= 8'h77;
parameter character_lowercase_x= 8'h78;
parameter character_lowercase_y= 8'h79;
parameter character_lowercase_z= 8'h7A;

//Other Characters
parameter character_colon = 8'h3A;          //':'
parameter character_stop = 8'h2E;           //'.'
parameter character_semi_colon = 8'h3B;   //';'
parameter character_minus = 8'h2D;         //'-'
parameter character_divide = 8'h2F;         //'/'
parameter character_plus = 8'h2B;          //'+'
parameter character_comma = 8'h2C;          // ','
parameter character_less_than = 8'h3C;    //'<'
parameter character_greater_than = 8'h3E; //'>'
parameter character_equals = 8'h3D;         //'='
parameter character_question = 8'h3F;      //'?'
parameter character_dollar = 8'h24;         //'$'
parameter character_space=8'h20;           //' '     
parameter character_exclaim=8'h21;          //'!'     
     */       
endmodule

