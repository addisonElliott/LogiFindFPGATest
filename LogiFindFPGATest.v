/*
 * Objective: This module tests the push button switches, LEDs, and buzzer. The four LEDs are set if their corresponding
 * push button switch is held down. Additionally, if SW2 is pressed down a 4kHz tone is emitted from the buzzer.
 *
 * Description: On each positive clock edge, the LEDs are set to the SW values. A 4kHz clock is created for the buzzer.
 * The buzzer output is set to the 4kHz clock if SW2 is pressed down, otherwise it is set to high impedance (OFF). 
 *
 * How to Use: Press down SW1 through SW4 to see the corresponding LEDs light up. In addition, press and hold SW2 to hear
 * a 4kHz tone from the buzzer.
 */
/*module LogiFindFPGATest(output BUZZER, output reg [3:0] LED, input [3:0] SW, input CLK_48M);
	wire CLK_4K;
	
	always @(posedge CLK_48M)
		LED <= SW;
	
	clock_divider #(32'd9400) clock_divider1(CLK_4K, CLK_48M);
	
	assign BUZZER = ~SW[1] ? CLK_4K : 1'bz;
endmodule*/

/*
 * Objective: This module tests the 4-digit seven segment display module by using the push switches to increment
 *	separate hexadecimal counters on each of the digits. The decimal points on the display are turned off by default.
 *
 * Description: The 4-bit registers num1 through num4 are the counters for each digit on the seven segment display. 
 * A 1kHz clock is created that is used to synchronize the switches(acts as a debouncer essentially) and for 
 * controlling the 4x7 display.
 *
 * How to Use: Press down SW1 through SW4 to increment each digit on the segment display. The hexadecimal digits A-F look
 * a bit weird because they use capital/lowercase to display the information. E.G. capital B would look like 8, lowercase
 * a would look wrong, etc. The numbers are only incremented on the negative edge of the switch signal (active LOW).
 */
/*module LogiFindFPGATest(output [6:0] SEG, output [3:0] SEG_EN, output SEG_DP, input [3:0] SW, input CLK_48M);
	reg [3:0] num1, num2, num3, num4;
	
	// Synchronize the corresponding wires to a clock with these registers
	reg [3:0] SW_reg;
	
	wire CLK_1K;
	
	initial begin
		num1 <= 4'b0000;
		num2 <= 4'b0000;
		num3 <= 4'b0000;
		num4 <= 4'b0000;
		
		SW_reg <= 4'b1111; // Initialize to HIGH because switches are active LOW
	end
	
	// Create 1kHz clock by dividing 48MHz clock by 48k
	clock_divider #(32'd48_000) clock_divider1(CLK_1K, CLK_48M);
	
	// Synchronize switches to 1kHz clock, this essentially is a debouncer assuming the clock frequency is low enough
	always @(posedge CLK_1K) begin
		SW_reg <= SW;
	end
	
	// Detect switches pressed down, increment respective digit on seven segment display
	always @(posedge SW_reg[0])
		num1 <= num1 + 1'b1;
	
	always @(posedge SW_reg[1])
		num2 <= num2 + 1'b1;
	
	always @(posedge SW_reg[2])
		num3 <= num3 + 1'b1;
		
	always @(posedge SW_reg[3])
		num4 <= num4 + 1'b1;
		
	// Instantiate 4x7 segment display
	seven_segment_display seven_segment_display1(SEG, SEG_EN, num1, num2, num3, num4, CLK_1K);
endmodule*/


/*
 * Objective: This module tests UART and IR receiver module by using the segment display module to show the values
 * entered through UART or from the IR remote.
 *
 * Description: The first digit, closest to the VGA connector, is set to report a hexadecimal number that was last entered
 * via the UART COM port. The third and fourth digit are set to report the last code entered by the IR receiver module.
 * The code is an 8 bit hexadecimal number.
 *
 * How to Use: While the software is running, look in device manager for available COM ports. You should see a device named
 * "Prolific USB-to-Serial Comm Port." Record the COM port (e.g. COM7, COM8) that the device is on. If you do not see this
 * com port, then you must install the driver supplied in the user manual. A basic google search for PL2303 USB driver will
 * also give you want you want. Next, open a serial console like PuTTy or RealTerm and connect to that com port recorded with
 * these settings:
 *		Baud Rate: 9600
 *		Data Bits: 8
 *		Stop Bits: 1
 *		Parity: None
 *
 *	Everything else can be left alone. Click connect and start typing in characters. First, you should see the characters being
 * displayed back on your console. This is because the FPGA is decoding the data sent, and then retransmitting that character correctly.
 * It may seem like the computer itself is recording it, but it is actually being forwarded through the FPGA. Next, if you press a valid
 * hexadecimal digit(uppercase or lowercase), it will display on digit 1 on the segment display.
 *
 * Next, get your IR remote, make sure you take the plastic piece out from the battery port so its on and press some buttons while
 * pointing the remote to the IR receiver (right beside segment display and gold SMA connector). You should see the hexadecimal digit
 * displayed on the segment display, digits 3 and 4.
 */
