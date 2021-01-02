`include "config.v"
module mem_wb(
    input clk,
    input rst,
    
    input wire [31 : 0] rd_data_i,
    input wire [4 : 0] rd_addr_i,
    input wire rd_enable_i,

    output reg [31 : 0] rd_data_o,
    output reg [4 : 0] rd_addr_o,
    output reg rd_enable_o,

    input wire [4 : 0] stall_signal
);

    always @ (posedge clk) begin
        if (rst || stall_signal[4]) begin
            rd_data_o <= `Zero;
            rd_addr_o <= 5'b00000;
            rd_enable_o <= `WriteDisable;
        end else begin
            rd_data_o <= rd_data_i;
            rd_addr_o <= rd_addr_i;
            rd_enable_o <= rd_enable_i;
        end
    end
    
endmodule
