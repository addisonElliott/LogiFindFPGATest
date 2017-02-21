`timescale 1 ns / 1 ps

module LogiFindFPGATest_tb();
	wire UART_RX, SEG_DP;
	wire [6:0] SEG;
	wire [3:0] SEG_EN;
	
	reg UART_TX;
	reg [3:0] SW;
	reg CLK_48M;
	
	LogiFindFPGATest UUT(UART_RX, SEG, SEG_EN, SEG_DP, UART_TX, SW, CLK_48M);
	
	initial begin
		UART_TX <= 1'b1;
		SW <= 4'b0000;
		CLK_48M <= 1'b0;
		
		forever begin
			#10.417 CLK_48M <= ~CLK_48M; // 10.417ns = 1/2 * period for 48MHz
		end
	end
	
	// 13021.25ns between positive clock cycles for 76.8KHz signal. Eight of these should give baud rate.
	initial begin
		#41063.75 UART_TX <= 1'b0; // Set low for start bit after 3 clock cycles
		#104166.667 UART_TX <= 1'b1; // Set data bit 0
		#104166.667 UART_TX <= 1'b0; // Set data bit 1
		#104166.667 UART_TX <= 1'b0; // Set data bit 2
		#104166.667 UART_TX <= 1'b0; // Set data bit 3
		#104166.667 UART_TX <= 1'b1; // Set data bit 4
		#104166.667 UART_TX <= 1'b1; // Set data bit 5
		#104166.667 UART_TX <= 1'b0; // Set data bit 6
		#104166.667 UART_TX <= 1'b0; // Set data bit 7
		#104166.667 UART_TX <= 1'b1; // Set stop bit
		#1500000 $stop(); // $stop is less annoying than $finish in ModelSim
	end
endmodule