import UART_CONSTANTS::*;
 
module LogiFindFPGATest(output UART_RX, output [6:0] SEG, output [3:0] SEG_EN, output SEG_DP, input UART_TX, 
	input IR_DATA, input [3:0] SW, input CLK_48M);
	reg [3:0] num1, num2, num3, num4;
	
	// Synchronize the corresponding wires to a clock with these registers
	reg [3:0] SW_reg;
	
	wire CLK_1K;
	
	wire CLK_76K8 /*synthesis keep*/; // You can put the synthesis comment on any variable and Altera wont optimize it out for simulation and such
	wire uart_rx_ready;
	wire [7: 0] uart_rx_byte;
	wire uart_tx_busy;
	reg uart_tx_send;
	wire [7: 0] uart_tx_byte;
	
	wire CLK_1M;
	wire [7:0] ir_address;
	wire [7:0] ir_data;
	wire ir_data_ready, ir_error;
	
	initial begin
		num1 <= 4'b0000;
		num2 <= 4'b0000;
		num3 <= 4'b0000;
		num4 <= 4'b0000;
		
		SW_reg <= 4'b1111; // Initialize to HIGH because switches are active LOW
		uart_tx_send <= 1'b0;
	end
	
	wire CLK_1;
	clock_divider #(32'd48_000_000) clock_divider2(CLK_1, CLK_48M);
	
	clock_divider #(32'd48_000) clock_divider1(CLK_1K, CLK_48M);
	
	// Synchronize switches to 1kHz clock, this essentially is a debouncer assuming the clock frequency is low enough
	always @(posedge CLK_1K) begin
		SW_reg <= SW;
	end
	
	// Detect switches pressed down, increment respective digit on seven segment display
	/*always @(posedge SW_reg[0])
		num1 <= num1 + 1'b1;
	
	always @(posedge SW_reg[1])
		num2 <= num2 + 1'b1;
	
	always @(posedge SW_reg[2])
		num3 <= num3 + 1'b1;
		
	always @(posedge SW_reg[3])
		num4 <= num4 + 1'b1;*/
	
	seven_segment_display seven_segment_display1(SEG, SEG_EN, num1, num2, num3, num4, CLK_1K);
	assign SEG_DP = 1'b0;
	
	// Instantiate General PLL clock, use this if you want to add additional clock outputs
	pll pll_inst(1'b0, CLK_48M, CLK_1M);
	
	// Instantiate the IR receiver module
	ir_module ir_module_inst(ir_address, ir_data, ir_data_ready, ir_error, IR_DATA, 1'b1, CLK_1M);
	
	// These parameters are not needed but I supply to show what can be changed. These are the defaults
	defparam ir_module_inst.multiplier = 1;
	defparam ir_module_inst.divider = 1;
	defparam ir_module_inst.counter_width = 16;
	defparam ir_module_inst.address_width = 8;
	defparam ir_module_inst.data_width = 8;
	
	// Generate a 76.8kHz clock for UART system
	// Baud rate: 9600bps, Oversampling Rate: 8x
	// PLL is active HIGH reset while uart_rx module is active LOW
	uart_pll_9600 uart_pll_inst(1'b0, CLK_48M, CLK_76K8);
	uart_rx uart_rx_inst(uart_rx_byte, uart_rx_ready, UART_TX, 1'b1,  CLK_76K8);
	uart_tx uart_tx_inst(UART_RX, uart_tx_busy, uart_tx_byte, uart_tx_send, 1'b1, CLK_76K8);
	
	defparam uart_rx_inst.data_width = 8;
	defparam uart_rx_inst.parity_type = UART_PARITY_NONE;
	defparam uart_rx_inst.stop_bits = 1;
	
	defparam uart_tx_inst.data_width = 8;
	defparam uart_tx_inst.parity_type = UART_PARITY_NONE;
	defparam uart_tx_inst.stop_bits = 1;
	
	// For a general test, this will loopback all characters sent to device back to sender.
	// If using this, disable uart_rx_inst and uart_tx_inst by commenting them out
	//assign UART_RX = UART_TX;
	
	assign uart_tx_byte = uart_rx_byte;
	
	always @(posedge CLK_76K8) begin
		if (uart_tx_send)
			uart_tx_send <= 1'b0;
		
		if (uart_rx_ready) begin
			if (uart_rx_byte >= "0" && uart_rx_byte <= "9") begin
				num1 <= uart_rx_byte[3:0];
			end
			else if (uart_rx_byte >= "a" && uart_rx_byte <= "f") begin
				num1 <= (uart_rx_byte[3:0] - 4'h1) + 4'hA;
			end
			else if (uart_rx_byte >= "A" && uart_rx_byte <= "F") begin
				num1 <= (uart_rx_byte[3:0] - 4'h1) + 4'hA;
			end
			
			// if (uart_tx_busy)
			// 	Do something for error
			uart_tx_send <= 1'b1;
		end
		
		// If there is data ready to be received from the IR module, set the 3rd and 4th digits of the segment display
		if (ir_data_ready) begin
			{num4, num3} <= ir_data;
		end
	end
endmodule

