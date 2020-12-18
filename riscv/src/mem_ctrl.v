`include "config.v"
module mem_ctrl(
	input wire clk,
	input wire rst,

	input wire inst_req,
	input wire [31 : 0] inst_addr_i,
	output reg [31 : 0] inst_o,
	output reg [31 : 0] inst_pc,
	output reg inst_done_o,

	input wire ram_r_req,
	input wire ram_w_req,
	input wire [31 : 0] ram_addr_i,
	input wire [3 : 0] buffer_pointer_i,
	input wire [31 : 0] ram_w_data_i,
	output reg [31 : 0] ram_r_data_o,
	output reg ram_done_o,

	input wire [7 : 0] mem_din,
	output reg [7 : 0] mem_dout,
	output reg [31 : 0] mem_a,
	output reg mem_wr
);

	reg [7 : 0] dcache [127 : 0]; 
	reg [31 : 0] data_buffer;
	reg [2 : 0] buffer_pointer;
	reg [1 : 0] ram_state;
	reg [31 : 0] cur_ram_addr;

	always @(posedge clk) begin
		if (rst) begin
			inst_o <= `Zero;
			inst_done_o <= `False;
			ram_r_data_o <= `Zero;
			ram_done_o <= `False;
			mem_dout <= `ZeroByte;
			mem_a <= `Zero;
			data_buffer <= `Zero;
			mem_wr <= `Read;
			buffer_pointer <= 3'h0;
			ram_state <= `Vacant;
			inst_pc <= `Zero;
		end else if (ram_state == `Vacant) begin
			ram_done_o <= `False;
			inst_done_o <= `False;
			mem_wr <= `Read;
			if (ram_w_req) begin
				data_buffer <= ram_w_data_i;
				mem_wr <= `Read;
				mem_a <= `Zero;
				if (ram_addr_i[17 : 16] != 2'b11) 
					buffer_pointer <= buffer_pointer_i;
				else 
					buffer_pointer <= 3'h3;
				ram_state <= `Write;
			end else if (ram_r_req) begin
				mem_wr <= `Read;
				buffer_pointer <= 3'h0;
				ram_state <= `Read;
				mem_a <= `Zero;
			end else if (inst_req) begin
				mem_wr <= `Read;
				mem_a <= inst_addr_i;
				buffer_pointer <= 3'h0;
				ram_state <= `IF;
				cur_ram_addr <= inst_addr_i;
			end else begin
			end
		end else if (ram_state == `Write && ram_w_req) begin
			inst_done_o <= `False;
			if (ram_addr_i[16 : 9] == 8'hff) begin
				ram_done_o <= `True;
				ram_state <= `Vacant;
				case (buffer_pointer)
					3'h0: begin
						dcache[ram_addr_i[8 : 0]] <= ram_w_data_i[7 : 0];
						dcache[ram_addr_i[8 : 0] + 1] <= ram_w_data_i[15 : 8];
						dcache[ram_addr_i[8 : 0] + 2] <= ram_w_data_i[23 : 16];
						dcache[ram_addr_i[8 : 0] + 3] <= ram_w_data_i[31 : 24];
					end
					3'h2: begin
						dcache[ram_addr_i[8 : 0]] <= ram_w_data_i[7 : 0];
						dcache[ram_addr_i[8 : 0] + 1] <= ram_w_data_i[15 : 8];
						dcache[ram_addr_i[8 : 0] + 2] <= `ZeroByte;
						dcache[ram_addr_i[8 : 0] + 3] <= `ZeroByte;
					end
					3'h3: begin
						dcache[ram_addr_i[8 : 0]] <= ram_w_data_i[7 : 0];
						dcache[ram_addr_i[8 : 0] + 1] <= `ZeroByte;
						dcache[ram_addr_i[8 : 0] + 2] <= `ZeroByte;
						dcache[ram_addr_i[8 : 0] + 3] <= `ZeroByte;
					end 
				endcase
			end else begin
				ram_done_o <= `False;
				case (buffer_pointer)
					3'h0: begin
						mem_dout <= ram_w_data_i[31 : 24];
						mem_a <= ram_addr_i + 3;
						mem_wr <= `Write;
						buffer_pointer <= 3'h1;
					end
					3'h1: begin
						mem_dout <= ram_w_data_i[23 : 16];
						mem_a <= ram_addr_i + 2;
						mem_wr <= `Write;
						buffer_pointer <= 3'h2;
					end
					3'h2: begin
						mem_dout <= ram_w_data_i[15 : 8];
						mem_a <= ram_addr_i + 1;
						mem_wr <= `Write;
						buffer_pointer <= 3'h3;
					end
					3'h3: begin
						mem_dout <= ram_w_data_i[7 : 0];
						mem_a <= ram_addr_i;
						mem_wr <= `Write;
						buffer_pointer <= 3'h0;
						ram_done_o <= `True;
						ram_state <= `Vacant;
					end 
				endcase
			end
		end else if (ram_state == `Read && ram_r_req) begin
			inst_done_o <= `False;
			if (ram_addr_i[16 : 9] == 8'hff) begin
				ram_done_o <= `True;
				ram_state <= `Vacant;
				ram_r_data_o[7 : 0] <= dcache[ram_addr_i[8 : 0]];
				ram_r_data_o[15 : 8] <= dcache[ram_addr_i[8 : 0] + 1];
				ram_r_data_o[23 : 16] <= dcache[ram_addr_i[8 : 0] + 2];
				ram_r_data_o[31 : 24] <= dcache[ram_addr_i[8 : 0] + 3];
			end else begin
				ram_done_o <= `False;
				case (buffer_pointer)
					3'h0: begin
						mem_a <= ram_addr_i;
						mem_wr <= `Read;
						buffer_pointer <= 3'h1;
					end
					3'h1: begin
						mem_a <= ram_addr_i + 1;
						mem_wr <= `Read;
						buffer_pointer <= 3'h2;
					end
					3'h2: begin
						data_buffer[7 : 0] <= mem_din;
						mem_a <= ram_addr_i + 2;
						mem_wr <= `Read;
						buffer_pointer <= 3'h3;
					end 
					3'h3: begin
						data_buffer[15 : 8] <= mem_din;
						mem_a <= ram_addr_i + 3;
						mem_wr <= `Read;
						buffer_pointer <= 3'h4;
					end 
					3'h4: begin
						data_buffer[23 : 16] <= mem_din;
						buffer_pointer <= 3'h5;
					end 
					3'h5: begin
						ram_r_data_o <= {mem_din, data_buffer[23 : 0]};
						buffer_pointer <= 3'h0;
						ram_done_o <= `True;
						ram_state <= `Vacant;
					end 
				endcase
			end
		end else if (ram_state == `IF) begin
			inst_done_o <= `False;
			ram_done_o <= `False;
			if (inst_addr_i != cur_ram_addr) begin
				mem_wr <= `Read;
				mem_a <= inst_addr_i;
				buffer_pointer <= 3'h0;
				cur_ram_addr <= inst_addr_i;
			end else begin
				case (buffer_pointer)
					3'h0: begin
						mem_a <= cur_ram_addr + 1;
						mem_wr <= `Read;
						buffer_pointer <= 3'h1;
					end
					3'h1: begin
						data_buffer[7 : 0] <= mem_din;
						mem_a <= cur_ram_addr + 2;
						mem_wr <= `Read;
						buffer_pointer <= 3'h2;
					end
					3'h2: begin
						data_buffer[15 : 8] <= mem_din;
						mem_a <= cur_ram_addr + 3;
						mem_wr <= `Read;
						buffer_pointer <= 3'h3;
					end 
					3'h3: begin
						data_buffer[23 : 16] <= mem_din;
						buffer_pointer <= 3'h4;
					end 
					3'h4: begin
						inst_o <= {mem_din, data_buffer[23 : 0]};
						buffer_pointer <= 3'h0;
						inst_done_o <= `True;
						inst_pc <= cur_ram_addr;
						ram_state <= `Vacant;
					end 
				endcase
			end
		end else begin
			ram_done_o <= `False;
			inst_done_o <= `False;
			mem_wr <= `Read;
			ram_state <= `Vacant;
		end
	end

endmodule