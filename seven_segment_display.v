////////////////////////////////////////////////////
//		Engineer: Addison Elliott
//
//		Date Created: 02/18/2017
//
//		Version: 1.0
//
//
////////////////////////////////////////////////////
//			  (0)
//		   -------
//		   |		|
//		(5)| (6)	|(1)
//		   -------
//		  	|		|
//		(4)|		|(2)
//		   -------
//			  (3)
//
//		1 = on, 0 = off
///////////////////////////////////////////////////
module seven_segment_display(output reg [6:0] segments, output reg [3:0] enable, input [3:0] num1, input [3:0] num2, 
	input [3:0] num3, input [3:0] num4, input clock);
	
	// Constants to output hexadecimal number
	// HIGH = ON, LOW = OFF
	parameter [6:0] NUM_0 = 7'b0111111;
	parameter [6:0] NUM_1 = 7'b0000110;
	parameter [6:0] NUM_2 = 7'b1011011;
	parameter [6:0] NUM_3 = 7'b1001111;
	parameter [6:0] NUM_4 = 7'b1100110;
	parameter [6:0] NUM_5 = 7'b1101101;
	parameter [6:0] NUM_6 = 7'b1111101;
	parameter [6:0] NUM_7 = 7'b0000111;
	parameter [6:0] NUM_8 = 7'b1111111;
	parameter [6:0] NUM_9 = 7'b1101111;
	parameter [6:0] NUM_A = 7'b1110111;
	parameter [6:0] NUM_B = 7'b1111100;
	parameter [6:0] NUM_C = 7'b1011000;
	parameter [6:0] NUM_D = 7'b1011110;
	parameter [6:0] NUM_E = 7'b1111001;
	parameter [6:0] NUM_F = 7'b1110001;
	parameter [6:0] NUM_BLK = 7'b0000000;
	
	// Constants to enable particular segment display. 
	// HIGH = OFF, LOW = ON
	parameter [3:0] EN_1 = 4'b1110;
	parameter [3:0] EN_2 = 4'b1101;
	parameter [3:0] EN_3 = 4'b1011;
	parameter [3:0] EN_4 = 4'b0111;
	parameter [3:0] EN_ALL = 4'b0000;
	
	reg [1:0] state;
	reg [3:0] input_num;
	reg [3:0] input_enable;
	
	initial begin
		state <= 2'b00;
		input_num <= 4'b0000;
		input_enable <= EN_1;
	end
	
	always @(posedge clock)
		if (state == 3)
			state <= 0;
		else
			state <= state + 1'b1;
			
	always @(posedge clock)
		case (state)
			2'b00: begin input_num <= num1; input_enable <= EN_1; end
			2'b01: begin input_num <= num2; input_enable <= EN_2; end
			2'b10: begin input_num <= num3; input_enable <= EN_3; end
			2'b11: begin input_num <= num4; input_enable <= EN_4; end
		endcase
			
	always @(posedge clock) begin
		enable <= input_enable;
		
		case (input_num)
			4'h0: segments <= NUM_0;
			4'h1: segments <= NUM_1;
			4'h2: segments <= NUM_2;
			4'h3: segments <= NUM_3;
			4'h4: segments <= NUM_4;
			4'h5: segments <= NUM_5;
			4'h6: segments <= NUM_6;
			4'h7: segments <= NUM_7;
			4'h8: segments <= NUM_8;
			4'h9: segments <= NUM_9;
			4'hA: segments <= NUM_A;
			4'hB: segments <= NUM_B;
			4'hC: segments <= NUM_C;
			4'hD: segments <= NUM_D;
			4'hE: segments <= NUM_E;
			4'hF: segments <= NUM_F;
			default: segments <= NUM_BLK;
		endcase
	end
endmodule
