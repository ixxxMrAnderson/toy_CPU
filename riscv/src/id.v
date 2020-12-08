module id(
    input wire rst,
    input wire [31 : 0] pc_i,
    input wire [31 : 0] inst,
    input wire [31 : 0] r1_data_i,
    input wire [31 : 0] r2_data_i,

    input wire ld_flag,
    input wire ex_wb_flag,
    input wire [4 : 0] ex_wb_addr,
    input wire [31 : 0] ex_forward,

    input wire mem_wb_flag,
    input wire [4 : 0] mem_wb_addr,
    input wire [31 : 0] mem_forward,

    //To Register
    output wire [4 : 0] r1_addr,
    output reg r1_read_enable,
    output wire [4 : 0] r2_addr,
    output reg r2_read_enable,

    //To next stage
    output reg [31 : 0] pc_o,
    output reg [31 : 0] r1,
    output reg [31 : 0] r2,
    output reg [31 : 0] imm,
    output wire [4 : 0] rd,
    output reg rd_enable,
    output reg [4 : 0] aluop,
    output reg [2 : 0] alusel,

    output wire id_stall
);

    wire [6 : 0] opcode = inst[6 : 0];
    wire [6 : 0] func7 = inst[31 : 25];
    wire [2 : 0] func3 = inst[14 : 12];
    reg use_imm_instead;
    
    //Decode: Get opcode, imm, rd, and the addr of rs1&rs2

    assign r1_addr = inst[19 : 15];
    assign r2_addr = inst[24 : 20];
    assign rd = inst[11 : 7];

    always @(*) begin
        imm = `Zero;
        rd_enable = `WriteDisable;
        r1_read_enable = `ReadDisable;
        r2_read_enable = `ReadDisable;
        aluop = `EX_NOP;
        alusel = `EX_RES_NOP;
        use_imm_instead = 1'b0;
        pc_o = pc_i;
        case (opcode)
            `EXE: begin
                case (func7)   
                    7'b0000000: begin
                        case (func3)
                            3'b000: begin //ADD       
                                aluop = `EX_ADD;
                                alusel = `EX_RES_ARITH;
                                rd_enable = `WriteEnable;
                                r1_read_enable = `ReadEnable;
                                r2_read_enable = `ReadEnable;
                                use_imm_instead = 1'b0;  
                            end
                            3'b100: begin //XOR           
                                aluop = `EX_XOR;
                                alusel = `EX_RES_LOGIC;
                                rd_enable = `WriteEnable;
                                r1_read_enable = `ReadEnable;
                                r2_read_enable = `ReadEnable;
                                use_imm_instead = 1'b0;  
                            end
                            3'b110: begin //OR           
                                aluop = `EX_OR;
                                alusel = `EX_RES_LOGIC;
                                rd_enable = `WriteEnable;
                                r1_read_enable = `ReadEnable;
                                r2_read_enable = `ReadEnable;
                                use_imm_instead = 1'b0;  
                            end
                            3'b111: begin //AND          
                                aluop = `EX_AND;
                                alusel = `EX_RES_LOGIC;
                                rd_enable = `WriteEnable;
                                r1_read_enable = `ReadEnable;
                                r2_read_enable = `ReadEnable;
                                use_imm_instead = 1'b0;  
                            end
                            3'b001: begin //SLL        
                                aluop = `EX_SLL;
                                alusel = `EX_RES_SHIFT;
                                rd_enable = `WriteEnable;
                                r1_read_enable = `ReadEnable;
                                r2_read_enable = `ReadEnable;
                                use_imm_instead = 1'b0;  
                            end
                            3'b101: begin //SRL           
                                aluop = `EX_SRL;
                                alusel = `EX_RES_SHIFT;
                                rd_enable = `WriteEnable;
                                r1_read_enable = `ReadEnable;
                                r2_read_enable = `ReadEnable;
                                use_imm_instead = 1'b0;  
                            end
                            3'b010: begin //SLT           
                                aluop = `EX_SLT;
                                alusel = `EX_RES_ARITH;
                                rd_enable = `WriteEnable;
                                r1_read_enable = `ReadEnable;
                                r2_read_enable = `ReadEnable;
                                use_imm_instead = 1'b0;  
                            end
                            3'b011: begin //SLTU        
                                aluop = `EX_SLTU;
                                alusel = `EX_RES_ARITH;
                                rd_enable = `WriteEnable;
                                r1_read_enable = `ReadEnable;
                                r2_read_enable = `ReadEnable;
                                use_imm_instead = 1'b0;  
                            end
                        endcase
                    end
                    7'b0100000: begin
                        case (func3)
                            3'b000: begin //SUB          
                                aluop = `EX_SUB;
                                alusel = `EX_RES_ARITH;
                                rd_enable = `WriteEnable;
                                r1_read_enable = `ReadEnable;
                                r2_read_enable = `ReadEnable;
                                use_imm_instead = 1'b0;  
                            end
                            3'b101: begin //SRA           
                                aluop = `EX_SRA;
                                alusel = `EX_RES_SHIFT;
                                rd_enable = `WriteEnable;
                                r1_read_enable = `ReadEnable;
                                r2_read_enable = `ReadEnable;
                                use_imm_instead = 1'b0;  
                            end
                        endcase
                    end
                endcase
            end
            `EXEI: begin
                case (func3)
                    3'b000: begin //ADDI
                        imm = { {20{inst[31]}} ,inst[31:20] };          
                        aluop = `EX_ADD;
                        alusel = `EX_RES_ARITH;
                        rd_enable = `WriteEnable;
                        r1_read_enable = `ReadEnable;
                        r2_read_enable = `ReadDisable;
                        use_imm_instead = 1'b1;
                    end
                    3'b100: begin //XORI
                        imm = { {20{inst[31]}} ,inst[31:20] };           
                        aluop = `EX_XOR;
                        alusel = `EX_RES_LOGIC;
                        rd_enable = `WriteEnable;
                        r1_read_enable = `ReadEnable;
                        r2_read_enable = `ReadDisable;
                        use_imm_instead = 1'b1;
                    end
                    3'b110: begin //ORI
                        imm = { {20{inst[31]}} ,inst[31:20] };      
                        aluop = `EX_OR;
                        alusel = `EX_RES_LOGIC;
                        rd_enable = `WriteEnable;
                        r1_read_enable = `ReadEnable;
                        r2_read_enable = `ReadDisable;
                        use_imm_instead = 1'b1;
                    end
                    3'b111: begin //ANDI
                        imm = { {20{inst[31]}} ,inst[31:20] };
                        aluop = `EX_AND;
                        alusel = `EX_RES_LOGIC;
                        rd_enable = `WriteEnable;
                        r1_read_enable = `ReadEnable;
                        r2_read_enable = `ReadDisable;
                        use_imm_instead = 1'b1;
                    end
                    3'b001: begin //SLLI
                        imm = { 27'h0 ,inst[24:20] };
                        aluop = `EX_SLL;
                        alusel = `EX_RES_SHIFT;
                        rd_enable = `WriteEnable;
                        r1_read_enable = `ReadEnable;
                        r2_read_enable = `ReadDisable;
                        use_imm_instead = 1'b1;
                    end
                    3'b101: begin //SRLI
                        case (func7)
                            7'b0000000: begin
                                imm = { 27'h0 ,inst[24:20] };     
                                aluop = `EX_SRL;
                                alusel = `EX_RES_SHIFT;
                                rd_enable = `WriteEnable;
                                r1_read_enable = `ReadEnable;
                                r2_read_enable = `ReadDisable;
                                use_imm_instead = 1'b1;
                            end
                            7'b0100000: begin
                                imm = { 27'h0 ,inst[24:20] };       
                                aluop = `EX_SRA;
                                alusel = `EX_RES_SHIFT;
                                rd_enable = `WriteEnable;
                                r1_read_enable = `ReadEnable;
                                r2_read_enable = `ReadDisable;
                                use_imm_instead = 1'b1;
                            end
                        endcase
                    end
                    3'b010: begin //SLTI
                        imm = { {20{inst[31]}} ,inst[31:20] };        
                        aluop = `EX_SLT;
                        alusel = `EX_RES_ARITH;
                        rd_enable = `WriteEnable;
                        r1_read_enable = `ReadEnable;
                        r2_read_enable = `ReadDisable;
                        use_imm_instead = 1'b1;
                    end
                    3'b011: begin //SLTIU
                        imm = { {20{inst[31]}} ,inst[31:20] };       
                        aluop = `EX_SLTU;
                        alusel = `EX_RES_ARITH;
                        rd_enable = `WriteEnable;
                        r1_read_enable = `ReadEnable;
                        r2_read_enable = `ReadDisable;
                        use_imm_instead = 1'b1;
                    end
                endcase
            end
            `LUI: begin
                imm = { inst[31 : 12] ,12'h0 }; 
                rd_enable = `WriteEnable;
                r1_read_enable = `ReadDisable;
                r2_read_enable = `ReadDisable;
                aluop = `EX_OR;
                alusel = `EX_RES_LOGIC;
                use_imm_instead = 1'b1; 
            end 
            `LOAD: begin
                case (func3)
                    3'b000: begin //LB
                        aluop = `EX_LB;
                        alusel = `EX_RES_LD_ST;
                        imm = { {20{inst[31]}} ,inst[31:20] };
                        rd_enable = `WriteEnable;
                        r1_read_enable = `ReadEnable;
                        r2_read_enable = `ReadDisable;
                        use_imm_instead = 1'b0; 
                    end
                    3'b001: begin //LH
                        aluop = `EX_LH;
                        alusel = `EX_RES_LD_ST;
                        imm = { {20{inst[31]}} ,inst[31:20] };
                        rd_enable = `WriteEnable;
                        r1_read_enable = `ReadEnable;
                        r2_read_enable = `ReadDisable;
                        use_imm_instead = 1'b0; 
                    end
                    3'b010: begin //LW
                        aluop = `EX_LW;
                        alusel = `EX_RES_LD_ST;
                        imm = { {20{inst[31]}} ,inst[31:20] };
                        rd_enable = `WriteEnable;
                        r1_read_enable = `ReadEnable;
                        r2_read_enable = `ReadDisable;
                        use_imm_instead = 1'b0; 
                    end
                    3'b100: begin //LBU
                        aluop = `EX_LBU;
                        alusel = `EX_RES_LD_ST;
                        imm = { {20{inst[31]}} ,inst[31:20] };
                        rd_enable = `WriteEnable;
                        r1_read_enable = `ReadEnable;
                        r2_read_enable = `ReadDisable;
                        use_imm_instead = 1'b0; 
                    end
                    3'b101: begin //LHU
                        aluop = `EX_LHU;
                        alusel = `EX_RES_LD_ST;
                        imm = { {20{inst[31]}} ,inst[31:20] };
                        rd_enable = `WriteEnable;
                        r1_read_enable = `ReadEnable;
                        r2_read_enable = `ReadDisable;
                        use_imm_instead = 1'b0; 
                    end
                endcase
            end
            `STORE: begin
                case (func3)
                    3'b000: begin //SB
                        aluop = `EX_SB;
                        alusel = `EX_RES_LD_ST;
                        imm = { {20{inst[31]}} ,inst[31:25] ,inst[11:7]};
                        rd_enable = `WriteDisable;
                        r1_read_enable = `ReadEnable;
                        r2_read_enable = `ReadEnable;
                        use_imm_instead = 1'b0; 
                    end
                    3'b001: begin //SH
                        aluop = `EX_SH;
                        alusel = `EX_RES_LD_ST;
                        imm = { {20{inst[31]}} ,inst[31:25] ,inst[11:7]};
                        rd_enable = `WriteDisable;
                        r1_read_enable = `ReadEnable;
                        r2_read_enable = `ReadEnable;
                        use_imm_instead = 1'b0; 
                    end
                    3'b010: begin //SW
                        aluop = `EX_SW;
                        alusel = `EX_RES_LD_ST;
                        imm = { {20{inst[31]}} ,inst[31:25] ,inst[11:7]};
                        rd_enable = `WriteDisable;
                        r1_read_enable = `ReadEnable;
                        r2_read_enable = `ReadEnable;
                        use_imm_instead = 1'b0; 
                    end
                endcase
            end
            `AUIPC: begin
                imm = { inst[31 : 20] ,12'h0 }; 
                rd_enable = `WriteEnable;
                r1_read_enable = `ReadDisable;
                r2_read_enable = `ReadDisable;
                aluop = `EX_AUIPC;
                alusel = `EX_RES_ARITH;
                use_imm_instead = 1'b0; 
            end
            `BRANCH: begin
                case (func3)
                    3'b000: begin //BEQ
                        aluop = `EX_BEQ;
                        alusel = `EX_RES_NOP;
                        imm = { {20{inst[31]}} ,inst[7] ,inst[30:25] ,inst[11:8], 1'b0};
                        rd_enable = `WriteDisable;
                        r1_read_enable = `ReadEnable;
                        r2_read_enable = `ReadEnable;
                        use_imm_instead = 1'b0; 
                    end
                    3'b001: begin //BNE
                        aluop = `EX_BNE;
                        alusel = `EX_RES_NOP;
                        imm = { {20{inst[31]}} ,inst[7] ,inst[30:25] ,inst[11:8], 1'b0};
                        rd_enable = `WriteDisable;
                        r1_read_enable = `ReadEnable;
                        r2_read_enable = `ReadEnable;
                        use_imm_instead = 1'b0; 
                    end
                    3'b100: begin //BLT
                        aluop = `EX_BLT;
                        alusel = `EX_RES_NOP;
                        imm = { {20{inst[31]}} ,inst[7] ,inst[30:25] ,inst[11:8], 1'b0};
                        rd_enable = `WriteDisable;
                        r1_read_enable = `ReadEnable;
                        r2_read_enable = `ReadEnable;
                        use_imm_instead = 1'b0; 
                    end
                    3'b101: begin //BGE
                        aluop = `EX_BGE;
                        alusel = `EX_RES_NOP;
                        imm = { {20{inst[31]}} ,inst[7] ,inst[30:25] ,inst[11:8], 1'b0};
                        rd_enable = `WriteDisable;
                        r1_read_enable = `ReadEnable;
                        r2_read_enable = `ReadEnable;
                        use_imm_instead = 1'b0; 
                    end
                    3'b110: begin //BLTU
                        aluop = `EX_BLTU;
                        alusel = `EX_RES_NOP;
                        imm = { {20{inst[31]}} ,inst[7] ,inst[30:25] ,inst[11:8], 1'b0};
                        rd_enable = `WriteDisable;
                        r1_read_enable = `ReadEnable;
                        r2_read_enable = `ReadEnable;
                        use_imm_instead = 1'b0; 
                    end
                    3'b111: begin //BGEU
                        aluop = `EX_BGEU;
                        alusel = `EX_RES_NOP;
                        imm = { {20{inst[31]}} ,inst[7] ,inst[30:25] ,inst[11:8], 1'b0};
                        rd_enable = `WriteDisable;
                        r1_read_enable = `ReadEnable;
                        r2_read_enable = `ReadEnable;
                        use_imm_instead = 1'b0; 
                    end
                endcase
            end
            `JAL: begin
                imm = { {12{inst[31]}} ,inst[19:12] ,inst[20] ,inst[30:21] ,1'b0}; 
                rd_enable = `WriteEnable;
                r1_read_enable = `ReadDisable;
                r2_read_enable = `ReadDisable;
                aluop = `EX_JAL;
                alusel = `EX_RES_JAL;
                use_imm_instead = 1'b0; 
            end
            `JALR: begin
                imm = { {20{inst[31]}} ,inst[31:20] }; 
                rd_enable = `WriteEnable;
                r1_read_enable = `ReadEnable;
                r2_read_enable = `ReadDisable;
                aluop = `EX_JALR;
                alusel = `EX_RES_JAL;
                use_imm_instead = 1'b0; 
            end
        endcase
    end

    reg r1_stall;
    reg r2_stall;

    //Get rs1
    always @ (*) begin
        r1_stall = `False;
        if (rst) begin
            r1 = `Zero;
        end else if (ld_flag && r1_read_enable && ex_wb_addr == r1_addr && r1_addr) begin
            r1 = `Zero;
            r1_stall = `True;
        end else if (ex_wb_flag && r1_read_enable && ex_wb_addr == r1_addr && r1_addr) begin
            r1 = ex_forward;
        end else if (mem_wb_flag && r1_read_enable && mem_wb_addr == r1_addr && r1_addr) begin
            r1 = mem_forward;
        end else if (r1_read_enable && r1_addr) begin
            r1 = r1_data_i;
        end else begin
            r1 = `Zero;
        end
    end

    //Get rs2
    always @ (*) begin
        r2_stall = `False;
        if (rst) begin
            r2 = `Zero;
        end else if (ld_flag && r2_read_enable && ex_wb_addr == r2_addr && r2_addr) begin
            r2 = `Zero;
            r2_stall = `True;
        end else if (ex_wb_flag && r2_read_enable && ex_wb_addr == r2_addr && r2_addr) begin
            r2 = ex_forward;
        end else if (mem_wb_flag && r2_read_enable && mem_wb_addr == r2_addr && r2_addr) begin
            r2 = mem_forward;
        end else if (r2_read_enable && r2_addr) begin
            r2 = r2_data_i;
        end else if (use_imm_instead) begin
            r2 = imm;
        end else begin
            r2 = `Zero;
        end
    end

    assign id_stall = r1_stall | r2_stall;

endmodule
