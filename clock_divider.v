module clock_divider(output reg new_clock, input clock);
	parameter divider = 32'd1;
	
	reg [31:0] counter;
	
	initial begin
		counter <= 32'd0;
		new_clock <= 1'b0;
	end
	
	always @(posedge clock)
		if (counter == divider / 2) begin
			counter <= 0;
			new_clock <= ~new_clock;
		end
		else
			counter <= counter + 1;
endmodule