`timescale 1ps / 1ps

module ifft4_tb;

    // 数据宽度
    parameter DATA_WIDTH = 8;

    // 输入数据
    reg signed [DATA_WIDTH-1:0] in0_real;
    reg signed [DATA_WIDTH-1:0] in0_imag;
    reg signed [DATA_WIDTH-1:0] in1_real;
    reg signed [DATA_WIDTH-1:0] in1_imag;
    reg signed [DATA_WIDTH-1:0] in2_real;
    reg signed [DATA_WIDTH-1:0] in2_imag;
    reg signed [DATA_WIDTH-1:0] in3_real;
    reg signed [DATA_WIDTH-1:0] in3_imag;

    // 输出数据
    wire signed [DATA_WIDTH+1:0] out0_real;
    wire signed [DATA_WIDTH+1:0] out0_imag;
    wire signed [DATA_WIDTH+1:0] out1_real;
    wire signed [DATA_WIDTH+1:0] out1_imag;
    wire signed [DATA_WIDTH+1:0] out2_real;
    wire signed [DATA_WIDTH+1:0] out2_imag;
    wire signed [DATA_WIDTH+1:0] out3_real;
    wire signed [DATA_WIDTH+1:0] out3_imag;

    // 数据有效信号
    wire valid;

    // 仿真时钟
    reg clk = 0;
    always #5 clk = !clk;

    // fft4模块实例化
    ifft4 #(
        .DATA_WIDTH(DATA_WIDTH)
    ) fft4_inst (
        .clk(clk),
        .rst_n(1'b1),
        .en(1'b1),
        .in0_real(in0_real),
        .in0_imag(in0_imag),
        .in1_real(in1_real),
        .in1_imag(in1_imag),
        .in2_real(in2_real),
        .in2_imag(in2_imag),
        .in3_real(in3_real),
        .in3_imag(in3_imag),
        .out0_real(out0_real),
        .out0_imag(out0_imag),
        .out1_real(out1_real),
        .out1_imag(out1_imag),
        .out2_real(out2_real),
        .out2_imag(out2_imag),
        .out3_real(out3_real),
        .out3_imag(out3_imag),
        .valid(valid)
    );

    // 模拟输入数据
    initial begin
        in0_real = 'd1;
        in0_imag = 'd0;
        in1_real =  -2;
        in1_imag = 'd3;
        in2_real =  -1;
        in2_imag = 'd0;
        in3_real =  -2;
        in3_imag =  -3;
        // input   1+j0,-2+j3,-1+j0,-2-j3
        // output -1+j0,-1+j0, 1+j0, 2+j0
        #100 $finish;
    end

    initial begin
        $dumpfile("build/top_ifft4_tb.vcd"); // 指定用作dumpfile的文件
        $dumpvars; // dump all vars
    end

endmodule
