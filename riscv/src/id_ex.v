`include "config.v"
module id_ex(
    input wire clk,
    input wire rst,

    input wire [31 : 0] r1_i,
    input wire [31 : 0] r2_i,
    input wire [31 : 0] imm_i,
    input wire [4 : 0] rd_i,
    input wire rd_enable_i,
    input wire [`OpCodeLen - 1 : 0] aluop_i,
    input wire [`OpSelLen - 1 : 0] alusel_i,
    input wire [31 : 0] pc_i,

    input wire jump_flag,

    output reg [31 : 0] pc_o,
    output reg [31 : 0] r1_o,
    output reg [31 : 0] r2_o,
    output reg [31 : 0] imm_o,
    output reg [4 : 0] rd_o,
    output reg rd_enable_o,
    output reg [`OpCodeLen - 1 : 0] aluop_o,
    output reg [`OpSelLen - 1 : 0] alusel_o,

    input wire [4 : 0] stall_signal
);

    always @ (posedge clk) begin
        if (rst) begin
            r1_o <= `Zero;
            r2_o <= `Zero;
            imm_o <= `Zero;
            rd_o <= `Zero;
            rd_enable_o <= `Zero;
            aluop_o <= `Zero;
            alusel_o <= `Zero;
            pc_o <= `Zero;
        end else if (stall_signal[3]) begin

        end else if (stall_signal[2] || jump_flag) begin
            r1_o <= `Zero;
            r2_o <= `Zero;
            imm_o <= `Zero;
            rd_o <= `Zero;
            rd_enable_o <= `Zero;
            aluop_o <= `Zero;
            alusel_o <= `Zero;
            pc_o <= `Zero;
        end else begin
            r1_o <= r1_i;
            r2_o <= r2_i;
            imm_o <= imm_i;
            rd_o <= rd_i;
            rd_enable_o <= rd_enable_i;
            aluop_o <= aluop_i;
            alusel_o <= alusel_i;
            pc_o <= pc_i;
        end
    end

endmodule
