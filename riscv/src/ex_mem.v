`include "config.v"
module ex_mem(
    input wire clk,
    input wire rst,
    input wire [31 : 0] rd_data_i,
    input wire [4 : 0] rd_addr_i,
    input wire [31 : 0] mem_addr_i,
    input wire [`OpCodeLen - 1 : 0] aluop_i,
    input wire rd_enable_i,

    output reg [`OpCodeLen - 1 : 0] aluop_o,
    output reg [31 : 0] rd_data_o,
    output reg [4 : 0] rd_addr_o,
    output reg [31 : 0] mem_addr_o,
    output reg rd_enable_o,

    input wire [4 : 0] stall_signal
);

    always @ (posedge clk) begin
        if (rst) begin
            aluop_o <= `Zero;
            rd_data_o <= `Zero;
            rd_addr_o <= `Zero;
            rd_enable_o <= `Zero;
            mem_addr_o <= `Zero;
        end else if (stall_signal[3]) begin
        end else begin
            aluop_o <= aluop_i;
            rd_data_o <= rd_data_i;
            rd_addr_o <= rd_addr_i;
            rd_enable_o <= rd_enable_i;
            mem_addr_o <= mem_addr_i;
        end
    end

endmodule
