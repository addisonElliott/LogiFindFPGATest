`timescale 1 ns / 1 ps

module IR_tb();
	wire [7:0] address, data;
	wire data_ready;
	
	reg IR, CLK_48M, CLK_1M;
	
	reg [7:0] addressSend;
	reg [7:0] dataSend;
	
	ir_module UUT(address, data, data_ready, IR, 1'b1, CLK_1M);
	
	defparam UUT.multiplier = 1;
	defparam UUT.divider = 1;
	defparam UUT.counter_width = 16;
	defparam UUT.address_width = 8;
	defparam UUT.data_width = 8;
	
	initial begin
		IR <= 1'b1;
		CLK_48M <= 1'b0;
		CLK_1M <= 1'b0;
		
		addressSend = 8'h00;
		dataSend = 8'h42;
		
		forever begin
			#10.417 CLK_48M <= ~CLK_48M; // 10.417ns = 1/2 * period for 48MHz
		end
	end
	
	initial begin
		CLK_1M <= 1'b0;
		
		forever begin
			#500 CLK_1M <= ~CLK_1M; // 500ns = 1/2 * period for 48MHz
		end
	end
	
	// 13021.25ns between positive clock cycles for 76.8KHz signal. Eight of these should give baud rate.
	initial begin
		#100000 // Wait 10 cycles before actually doing something
		IR <= 1'b0; #9000000 // Set to LOW for 9ms, START_MARK
		IR <= 1'b1; #4500000 // Set to HIGH for 4.5ms, START_SPACE
		
		// I am going to transmit: Address: 0x00, Data: 0x42
		// Address: 
		// Data: 
		
		// Code 0
		// IR <= 1'b0; #562500
		// IR <= 1'b1; #562500
		
		// Code 1
		// IR <= 1'b0; #562500
		// IR <= 1'b1; #1687500
		
		for (integer i = 0; i < 8; i=i+1) begin
			if (addressSend[i]) begin
				// Code 1
				IR <= 1'b0; #562500;
				IR <= 1'b1; #1687500;		
			end
			else begin
				// Code 0
				IR <= 1'b0; #562500;
				IR <= 1'b1; #562500;		
			end
		end
		
		for (integer i = 0; i < 8; i=i+1) begin
			if (!addressSend[i]) begin
				// Code 1
				IR <= 1'b0; #562500;
				IR <= 1'b1; #1687500;		
			end
			else begin
				// Code 0
				IR <= 1'b0; #562500;
				IR <= 1'b1; #562500;		
			end
		end
		
		for (integer i = 0; i < 8; i=i+1) begin
			if (dataSend[i]) begin
				// Code 1
				IR <= 1'b0; #562500;
				IR <= 1'b1; #1687500;		
			end
			else begin
				// Code 0
				IR <= 1'b0; #562500;
				IR <= 1'b1; #562500;		
			end
		end
		
		for (integer i = 0; i < 8; i=i+1) begin
			if (!dataSend[i]) begin
				// Code 1
				IR <= 1'b0; #562500;
				IR <= 1'b1; #1687500;		
			end
			else begin
				// Code 0
				IR <= 1'b0; #562500;
				IR <= 1'b1; #562500;		
			end
		end
		
		// STOP_MARK
		IR <= 1'b0; #562500;
		IR <= 1'b1;

		#1500000 $stop(); // $stop is less annoying than $finish in ModelSim
	end
endmodule
