module if_(
	input wire clk,
	input wire rst,

	input wire [31 : 0] pc_i, //pc_reg
	input wire [31 : 0] without_prediction_i,

	output reg [31 : 0] inst_o, //if_id
	output reg [31 : 0] pc_o,
	output reg [31 : 0] without_prediction_o,
	
	input wire [31 : 0] inst_i, //mem_ctrl
	input wire [31 : 0] inst_pc,
	input wire inst_done,
	output wire inst_req,
	output reg [31 : 0] inst_addr_o,
	
	output reg if_stall
);
	
	reg [38 : 0] icache [255 : 0]; //index_size = 256, tag_length = 8
	assign inst_req = icache[inst_addr_o[9 : 2]][38 : 32] != inst_addr_o[17 : 10] && !inst_done;

	integer i;

	always @ (posedge clk) begin
	    if (rst) begin
	        for (i = 0; i < 256; i = i + 1) begin
	            icache[i][38] <= 1'b1;
	        end
	        inst_addr_o <= `Zero;
	    end else begin
	        if (inst_done) begin
	            icache[inst_addr_o[9 : 2]] <= {inst_addr_o[17 : 10], inst_i};
	            inst_addr_o <= pc_i + 4;
	        end else begin
	            inst_addr_o <= pc_i;
	        end
	    end
	end

	always @(*) begin
		if (rst) begin
			pc_o = `Zero;
			without_prediction_o = `Zero;
			inst_o = `Zero;
			if_stall = `False;
		end else if (icache[pc_i[9 : 2]][38 : 32] == pc_i[17 : 10]) begin
	        pc_o = pc_i;
	        without_prediction_o = without_prediction_i;
	        inst_o = icache[pc_i[9 : 2]];
	        if_stall = `False;
    	end else if (inst_done && inst_pc == pc_i) begin
			pc_o = pc_i;
	        without_prediction_o = without_prediction_i;
			inst_o = inst_i;
			if_stall = `False;
		end else begin
			pc_o = `Zero;
			without_prediction_o = `Zero;
			inst_o = `Zero;
			if_stall = `True;
		end
	end

endmodule