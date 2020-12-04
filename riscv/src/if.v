module if_(
	input wire clk,
	input wire rst,
	input wire [31 : 0] pc_i,
	input wire [31 : 0] inst_i,

	output reg [31 : 0] inst_o,
	output reg [31 : 0] pc_o,
	
	output reg inst_req,
	output reg [31 : 0] inst_addr_o,
	input wire inst_done,
	
	output wire if_stall
);
	
	reg [31 : 0] req_pc;

	assign if_stall = !inst_done;

	always @(*) begin
		if (!inst_done) begin //wait for IF
		end else if (req_pc != pc_i) begin 
			inst_req = `True;
			req_pc = pc_i;
			inst_addr_o = pc_i;
		end else begin //reset request signal
			inst_req = `False;
		end
	end

	always @(*) begin
		if (rst) begin
			pc_o = `Zero;
			inst_o = `Zero;
		end else begin
			pc_o = pc_i;
			inst_o = inst_i;
		end
	end

endmodule