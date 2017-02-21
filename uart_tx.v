/*
 * UART Transmitter Module with Asynchronous Active LOW Reset
 *
 * tx: Output to the RX line
 * busy: Flag that is set HIGH when sending data. Do NOT alter the data variable while this is HIGH
 * data: Contains byte to be written
 * send_data: Set HIGH for one clock cycle to start sending the byte in data
 * 
 *
 * Clock Rate(Hz) = DesiredBaudRate(Hz) * data_width * oversampling_rate
 * 
 * Creator: Addison Elliott
 * Date Created: 02/20/2017
 *
 */
import UART_CONSTANTS::*;
 
module uart_tx #(parameter data_width = 8, oversampling_rate = 8, parity_type = UART_PARITY_NONE, stop_bits = 1) 
	(output tx, busy, input [data_width-1:0] data, input send_data, reset, clock);	
	// Parameters are declared within header because ModelSim threw errors when the data_width parameter was declared
	// AFTER it was used in the module declaration. Quartus Prime compiled it fine though.
	//parameter data_width: Size of each data byte sent (Valid options: 5-8)
	//parameter oversampling_rate: Oversampling rate. Clock must be this many times faster than desired bit rate
	//parameter uart_parity_t parity_type: Parity bit
	//parameter stop_bits: Stop bits (Valid options: 0-2)
	
	localparam IDLE 		= 3'b000,
				  START		= 3'b001,
				  SEND_DATA = 3'b010,
				  PARITY		= 3'b011,
				  STOP		= 3'b100;
	
	reg [3:0] state;
	reg [3:0] counter;
	reg [3:0] bits_read;
	reg tx_reg;
	reg parity; // Represents EVEN parity
	
	initial begin
		state <= IDLE;
		counter <= 4'd0;
		bits_read <= 4'd0;
		tx_reg <= 1'b1;
		parity <= 1'b0;
	end
	
	assign tx = tx_reg;
	assign busy = (state != IDLE);
	
	always @(posedge clock, negedge reset) begin
		if (!reset) begin			
			state <= IDLE;
			counter <= 4'd0;
			bits_read <= 4'd0;
			tx_reg <= 1'b1;
			parity <= 1'b0;
		end
		else begin
			case (state)
				IDLE: begin
					tx_reg <= 1'b1;
				
					if (send_data) begin
						state <= START;
						counter <= 4'd0;
					end
					else begin
						state <= IDLE;
					end
				end
				
				START: begin
					tx_reg <= 1'b0;
					counter = counter + 4'd1;
					
					if (counter == oversampling_rate) begin
						counter <= 4'd0;
						bits_read <= 4'd0;
						state <= SEND_DATA;
					end
				end
				
				SEND_DATA: begin
					tx_reg = data[bits_read];
					counter = counter + 4'd1;
					
					if (counter == oversampling_rate) begin
						bits_read = bits_read + 4'd1;
						counter <= 4'd0;
						parity <= parity ^ tx_reg;
						
						if (bits_read == data_width) begin
							bits_read <= 4'd0;
							
							if (parity_type == UART_PARITY_NONE && stop_bits == 0)
								state <= IDLE;
							else if (parity_type == UART_PARITY_NONE)
								state <= STOP;
							else
								state <= PARITY;
						end
					end
				end
				
				PARITY: begin
					counter = counter + 4'd1;
					tx_reg <= (parity_type == UART_PARITY_EVEN & (parity)) || (parity_type == UART_PARITY_ODD & (~parity)) ||
								 (parity_type == UART_PARITY_MARK & 1'b1) || (parity_type == UART_PARITY_SPACE & 1'b0); 
					
					if (counter == oversampling_rate) begin
						counter <= 4'd0;
						
						if (stop_bits == 0)
							state <= IDLE;
						else
							state <= STOP;
					end
				end
				
				STOP: begin
					tx_reg <= 1'b1;
					counter = counter + 4'd1;
					
					if (counter == oversampling_rate) begin
						bits_read = bits_read + 4'd1;
						counter <= 4'd0;
						
						if (bits_read == stop_bits) begin
							bits_read <= 4'd0;
							state <= IDLE;
						end
					end
				end
				
				default: state <= IDLE;
			endcase
		end
	end
endmodule
