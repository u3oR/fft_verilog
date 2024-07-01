# Encoding: UTF-8

BUILD_DIR = build


butterfly_tb: $(BUILD_DIR)/top_butterfly_tb.vcd
 gtkwave $<

$(BUILD_DIR)/top_butterfly_tb.vcd: butterfly_tb.v butterfly.v | build
	iverilog -o $(BUILD_DIR)/top_butterfly_tb $^
	vvp $(BUILD_DIR)/top_butterfly_tb


fft4_tb: $(BUILD_DIR)/top_fft4_tb.vcd
 gtkwave $<

$(BUILD_DIR)/top_fft4_tb.vcd: fft4_tb.v fft4.v butterfly.v | build
	iverilog -o $(BUILD_DIR)/top_fft4_tb $^
	vvp $(BUILD_DIR)/top_fft4_tb


ifft4_tb: $(BUILD_DIR)/top_ifft4_tb.vcd
 gtkwave $<

$(BUILD_DIR)/top_ifft4_tb.vcd: ifft4_tb.v ifft4.v butterfly.v | build
	iverilog -o $(BUILD_DIR)/top_ifft4_tb $^
	vvp $(BUILD_DIR)/top_ifft4_tb


build: 
	mkdir -p $(BUILD_DIR)

