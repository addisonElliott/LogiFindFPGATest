/*
 *		Engineer: Addison Elliott
 *
 *		Date Created: 02/20/2017
 *
 *		Version: 1.0
 *
 *		This IR receiver follows the NEC protocol. This module could easily be extended to support other infrared protocols
 *		There is even potential to expand this module to support extended NEC where the address is 16-bits instead of 8-bits.
 *
 *		Note: A mark, A.K.A logical 1 is when the IR LED is turned on at a particular carrier frequency
 *		Since the receiver consists of a phototransistor, the OUT line is pulled to GND when IR LED is on
 *		Thus, a mark equals logic LOW and space equals logic HIGH for a receiver module.
 *
 *		Address: Byte that returns the address of device that the code is meant for. This address refers to receiving
 *		device address.
 *		Code: The code that is being sent to the device. Common key codes from IR modules can be found online
 *		Data_ready: This is a status indicator which will go HIGH for one clock cycle when data is ready to be read.
 *		Error: This is a status indicator that will go HIGH when there was an error reading a command. This will stay high
 *		until the IR line is consistently HIGH for 9ms. Thus, it ignores the command being sent and waits for next one
 *		IR: This is the pin connected  to the IR receiver module
 *		Reset: Asynchronous active LOW reset that will reset the module
 *		Clock: This is a synchronous module and so the IR pin is read on each posedge of the clock
 *
 *		Note: The clock is also used as timing and thus the clock speed must be known. The clock is referenced to a 
 *		1MHz clock and can be configured by multiplier and divider parameters. The necessary multiplier and divider parameters
 *		can be calculated based on the equation below.
 *
 *		The counter_width parameter is the size of the counter that is used for timing. The largest number, which is 
 *		START_MARK_TIME should be able to fit in a register of width data_width (Max value: 2^data_width - 1). Don't forget
 *		to take into consideration the tolerance parameter.
 *
 *		Supplied Clock Frequency * Multiplier / Divider = 1MHz;
 *
 *		Address width should either be 8 bits or 16 bits. 8 bits is standard NEC protocol where the address is sent and then
 *		the address inverted for error checking. However, extended NEC allows for one 16-bit number with no error checking.
 *
 *		Similarly to address width, the data width sets the width, either 8 bits or 16 bits, when reading. Error checking is
 *		performed with 8 bits by sending the inverted byte again. The 8 bits is technically what the NEC standard uses.
 */
