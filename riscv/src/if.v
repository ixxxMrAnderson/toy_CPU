module if_(
	input wire clk,
	input wire rst,

	input wire [31 : 0] pc_i, //pc_reg

	output reg [31 : 0] inst_o, //if_id
	output reg [31 : 0] pc_o,
	
	input wire [31 : 0] inst_i, //mem_ctrl
	input wire [31 : 0] inst_pc,
	input wire inst_done,
	output reg inst_req,
	output reg [31 : 0] inst_addr_o,
	
	output reg if_stall
);
	
	// assign inst_req = !(inst_done && inst_pc == pc_i);

	// always @(posedge clk) begin
	// 	if (rst) begin
	// 		inst_addr_o <= `Zero;
	// 	end else if (inst_pc == pc_i) begin 
	// 	end else begin
	// 		inst_addr_o <= pc_i;
	// 	end
	// end

	always @(*) begin
		if (rst) begin
			pc_o = `Zero;
			inst_o = `Zero;
			if_stall = `False;
		end else if (inst_done && inst_pc == pc_i) begin
			pc_o = pc_i;
			inst_o = inst_i;
			if_stall = `False;
			inst_req = `False;
		end else begin
			pc_o = `Zero;
			inst_o = `Zero;
			if_stall = `True;
			inst_req = `True;
			inst_addr_o = pc_i;
		end
	end

endmodule