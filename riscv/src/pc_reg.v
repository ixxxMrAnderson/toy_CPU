module pc_reg(
	input wire clk,
	input wire rst,
	input wire jump_flag,
	input wire [31 : 0] branch_to,
	output reg [31 : 0] pc,

	input wire [4 : 0] stall_signal
);

	always @ (posedge clk) begin
	    if (rst) begin
	        pc <= `Zero;
	    end else if (jump_flag) begin
	    	pc <= branch_to;
	    end else if (stall_signal[0]) begin
	    end else begin
	    	pc <= pc + 4;
	    end
	end

endmodule