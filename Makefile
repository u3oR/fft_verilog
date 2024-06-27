# Encoding: UTF-8

BUILD_DIR = build


butterfly_tb: butterfly_tb.v butterfly.v | build
	iverilog -o $(BUILD_DIR)/top_butterfly_tb $^
	vvp $(BUILD_DIR)/top_butterfly_tb

fft4_tb: fft4_tb.v fft4.v butterfly.v | build
	iverilog -o $(BUILD_DIR)/top_fft4_tb $^
	vvp $(BUILD_DIR)/top_fft4_tb

ifft4_tb: ifft4_tb.v ifft4.v butterfly.v | build
	iverilog -o $(BUILD_DIR)/top_ifft4_tb $^
	vvp $(BUILD_DIR)/top_ifft4_tb

view: butterfly_tb fft4_tb ifft4_tb
	gtkwave top_butterfly_tb.vcd
	gtkwave top_fft4_tb.vcd 
	gtkwave top_ifft4_tb.vcd

build: 
	mkdir $(BUILD_DIR)

