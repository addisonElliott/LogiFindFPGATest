/*
 * UART Receiver Module with Asynchronous Active LOW Reset
 *
 * data: Contains byte that was read 
 * data_ready: Set to HIGH when data has been received
 * rx: Input to the RX line
 *
 * Clock Rate(Hz) = DesiredBaudRate(Hz) * data_width * oversampling_rate
 * 
 * Creator: Addison Elliott
 * Date Created: 02/18/2017
 *
 */
 
package UART_CONSTANTS;
typedef enum 
{
	UART_PARITY_NONE 	= 0,
	UART_PARITY_EVEN 	= 1,
	UART_PARITY_ODD		= 2,
	UART_PARITY_MARK		= 3,
	UART_PARITY_SPACE	= 4	
} uart_parity_t;
endpackage : UART_CONSTANTS

import UART_CONSTANTS::*;

module uart_rx #(parameter data_width = 8, oversampling_rate = 8, parity_type = UART_CONSTANTS::UART_PARITY_NONE, stop_bits = 1) 
	(output [data_width-1:0] data, output data_ready, input rx, reset, clock);	
	// Parameters are declared within header because ModelSim threw errors when the data_width parameter was declared
	// AFTER it was used in the module declaration. Quartus Prime compiled it fine though.
	//parameter data_width: Size of each data byte sent (Valid options: 5-8)
	//parameter oversampling_rate: Oversampling rate. Clock must be this many times faster than desired bit rate
	//parameter uart_parity_t parity_type: Parity bit
	//parameter stop_bits: Stop bits (Valid options: 0-2)
	
	localparam IDLE 		= 3'b000,
				  READ_DATA = 3'b001,
				  PARITY		= 3'b010,
				  STOP		= 3'b011,
				  DONE		= 3'b100,
				  ERROR		= 3'b101;
	
	reg [3:0] state;
	reg [3:0] counter;
	reg [3:0] bits_read;
	reg [data_width-1: 0] data_reg;
	reg data_ready_reg;
	reg parity; // Represents EVEN parity
	
	initial begin
		state <= IDLE;
		counter <= 4'd0;
		bits_read <= 4'd0;
		data_reg <= {data_width{1'b0}};
		data_ready_reg <= 1'b0;
		parity <= 1'b0;
	end
	
	assign data = data_reg;
	assign data_ready = data_ready_reg;
	
	always @(posedge clock, negedge reset) begin
		if (!reset) begin
			state <= IDLE;
			counter <= 4'd0;
			bits_read <= 4'd0;
			data_reg <= {data_width{1'b0}};
			data_ready_reg <= 1'b0;
			parity <= 1'b0;
		end
		else begin
			case (state)
				IDLE: begin
					if (!rx)
						counter = counter + 4'd1;
					else
						counter = 4'd0;
						
					// We only wait for half of the bit time so that we are in the "middle" of each transition.
					// Now, we simply wait a bit time for each bit and read at the end of the bit time
					if (counter == oversampling_rate / 2) begin
						state <= READ_DATA;
						counter <= 4'd0;
						bits_read <= 4'd0;
						parity <= 1'b0;
					end
					else
						state <= IDLE;
						
					data_ready_reg <= 1'b0;
				end
				
				READ_DATA: begin
					counter = counter + 4'd1;
					
					if (counter == oversampling_rate) begin
						if (bits_read == data_width - 1) begin
							parity <= parity ^ rx;
							counter <= 4'd0;
							bits_read <= 4'd0;
							
							data_reg = {rx, data_reg[data_width-1:1]};
							
							if (parity_type == UART_PARITY_NONE)
								state = DONE;
							else 
								state = PARITY;
						end
						else begin						
							data_reg <= {rx, data_reg[data_width-1:1]};
							counter <= 4'd0;
							parity <= parity ^ rx;
							bits_read <= bits_read + 4'd1;
						end
					end
				end
				
				PARITY: begin
					counter = counter + 4'd1;
					
					if (counter == oversampling_rate) begin
					
						if ((parity_type == UART_PARITY_EVEN & (rx == parity)) |
							(parity_type == UART_PARITY_ODD & (rx == ~parity)) |
							(parity_type == UART_PARITY_MARK & rx) |
							(parity_type == UART_PARITY_SPACE & ~rx)) begin
							// Everything went OK with parity
							state <= DONE;
						end
						else begin
							state <= ERROR;
						end
						
						counter <= 4'd0;
					end
				end
				
				DONE: begin
					counter = counter + 4'd1;
					data_ready_reg <= 1'b1;
					
					// Wait for half a cycle to begin the stop bit.
					// Dont bother reading the stop bit since it doesnt matter
					// Since we get to this state from READ_DATA or PARITY, the state is changed in the middle of the
					// bit being transmitted, so we need to wait another half cycle to actually go back to IDLE
					if (counter == oversampling_rate / 2) begin
						state <= IDLE;
						counter <= 4'd0;
					end
				end
				
				ERROR: begin
					counter = counter + 4'd1;
					
					// Wait for half a cycle to begin the stop bit.
					// Dont bother reading the stop bit since it doesnt matter
					// Since we get to this state from READ_DATA or PARITY, the state is changed in the middle of the
					// bit being transmitted, so we need to wait another half cycle to actually go back to IDLE
					if (counter == oversampling_rate / 2) begin
						state <= IDLE;
						counter <= 4'd0;
					end
				end
				
				default: state <= IDLE;
			endcase
		end
	end
endmodule