module ir_module #(parameter multiplier = 1, divider = 1, counter_width = 16, data_width = 8, address_width = 8, tolerance = 0.15)
		(output [address_width-1:0] address, output [7:0] data, output data_ready, output error, input IR, reset, clock);
	
	// Nominal Values without tolerance added
	localparam START_MARK_TIME = 9000 * divider / multiplier; // 9ms
	localparam START_SPACE_TIME = 4500 * divider / multiplier; // 4.5ms
	localparam CODE_0_TIME = (562.5 + 562.5) * divider / multiplier; // 1.125ms
	localparam CODE_1_TIME = (1687.5 + 562.5) * divider / multiplier; // 2.25ms
	
	// LB = Lower Bound taking into consideration tolerance
	// UB = Upper Bound taking into consideration tolerance
	// The timing constraints must be within the upper bound and lower bound to be considered valid
	localparam START_MARK_TIME_LB = int'(START_MARK_TIME * (1.0 - tolerance));
	localparam START_MARK_TIME_UB = int'(START_MARK_TIME * (1.0 + tolerance));
	localparam START_SPACE_TIME_LB = int'(START_SPACE_TIME * (1.0 - tolerance));
	localparam START_SPACE_TIME_UB = int'(START_SPACE_TIME * (1.0 + tolerance));
	localparam CODE_0_TIME_LB = int'(CODE_0_TIME * (1.0 - tolerance));
	localparam CODE_0_TIME_UB = int'(CODE_0_TIME * (1.0 + tolerance));
	localparam CODE_1_TIME_LB = int'(CODE_1_TIME * (1.0 - tolerance));
	localparam CODE_1_TIME_UB = int'(CODE_1_TIME * (1.0 + tolerance));
	
	localparam START_MARK 			= 4'b0000,
				  START_SPACE			= 4'b0001,
				  READ_ADDRESS			= 4'b0010,
				  READ_ADDRESS_INV	= 4'b0011,
				  READ_DATA				= 4'b0100,
				  READ_DATA_INV		= 4'b0101,
				  STOP_MARK				= 4'b0110,
				  DONE					= 4'b0111,
				  ERROR					= 4'b1000;
				  
	reg [4:0] state;
	reg [counter_width-1:0] counter;
	reg [4:0] bits_read;
	reg [7:0] address_reg, data_reg;
	reg data_ready_reg;
	reg error_reg;
	
	// Store the previous value of the IR sensor
	// If switching from LOW to HIGH or HIGH to LOW, then 
	// there has been a positive edge or negative edge, respectively
	reg IR_prev;
	wire IR_posedge, IR_negedge;
	
	initial begin
		state <= START_MARK;
		counter <= {data_width{1'b0}};
		bits_read <= 5'd0;
		address_reg <= 8'd0;
		data_reg <= 8'd0;
		data_ready_reg <= 1'b0;
		error_reg <= 1'b0;
		IR_prev <= 1'b1;
	end
	
	assign IR_posedge = (IR & ~IR_prev);
	assign IR_negedge = (~IR & IR_prev);
	
	assign address = address_reg;
	assign data = data_reg;
	assign data_ready = data_ready_reg;
	assign error = error_reg;
	
	always @(posedge clock, negedge reset) begin
		if (!reset) begin
			state <= START_MARK;
			counter <= {data_width{1'b0}};
			bits_read <= 5'd0;
			address_reg <= 8'd0;
			data_reg <= 8'd0;
			data_ready_reg <= 1'b0;
			error_reg <= 1'b0;
			IR_prev <= 1'b1;
		end
		else begin
			case (state)
				START_MARK: begin
					if (!IR)
						counter = counter + 1;
					else begin
						if (counter >= START_MARK_TIME_LB && counter <= START_MARK_TIME_UB) begin
							state <= START_SPACE;
							bits_read <= 5'd0;
							counter <= 0;
						end
						else if (counter >= START_MARK_TIME_UB) begin
							state <= ERROR;
						end
						else begin
							counter <= 0;
						end
					end
					
					data_ready_reg <= 1'b0;
					error_reg <= 1'b0;
				end
				
				START_SPACE: begin
					if (IR)
						counter = counter + 1;
					else begin
						if (counter >= START_SPACE_TIME_LB && counter <= START_SPACE_TIME_UB)
							state <= READ_ADDRESS;
						else
							state <= ERROR;
						
						bits_read <= 5'd0;
						counter <= 0;
					end
					
					data_ready_reg <= 1'b0;
					error_reg <= 1'b0;
				end
				
				READ_ADDRESS: begin
					counter = counter + 1;
					
					if (IR_negedge) begin
						if (counter >= CODE_0_TIME_LB && counter <= CODE_0_TIME_UB) begin
							address_reg <= {1'b0, address_reg[7:1]};
							bits_read = bits_read + 1;
						end
						else if (counter >= CODE_1_TIME_LB && counter <= CODE_1_TIME_UB) begin
							address_reg <= {1'b1, address_reg[7:1]};
							bits_read = bits_read + 1;
						end
						else begin
							state <= ERROR;
						end
						
						if (bits_read == address_width) begin
							state <= (address_width == 16) ? READ_DATA : READ_ADDRESS_INV;
							bits_read <= 5'd0;
						end
						
						counter = 0;
					end
					
					data_ready_reg <= 1'b0;
					error_reg <= 1'b0;
				end
				
				READ_ADDRESS_INV: begin
					counter = counter + 1;
					
					if (IR_negedge) begin						
						if ((address_reg[bits_read] && counter >= CODE_0_TIME_LB && counter <= CODE_0_TIME_UB) ||
							(!address_reg[bits_read] && counter >= CODE_1_TIME_LB && counter <= CODE_1_TIME_UB)) begin
							// Inverted value matches correct value
							bits_read = bits_read + 1;
							
							if (bits_read == 8) begin
								state <= READ_DATA;
								bits_read <= 5'd0;
							end
						end
						else begin
							state <= ERROR;
						end
						
						counter <= 0;
					end
					
					data_ready_reg <= 1'b0;
					error_reg <= 1'b0;
				end
				
				READ_DATA: begin
					counter = counter + 1;
					
					if (IR_negedge) begin
						if (counter >= CODE_0_TIME_LB && counter <= CODE_0_TIME_UB) begin
							data_reg <= {1'b0, data_reg[7:1]};
							bits_read = bits_read + 1;
						end
						else if (counter >= CODE_1_TIME_LB && counter <= CODE_1_TIME_UB) begin
							data_reg <= {1'b1, data_reg[7:1]};
							bits_read = bits_read + 1;
						end
						else begin
							state <= ERROR;
						end
						
						if (bits_read == data_width) begin
							state <= (data_width == 16) ? STOP_MARK : READ_DATA_INV;
							bits_read <= 5'd0;
						end
						
						counter = 0;
					end
					
					data_ready_reg <= 1'b0;
					error_reg <= 1'b0;
				end
				
				READ_DATA_INV: begin
					counter = counter + 1;
					
					if (IR_negedge) begin						
						if ((data_reg[bits_read] && counter >= CODE_0_TIME_LB && counter <= CODE_0_TIME_UB) ||
							(!data_reg[bits_read] && counter >= CODE_1_TIME_LB && counter <= CODE_1_TIME_UB)) begin
							// Inverted value matches correct value
							bits_read = bits_read + 1;
							
							if (bits_read == 8) begin
								state <= STOP_MARK;
								bits_read <= 5'd0;
							end
						end
						else begin
							state <= ERROR;
						end
						
						counter <= 0;
					end
					
					data_ready_reg <= 1'b0;
					error_reg <= 1'b0;
				end
				
				STOP_MARK: begin
					// The stop mark is 562.5uS, so we will just wait until it goes HIGH and then switch states
					if (IR)
						state <= DONE;
						
					data_ready_reg <= 1'b0;
					error_reg <= 1'b0;
				end
				
				DONE: begin
					state <= START_MARK;
					data_ready_reg <= 1'b1;
					error_reg <= 1'b0;
				end
				
				ERROR: begin
					if (IR)
						counter = counter + 1;
					else
						counter = 0;
					
					// If there was an error, wait for the IR line to be HIGH for ~9ms. Then start the state machine over
					if (counter >= START_MARK_TIME) begin
						state <= START_MARK;
						counter = 0;
					end
					
					data_ready_reg <= 1'b0;
					error_reg <= 1'b1;
				end
				
				default: state <= START_MARK;
			endcase
			
			IR_prev <= IR;
		end
	end
endmodule
