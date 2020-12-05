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
	input wire [31 : 0] ram_w_data_i,
	output reg [31 : 0] ram_r_data_o,
	output reg ram_done_o,

	input wire [7 : 0] mem_din,
	output reg [7 : 0] mem_dout,
	output reg [31 : 0] mem_a,
	output reg mem_wr
);

	// reg [7 : 0] d_cache [`DCacheSize - 1 : 0]; 
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
			mem_dout <= 8'b00000000;
			mem_a <= `Zero;
			data_buffer <= `Zero;
			mem_wr <= 1'b0;
			buffer_pointer <= 3'h0;
			ram_state <= `Vacant;
			inst_pc <= `Zero;
		end else if (ram_state == `Vacant) begin
			if (ram_w_req) begin
				data_buffer <= ram_w_data_i;
				mem_dout <= ram_w_data_i[7 : 0];
				mem_wr <= `Write;
				buffer_pointer <= 3'h1;
				ram_state <= `Write;
				ram_done_o <= `False;
				inst_done_o <= `False;
				cur_ram_addr <= ram_addr_i;
				mem_a <= ram_addr_i;
			end else if (ram_r_req) begin
				mem_wr <= `Read;
				buffer_pointer <= 3'h0;
				ram_state <= `Read;
				ram_done_o <= `False;
				inst_done_o <= `False;
				cur_ram_addr <= ram_addr_i;
				mem_a <= ram_addr_i;
			end else if (inst_req) begin
				mem_wr <= `Read;
				mem_a <= inst_addr_i;
				buffer_pointer <= 3'h0;
				ram_state <= `IF;
				inst_done_o <= `False;
				ram_done_o <= `False;
				cur_ram_addr <= inst_addr_i;
			end else begin
				ram_done_o <= `True;
				inst_done_o <= `True;
			end
		end else if (ram_state == `Write) begin
			ram_done_o <= `False;
			inst_done_o <= `False;
			case (buffer_pointer)
				3'h1: begin
					mem_dout <= data_buffer[15 : 8];
					mem_a <= cur_ram_addr + 1;
					mem_wr <= `Write;
					buffer_pointer <= 3'h2;
				end
				3'h2: begin
					mem_dout <= data_buffer[23 : 16];
					mem_a <= cur_ram_addr + 2;
					mem_wr <= `Write;
					buffer_pointer <= 3'h3;
				end
				3'h3: begin
					mem_dout <= data_buffer[31 : 24];
					mem_a <= cur_ram_addr + 3;
					mem_wr <= `Write;
					buffer_pointer <= 3'h0;
					ram_done_o <= `True;
					ram_state <= `Vacant;
				end 
			endcase
		end else if (ram_state == `Read) begin
			ram_done_o <= `False;
			inst_done_o <= `False;
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
					ram_r_data_o <= {mem_din, data_buffer[23 : 0]};
					buffer_pointer <= 3'h0;
					ram_done_o <= `True;
					ram_state <= `Vacant;
				end 
			endcase
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
		end
	end

endmodule