`include "config.v"
module pc_reg(
	input wire clk,
	input wire rst,
	
	output reg [31 : 0] pc,

	input wire jump_flag,
	input wire branch_taken,
	input wire branch_flag,
	input wire [31 : 0] branch_pc,
	input wire [31 : 0] branch_to,
	input wire [31 : 0] BTB_,

	input wire [4 : 0] stall_signal
);
	
	reg [31 : 0] BTB [127 : 0];
	reg [10 : 0] BHT [127 : 0];
	integer i;

	always @ (posedge clk) begin
	    if (rst) begin
	    	for (i = 0; i < 128; i = i + 1) begin
    			BHT[i] <= 11'h401;
    			BTB[i] <= `Zero;
    		end
	        pc <= `Zero;
	    end else if (jump_flag) begin
	    	pc <= branch_to;
	    end else if (stall_signal[0]) begin
	    end else begin
	    	if (pc[17 : 9] == BHT[pc[8 : 2]][10 : 2] && BHT[pc[8 : 2]][1]) begin
	    		pc <= BTB[pc[8 : 2]];
	    	end else begin
	    		pc <= pc + 4;
	    	end
	    end

	    if (branch_flag && !rst) begin
	    	BTB[branch_pc[8 : 2]] <= BTB_;
	    	BHT[branch_pc[8 : 2]][10 : 2] <= branch_pc[17 : 9];
	    	if (branch_taken && BHT[branch_pc[8 : 2]][1 : 0] != 2'b11) begin
	    		BHT[branch_pc[8 : 2]][1 : 0] <= BHT[branch_pc[8 : 2]][1 : 0] + 1;
	    	end else if (!branch_taken && BHT[branch_pc[8 : 2]][1 : 0] != 2'b00) begin
	    		BHT[branch_pc[8 : 2]][1 : 0] <= BHT[branch_pc[8 : 2]][1 : 0] - 1;
	    	end
	    end
	end
	
endmodule