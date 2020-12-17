module ex(
    input wire rst,

    input wire [31 : 0] r1,
    input wire [31 : 0] r2,
    input wire [31 : 0] imm,
    input wire [4 : 0] rd,
    input wire rd_enable,
    input wire [`OpCodeLen - 1 : 0] aluop,
    input wire [`OpSelLen - 1 : 0] alusel,
    input wire [31 : 0] pc,
    input wire [31 : 0] predicted_pc,

    output reg [`OpCodeLen - 1 : 0] aluop_o,
    output reg [4 : 0] rd_addr_o,
    output reg [31 : 0] mem_addr_o,
    output reg rd_enable_o,
    output reg [31 : 0] output_,
    output reg [31 : 0] branch_to,
    output reg jump_flag,
    output reg branch_taken,

    output reg ld_flag
    );

    reg [31 : 0] arith_out;
    reg [31 : 0] logic_out;
    reg [31 : 0] shift_out;
    wire [31 : 0] jalr_to = r1 + imm;

    always @ (*) begin
        if (!rst) begin
            rd_enable_o = (rd_enable && rd) ? 1'b1 : 1'b0;
            rd_addr_o = rd;
            case (aluop)
                `EX_JAL: begin
                    branch_to  = pc + imm;
                    jump_flag = predicted_pc + 4 == branch_to ? `False : `True;
                    branch_taken = `True;
                end
                `EX_JALR: begin
                    branch_to  = {jalr_to[31:1], 1'b0};
                    jump_flag = predicted_pc + 4 == branch_to ? `False : `True;
                    branch_taken = `True;
                end
                `EX_BEQ: begin
                    if (r1 == r2) begin
                        branch_to  = pc + imm;
                        branch_taken = `True;
                    end else begin
                        branch_to  = pc + 4;
                        branch_taken = `False;
                    end
                    jump_flag = predicted_pc + 4 == branch_to ? `False : `True;
                end
                `EX_BNE: begin
                    if (r1 != r2) begin
                        branch_to  = pc + imm;
                        branch_taken = `True;
                    end else begin
                        branch_to  = pc + 4;
                        branch_taken = `False;
                    end
                    jump_flag = predicted_pc + 4 == branch_to ? `False : `True;
                end
                `EX_BLT: begin
                    if ($signed(r1) < $signed(r2)) begin
                        branch_to = pc + imm;
                        branch_taken = `True;
                    end else begin
                        branch_to = pc + 4;
                        branch_taken = `False;
                    end
                    jump_flag = predicted_pc + 4 == branch_to ? `False : `True;
                end
                `EX_BGE: begin
                    if ($signed(r1) >= $signed(r2)) begin
                        branch_to = pc + imm;
                        branch_taken = `True;
                    end else begin
                        branch_to = pc + 4;
                        branch_taken = `False;
                    end
                    jump_flag = predicted_pc + 4 == branch_to ? `False : `True;
                end
                `EX_BLTU: begin
                    if (r1 < r2) begin
                        branch_to = pc + imm;
                        branch_taken = `True;
                    end else begin
                        branch_to = pc + 4;
                        branch_taken = `False;
                    end
                    jump_flag = predicted_pc + 4 == branch_to ? `False : `True;
                end
                `EX_BGEU: begin
                    if (r1 >= r2) begin
                        branch_to = pc + imm;
                        branch_taken = `True;
                    end else begin
                        branch_to = pc + 4;
                        branch_taken = `False;
                    end
                    jump_flag = predicted_pc + 4 == branch_to ? `False : `True;
                end
                default: begin
                    jump_flag = `False;
                    branch_taken = `False;
                end
            endcase
        end
    end

    always @ (*) begin
        if (rst) begin
            arith_out = `Zero;
        end else begin
            case (aluop)
                `EX_ADD:
                    arith_out = r1 + r2;
                `EX_SUB:
                    arith_out = r1 - r2;
                `EX_SLTU:
                    arith_out = r1 < r2;
                `EX_SLT: 
                    arith_out = $signed(r1) < $signed(r2);
                `EX_SLTU :
                    arith_out = r1 < r2;
                `EX_AUIPC: 
                    arith_out = pc + imm;
                default: 
                    arith_out = `Zero;
            endcase
        end
    end

    always @ (*) begin
        if (rst) begin
            logic_out = `Zero;
        end else begin
            case (aluop)
                `EX_AND:
                    logic_out = r1 & r2;
                `EX_OR:
                    logic_out = r1 | r2;
                `EX_XOR: 
                    logic_out = r1 ^ r2;
                default: 
                    logic_out = `Zero;
            endcase
        end
    end

    always @ (*) begin
        if (rst) begin
            shift_out = `Zero;
        end else begin
            case (aluop)
                `EX_SLL:
                    shift_out = r1 << (r2[4:0]);
                `EX_SRL:
                    shift_out = r1 >> (r2[4:0]);
                `EX_SRA: 
                    shift_out = (r1 >> (r2[4:0])) | ({32{r1[31]}} << (6'd32 - {1'b0,r2[4:0]}));
                default: 
                    shift_out = `Zero;
            endcase
        end
    end

    always @ (*) begin // Load and Store
        if (rst) begin
            mem_addr_o = `Zero;
            ld_flag = `False;
        end else begin
            case (aluop)
                `EX_LW, `EX_LH, `EX_LB, `EX_LHU, `EX_LBU: begin
                    mem_addr_o = r1 + imm;
                    ld_flag = `True;
                end
                `EX_SH, `EX_SB, `EX_SW: begin
                    mem_addr_o = r1 + imm;
                    ld_flag = `False;
                end
                default: begin
                    mem_addr_o = `Zero;
                    ld_flag = `False;
                end
            endcase
        end
    end

    always @ (*) begin // MUX
        if (rst) begin
            output_ = `Zero;
            aluop_o = `MEM_NOP;
        end else begin
            case (alusel)
                `EX_RES_JAL: begin
                    output_ = pc + 4;
                    aluop_o = `MEM_NOP;
                end
                `EX_RES_LOGIC: begin
                    output_ = logic_out;
                    aluop_o = `MEM_NOP;
                end
                `EX_RES_SHIFT: begin
                    output_ = shift_out;
                    aluop_o = `MEM_NOP;
                end
                `EX_RES_ARITH: begin
                    output_ = arith_out;
                    aluop_o = `MEM_NOP;
                end
                `EX_RES_LD_ST: begin
                    output_ = r2;
                    aluop_o = aluop;
                end
                `EX_RES_NOP: begin
                    output_ = `Zero;
                    aluop_o = `MEM_NOP;
                end
                default: begin
                    output_ = `Zero;
                    aluop_o = `MEM_NOP;
                end
            endcase
        end
    end

endmodule
