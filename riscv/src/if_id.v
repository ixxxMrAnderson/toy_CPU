module if_id(
    input wire clk, 
    input wire rst,
    input wire [31 : 0] pc_i,
    input wire [31 : 0] inst_i,
    input wire jump_flag,
    output reg [31 : 0] pc_o,
    output reg [31 : 0] inst_o,

    input wire [`StallSignalLen - 1 : 0] stall_signal
);
    
    always @ (posedge clk) begin
        if (rst || jump_flag) begin
            pc_o <= `Zero;
            inst_o <= `Zero;
        end else if (stall_signal[1]) begin
        end else begin
            pc_o <= pc_i;
            inst_o <= inst_i;
        end
    end
    
endmodule
