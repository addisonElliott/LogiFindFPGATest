add wave *
add wave -internal /LogiFindFPGATest_tb/UUT/*
add wave -divider "UART Receiver"
add wave -internal /LogiFindFPGATest_tb/UUT/uart_rx_inst/*
add wave -divider "UART Transmitter"
add wave -internal /LogiFindFPGATest_tb/UUT/uart_tx_inst/*

run -all