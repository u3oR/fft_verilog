
module Butterfly #(
	parameter DATA_WIDTH = 4,// 默认位宽为
    parameter EXPAND = 9 // 默认将旋转因子扩大1<<9=512倍
)(
    input wire clk,
    input wire rst_n,
    input wire en,

    // Input 1 and Input 2
    input wire signed [DATA_WIDTH-1:0] in1_real,
    input wire signed [DATA_WIDTH-1:0] in1_imag,
    input wire signed [DATA_WIDTH-1:0] in2_real,
    input wire signed [DATA_WIDTH-1:0] in2_imag,
    // rotation factor
    // 多出的1位用于存放符号位
    input wire signed [EXPAND+1:0] ro_real,
    input wire signed [EXPAND+1:0] ro_imag,
    // Output 1 and Output 2
    // 输出要比输入多富余出一个位宽
    output wire signed [DATA_WIDTH:0] out1_real,
    output wire signed [DATA_WIDTH:0] out1_imag,
    output wire signed [DATA_WIDTH:0] out2_real,
    output wire signed [DATA_WIDTH:0] out2_imag,
    // 
    output wire valid

);
    //因为有3级流水线,故为每一级流水线计算富余出一个位宽,确保精度
	localparam PRECISION = 3;

	// localparam EXPAND = 13;
	
    // initial begin
    //     valid <= 'b0;
    // end


	reg [4:0] en_r;
	
    // 每次将en的值保存到en_r寄存器的最低位,
    // 保存en的值用于判断当流水线计算完毕输出时的数据是否是在en置位时的输入的,
	// 这样是为了判断输出是否合法.
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            en_r <= 'b0;
        end else begin
            en_r <= {en_r[3:0], en};// 保存en的值到en_r寄存器的最低位
        end
    end

    /*
     * 整个过程分为三级计算.
     * 
     * 第一步当然是要先计算x2 和 ro 的乘积的系数.
     * 假设x2 = x2_r + i * x2_i;ro = ro_r + i * ro_i;
     * 假设这两个虚数计算的结果是 rod = rod_r + i * rod_i;
     * 计算过程如下:
     * rod = x2 * ro;
     * 即 rod = (x2_r + i * x2_i) * (ro_r + i * ro_i);
     * 整理后 rod = (x2_r * ro_r - x2_i * ro_i) + i * (x2_r * ro_i + x2_i * ro_r);
     * 
     * 第一级就是 在给定x2和ro(旋转因子)后,通过上式计算四个乘积的结果;
     * 
     * 第二级就是 将这四个乘积结果进行加减组合后得出rod = rod_r + i * rod_i的过程.具体过程如下:
     * rod_r = x2_r * ro_r - x2_i * ro_i;
     * rod_i = x2_r * ro_i + x2_i * ro_r;
     * 
     * 第三级则是 将x1和rod进行加减计算的过程.假设结果是y1和y2,具体过程如下:
     * y1 = x1 + rod = (x1_r + rod_r) + i * (x1_i + rod_i)
     * y2 = x1 - rod = (x1_r - rod_r) + i * (x1_i - rod_i)
     */

    //====================================//
    // 第一级 只计算in2和ro(旋转因子)的乘积系数;不计算in1,只将其保存下来。

    reg signed [PRECISION+DATA_WIDTH+EXPAND-1:0] rod_real_0;
    reg signed [PRECISION+DATA_WIDTH+EXPAND-1:0] rod_real_1;
    reg signed [PRECISION+DATA_WIDTH+EXPAND-1:0] rod_imag_0;
    reg signed [PRECISION+DATA_WIDTH+EXPAND-1:0] rod_imag_1;

    reg signed [PRECISION+DATA_WIDTH+EXPAND-1:0] in1_real_d;
    reg signed [PRECISION+DATA_WIDTH+EXPAND-1:0] in1_imag_d;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rod_real_0 <= 'b0;
            rod_real_1 <= 'b0;
            rod_imag_0 <= 'b0;
            rod_imag_1 <= 'b0;
            in1_real_d <= 'b0;
            in1_imag_d <= 'b0;
        end else if(en) begin
            // 这里计算in2 * ro(旋转因子) 的计算结果
            rod_real_0 <= in2_real * ro_real;
            rod_real_1 <= in2_imag * ro_imag;
            rod_imag_0 <= in2_real * ro_imag;
            rod_imag_1 <= in2_imag * ro_real;
            // 保存in1的值,并对其进行移位扩展
            in1_real_d <= in1_real <<< EXPAND;
            in1_imag_d <= in1_imag <<< EXPAND;
        end
    end

    //====================================//
    // 第二级 组合in2和ro(旋转因子)的乘积系数, 仍然不计算in1
    reg signed [PRECISION+DATA_WIDTH+EXPAND-1:0] rod_real;
    reg signed [PRECISION+DATA_WIDTH+EXPAND-1:0] rod_imag;
    reg signed [PRECISION+DATA_WIDTH+EXPAND-1:0] in1_real_d1;
    reg signed [PRECISION+DATA_WIDTH+EXPAND-1:0] in1_imag_d1;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            in1_real_d1 <= 'b0;
            in1_imag_d1 <= 'b0;
            rod_real <= 'b0 ;
            rod_imag <= 'b0 ;
        end
        else if (en_r[0]) begin
            in1_real_d1 <= in1_real_d; // 再次保存in1的值
            in1_imag_d1 <= in1_imag_d;
            // (rod_real + i * rod_imag)就是in2和ro计算的值
            // 提前设置好位宽余量，防止数据溢出
            rod_real <= rod_real_0 - rod_real_1; 
            rod_imag <= rod_imag_0 + rod_imag_1;
      end
    end

    //====================================//
    // 第三级 计算in1和(in2和ro))的和and差
	
    reg signed [PRECISION+DATA_WIDTH+EXPAND-1:0] out1_real_r;
    reg signed [PRECISION+DATA_WIDTH+EXPAND-1:0] out1_imag_r;
    reg signed [PRECISION+DATA_WIDTH+EXPAND-1:0] out2_real_r;
    reg signed [PRECISION+DATA_WIDTH+EXPAND-1:0] out2_imag_r; 

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            out1_real_r <= 'b0;
            out1_imag_r <= 'b0;
            out2_real_r <= 'b0;
            out2_imag_r <= 'b0;
        end
        else if (en_r[1]) begin
            out1_real_r <= in1_real_d1 + rod_real;
            out1_imag_r <= in1_imag_d1 + rod_imag;
            out2_real_r <= in1_real_d1 - rod_real;
            out2_imag_r <= in1_imag_d1 - rod_imag;

            // valid <= en_r[2];
        end
    end
    

    // 在计算出结果时丢弃之前扩展的ENPAND位
    // 将第三级计算出的结果取其可用之处，连接线出去到各个输出寄存器
    // 截取最高位 和 从扩展位开始加上原来带宽的位宽 组成新的数据
    assign out1_real = {out1_real_r[PRECISION+DATA_WIDTH+EXPAND-1], out1_real_r[DATA_WIDTH+EXPAND-1:EXPAND]};
    assign out1_imag = {out1_imag_r[PRECISION+DATA_WIDTH+EXPAND-1], out1_imag_r[DATA_WIDTH+EXPAND-1:EXPAND]};
    assign out2_real = {out2_real_r[PRECISION+DATA_WIDTH+EXPAND-1], out2_real_r[DATA_WIDTH+EXPAND-1:EXPAND]};
    assign out2_imag = {out2_imag_r[PRECISION+DATA_WIDTH+EXPAND-1], out2_imag_r[DATA_WIDTH+EXPAND-1:EXPAND]};
    
    assign valid = en_r[2];// 用来表示当前输出的结果是否是合法的.

endmodule
