`timescale 1ns / 1ps

`define Zero 32'h00000000
`define ZeroReg 5'b00000
`define ZeroByte 8'b00000000
`define True 1'b1
`define False 1'b0
`define Write 2'b01
`define Read 2'b00
`define Vacant 2'b10
`define IF 2'b11

`define WriteEnable 1'b1
`define WriteDisable 1'b0
`define ReadEnable 1'b1
`define ReadDisable 1'b0

//OPCODE
`define OpLen 7
`define EXE 7'b0110011
`define EXEI 7'b0010011
`define LOAD 7'b0000011
`define STORE 7'b0100011
`define LUI 7'b0110111
`define AUIPC 7'b0010111
`define BRANCH 7'b1100011
`define JAL 7'b1101111
`define JALR 7'b1100111

//AluOP
`define OpCodeLen 5
`define EX_NOP   5'h0
`define EX_ADD   5'h1
`define EX_SUB   5'h2
`define EX_SLT   5'h3
`define EX_SLTU  5'h4
`define EX_XOR   5'h5
`define EX_OR    5'h6
`define EX_AND   5'h7
`define EX_SLL   5'h8
`define EX_SRL   5'h9
`define EX_SRA   5'ha
`define EX_AUIPC 5'hb

`define EX_JAL   5'hc
`define EX_JALR  5'hd
`define EX_BEQ   5'he
`define EX_BNE   5'hf
`define EX_BLT   5'h10
`define EX_BGE   5'h11
`define EX_BLTU  5'h12
`define EX_BGEU  5'h13

`define EX_LB    5'h14
`define EX_LH    5'h15
`define EX_LW    5'h16
`define EX_LBU   5'h17
`define EX_LHU   5'h18

`define EX_SB    5'h19
`define EX_SH    5'h1a
`define EX_SW    5'h1b

`define MEM_NOP   5'h0

//AluSelect
`define OpSelLen 3
`define EX_RES_NOP      3'b000
`define EX_RES_LOGIC    3'b001
`define EX_RES_SHIFT    3'b010
`define EX_RES_ARITH    3'b011
`define EX_RES_JAL      3'b100
`define EX_RES_LD_ST    3'b101