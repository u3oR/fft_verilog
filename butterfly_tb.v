`timescale 1ps/1ps

module butterfly_tb;

	localparam DATA_WIDTH = 8;
    localparam EXPAND = 6; // 默认将旋转因子扩大1<<6=64倍
    
    
    // 定义输入信号
    reg signed [DATA_WIDTH-1:0] in1_real = {DATA_WIDTH{1'b0}};
    reg signed [DATA_WIDTH-1:0] in1_imag = {DATA_WIDTH{1'b0}};
    reg signed [DATA_WIDTH-1:0] in2_real = {DATA_WIDTH{1'b0}};
    reg signed [DATA_WIDTH-1:0] in2_imag = {DATA_WIDTH{1'b0}};
    // 旋转因子
    reg signed [EXPAND+1:0] ro_real  = 'd64;
    reg signed [EXPAND+1:0] ro_imag  = 'd0;

    // 定义输出信号
    wire signed [DATA_WIDTH:0] out1_real;
    wire signed [DATA_WIDTH:0] out1_imag;
    wire signed [DATA_WIDTH:0] out2_real;
    wire signed [DATA_WIDTH:0] out2_imag;
    // 有效性信号
    wire valid;
	
	// 定义模块的实例
    Butterfly #(
        .DATA_WIDTH(DATA_WIDTH),
        .EXPAND(EXPAND)
    ) 
    dut (
        .clk(clk),
        .rst_n(1'b1),
        .en(en),
        .in1_real(in1_real),
        .in1_imag(in1_imag),
        .in2_real(in2_real),
        .in2_imag(in2_imag),
        .ro_real(ro_real),
        .ro_imag(ro_imag),
        .out1_real(out1_real),
        .out1_imag(out1_imag),
        .out2_real(out2_real),
        .out2_imag(out2_imag),
        .valid(valid)
    );
	
    // 时钟信号
    reg clk = 0;
    always #5 clk = ~clk;

    // 设定结束时间点
    initial begin
        #500;
		$finish;
	end

    reg en = 1;
    always #50 en = ~en;
    
    // 设置数据
	initial begin

        forever begin
            in1_real = $random;
            in1_imag = $random;
            in2_real = $random;
            in2_imag = $random;
            #10;
        end

	end
  
	initial begin
		$dumpfile("build/top_butterfly_tb.vcd"); // 指定用作dumpfile的文件
		$dumpvars; // dump all vars
	end

endmodule