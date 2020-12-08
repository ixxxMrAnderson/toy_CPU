module mem(
    input rst,
    input wire [31 : 0] rd_data_i,
    input wire [4 : 0] rd_addr_i,
    input wire rd_enable_i,

    input wire [`OpCodeLen - 1 : 0] aluop_i,

    output reg [31 : 0] rd_data_o,
    output reg [4 : 0] rd_addr_o,
    output reg rd_enable_o,

    input wire [31 : 0] mem_addr_i,
    input wire ram_done_i,
    input wire [31 : 0] ram_r_data_i,

    output reg ram_r_req_o,
    output reg ram_w_req_o,
    output reg [31 : 0] ram_addr_o,
    output reg [31 : 0] ram_w_data_o,

    output reg mem_stall
);

always @ (*) begin
    if (rst) begin
        rd_data_o = `Zero;
        rd_addr_o = 5'b00000;
        rd_enable_o = `WriteDisable;
        ram_r_req_o     = `False;
        ram_w_req_o     = `False;
        ram_w_data_o    = `Zero;
        ram_addr_o      = `Zero;
        // ram_state       = 2'h0;
        mem_stall       = `False;
    end
    else begin
        rd_addr_o = rd_addr_i;
        rd_enable_o = rd_enable_i;
        case(aluop_i)
            `MEM_NOP: begin
                ram_r_req_o     = `False;
                ram_w_req_o     = `False;
                ram_w_data_o    = `Zero;
                ram_addr_o      = `Zero;
                // ram_state       = 2'h0;
                mem_stall       = `False;
                rd_data_o       = rd_data_i;
            end
            `EX_LB: begin
                ram_r_req_o     = `True && !ram_done_i;
                ram_w_req_o     = `False;
                ram_w_data_o    = `Zero;
                ram_addr_o      = mem_addr_i;
                rd_data_o       = {{24{ram_r_data_i[7]}},ram_r_data_i[7:0]};
                // ram_state       = 2'b00;
                mem_stall       = !ram_done_i;
            end
            `EX_LBU: begin
                ram_r_req_o     = `True && !ram_done_i;
                ram_w_req_o     = `False;
                ram_w_data_o    = `Zero;
                ram_addr_o      = mem_addr_i;
                rd_data_o       = {24'b0,ram_r_data_i[7:0]};
                // ram_state       = 2'b00;
                mem_stall       = !ram_done_i;
            end
            `EX_LH: begin
                ram_r_req_o     = `True && !ram_done_i;
                ram_w_req_o     = `False;
                ram_w_data_o    = `Zero;
                ram_addr_o      = mem_addr_i;
                rd_data_o       = {{16{ram_r_data_i[15]}},ram_r_data_i[15:0]};
                // ram_state       = 2'b01;
                mem_stall       = !ram_done_i;
            end
            `EX_LHU: begin
                ram_r_req_o     = `True && !ram_done_i;
                ram_w_req_o     = `False;
                ram_w_data_o    = `Zero;
                ram_addr_o      = mem_addr_i;
                rd_data_o       = {16'b0,ram_r_data_i[15:0]};
                // ram_state       = 2'b01;
                mem_stall       = !ram_done_i;
            end
            `EX_LW: begin
                ram_r_req_o     = `True && !ram_done_i;
                ram_w_req_o     = `False;
                ram_w_data_o    = `Zero;
                ram_addr_o      = mem_addr_i;
                rd_data_o       = ram_r_data_i;
                // ram_state       = 2'b11;
                mem_stall       = !ram_done_i;
            end
            `EX_SB: begin
                ram_r_req_o     = `False;
                ram_w_req_o     = `True && !ram_done_i;
                ram_addr_o      = mem_addr_i;
                ram_w_data_o    = rd_data_i[7 : 0];
                rd_data_o       = rd_data_i;
                // ram_state       = 2'b00;
                mem_stall       = !ram_done_i;
            end
            `EX_SH: begin
                ram_r_req_o     = `False;
                ram_w_req_o     = `True && !ram_done_i;
                ram_addr_o      = mem_addr_i;
                ram_w_data_o    = rd_data_i[15 : 0];
                rd_data_o       = rd_data_i;
                // ram_state       = 2'b01;
                mem_stall       = !ram_done_i;
            end
            `EX_SW: begin
                ram_r_req_o     = `False;
                ram_w_req_o     = `True && !ram_done_i;
                ram_addr_o      = mem_addr_i;
                ram_w_data_o    = rd_data_i[31 : 0];
                rd_data_o       = rd_data_i;
                // ram_state       = 2'b11;
                mem_stall       = !ram_done_i;
            end
            default: begin
                ram_r_req_o     = `False;
                ram_w_req_o     = `False;
                ram_w_data_o    = `Zero;
                ram_addr_o      = `Zero;
                rd_data_o       = `Zero;
                // ram_state       = 2'b0;
                mem_stall       = `False;
            end
        endcase
    end
end

endmodule
