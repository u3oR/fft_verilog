module fft4 #(
    parameter DATA_WIDTH = 8    
)
(
    input wire clk,
    input wire rst_n,
    input wire en,

    // 4点的FFT,四个输入实部和虚部
    input  wire signed [DATA_WIDTH-1:0] in0_real,
    input  wire signed [DATA_WIDTH-1:0] in0_imag,
    input  wire signed [DATA_WIDTH-1:0] in1_real,
    input  wire signed [DATA_WIDTH-1:0] in1_imag,
    input  wire signed [DATA_WIDTH-1:0] in2_real,
    input  wire signed [DATA_WIDTH-1:0] in2_imag,
    input  wire signed [DATA_WIDTH-1:0] in3_real,
    input  wire signed [DATA_WIDTH-1:0] in3_imag,

    // 4点的FFT需要进行两层Butterfly, 因此为其多富余两个位宽
    output wire signed [DATA_WIDTH+1:0] out0_real,
    output wire signed [DATA_WIDTH+1:0] out0_imag,
    output wire signed [DATA_WIDTH+1:0] out1_real,
    output wire signed [DATA_WIDTH+1:0] out1_imag,
    output wire signed [DATA_WIDTH+1:0] out2_real,
    output wire signed [DATA_WIDTH+1:0] out2_imag,
    output wire signed [DATA_WIDTH+1:0] out3_real,
    output wire signed [DATA_WIDTH+1:0] out3_imag,

    output wire valid
);
    // 1 << 9 = 512 故下面的旋转因子参数也被扩大了512倍
    localparam EXPAND = 9;
    // 四点fft
    localparam POINTS = 4; 

    // 旋转因子 
    reg signed [EXPAND+1:0] RO_ARRAY[POINTS-1:0][1:0];
    // 初始化旋转因子
    initial begin
        RO_ARRAY[0][0] <= 512;
        RO_ARRAY[0][1] <= 0;
        RO_ARRAY[1][0] <= 0;
        RO_ARRAY[1][1] <= -512;
        RO_ARRAY[2][0] <= -512;
        RO_ARRAY[2][1] <= 0;
        RO_ARRAY[3][0] <= 0;
        RO_ARRAY[3][1] <= 512;
    end


    // 四点的fft共需要三层连线:码位倒置一层,第一次蝶形运算一层,第二次蝶形运算一层
    // [DATA_WIDTH+EXPAND-1:0]表示每个数据的位宽
    // [2:0]表示 共需要三层
    // [3:0]表示每个层有四个数据,即四点的数据
    // wire signed [DATA_WIDTH+EXPAND-1:0] in_real[2:0][3:0];
    // wire signed [DATA_WIDTH+EXPAND-1:0] in_imag[2:0][3:0];

    // 用于原始数据层和第一计算层
    wire signed [DATA_WIDTH-1:0] in_real[3:0];
    wire signed [DATA_WIDTH-1:0] in_imag[3:0];
    // 用于第一计算层和第二计算层
    wire signed [DATA_WIDTH+0:0] in_real_step1[3:0];
    wire signed [DATA_WIDTH+0:0] in_imag_step1[3:0];
    // 用于第二计算层和输出层
    wire signed [DATA_WIDTH+1:0] in_real_step2[3:0];
    wire signed [DATA_WIDTH+1:0] in_imag_step2[3:0];
    // 用于连接各个模块的en引脚

    wire en_connect [3:0][1:0];
    //  连接引脚第一层蝶形运算模块
    assign en_connect[0][0] = en;
    assign en_connect[1][0] = en;
    // 第一步: 码位倒置
    assign in_real[0] = in0_real;
    assign in_imag[0] = in0_imag;
    assign in_real[1] = in2_real;
    assign in_imag[1] = in2_imag;
    assign in_real[2] = in1_real;
    assign in_imag[2] = in1_imag;
    assign in_real[3] = in3_real;
    assign in_imag[3] = in3_imag;

    //  第二步: 连接倒置后的数据和第一层蝶形运算
    Butterfly #(
        .DATA_WIDTH(DATA_WIDTH), .EXPAND(EXPAND)
    )  butterfly_unit_0_0 (
            // 控制信号
            .clk(clk),
            .rst_n(rst_n),
            .en(en_connect[0][0]),
            // 输入 
            .in1_real(in_real[0]),
            .in1_imag(in_imag[0]),
            .in2_real(in_real[1]),
            .in2_imag(in_imag[1]),
            // 旋转因子
            .ro_real(RO_ARRAY[0][0]),
            .ro_imag(RO_ARRAY[0][1]),
            // 输出
            .out1_real(in_real_step1[0]),
            .out1_imag(in_imag_step1[0]),
            .out2_real(in_real_step1[1]),
            .out2_imag(in_imag_step1[1]),
            // 输出是否有效信号
            // 有效代表该数据可用,否则则不可用
            .valid(en_connect[0][1])
    );

    Butterfly #(
        .DATA_WIDTH(DATA_WIDTH), .EXPAND(EXPAND)
    )  butterfly_unit_0_1 (
            // 控制信号
            .clk(clk),
            .rst_n(rst_n),
            .en(en_connect[1][0]),
            // 输入 
            .in1_real(in_real[2]),
            .in1_imag(in_imag[2]),
            .in2_real(in_real[3]),
            .in2_imag(in_imag[3]),
            // 旋转因子
            .ro_real(RO_ARRAY[0][0]),
            .ro_imag(RO_ARRAY[0][1]),
            // 输出
            .out1_real(in_real_step1[2]),
            .out1_imag(in_imag_step1[2]),
            .out2_real(in_real_step1[3]),
            .out2_imag(in_imag_step1[3]),
            // 输出是否有效信号
            // 有效代表该数据可用,否则则不可用
            .valid(en_connect[1][1])
    );
    
    //  连接第一层蝶形运算模块valid和第二层蝶形运算模块en
    assign en_connect[2][0] = en_connect[0][1];
    assign en_connect[3][0] = en_connect[1][1];

    // 第二层蝶形运算
    Butterfly #(
        .DATA_WIDTH(DATA_WIDTH+1), .EXPAND(EXPAND)
    )  butterfly_unit_1_0 (
            // 控制信号
            .clk(clk),
            .rst_n(rst_n),
            .en(en_connect[2][0]),
            // 输入 
            .in1_real(in_real_step1[0]),
            .in1_imag(in_imag_step1[0]),
            .in2_real(in_real_step1[2]),
            .in2_imag(in_imag_step1[2]),
            // 旋转因子
            .ro_real(RO_ARRAY[0][0]),
            .ro_imag(RO_ARRAY[0][1]),
            // 输出
            .out1_real(in_real_step2[0]),
            .out1_imag(in_imag_step2[0]),
            .out2_real(in_real_step2[2]),
            .out2_imag(in_imag_step2[2]),
            // 输出是否有效信号
            // 有效代表该数据可用,否则则不可用
            .valid(en_connect[2][1])
    );

    Butterfly #(
        .DATA_WIDTH(DATA_WIDTH+1), .EXPAND(EXPAND)
    )  butterfly_unit_1_1 (
            // 控制信号
            .clk(clk),
            .rst_n(rst_n),
            .en(en_connect[3][0]),
            // 输入 
            .in1_real(in_real_step1[1]),
            .in1_imag(in_imag_step1[1]),
            .in2_real(in_real_step1[3]),
            .in2_imag(in_imag_step1[3]),
            // 旋转因子
            .ro_real(RO_ARRAY[1][0]),
            .ro_imag(RO_ARRAY[1][1]),
            // 输出
            .out1_real(in_real_step2[1]),
            .out1_imag(in_imag_step2[1]),
            .out2_real(in_real_step2[3]),
            .out2_imag(in_imag_step2[3]),
            // 输出是否有效信号
            // 有效代表该数据可用,否则则不可用
            .valid(en_connect[3][1])
    );

    assign valid = en_connect[3][1];

    assign out0_real = in_real_step2[0];
    assign out0_imag = in_imag_step2[0];
    assign out1_real = in_real_step2[1];
    assign out1_imag = in_imag_step2[1];
    assign out2_real = in_real_step2[2];
    assign out2_imag = in_imag_step2[2];
    assign out3_real = in_real_step2[3];
    assign out3_imag = in_imag_step2[3];

endmodule



// genvar m, k;
// // 对于每一个fft,每层蝶形运算单元的个数都是相等的
// // 对于一个四点的fft, 每一层有两个有两个蝶形运算单元
// generate
//     // 构造两层
//     for(m = 0; m < 2; m = m + 1) begin: stage
//         // 每层两个
//         for (k = 0; k < 2; k = k + 1) begin: unit
//             
//         end
//     end
// endgenerate
