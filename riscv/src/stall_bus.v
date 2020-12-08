module stall(
	input wire rst, 
	input wire if_stall,
	input wire id_stall,
	input wire mem_stall,

	output reg [4 : 0] stall_signal
);

	always @ (*) begin
		if (rst) begin
			stall_signal = 5'b11111;
		end else if (mem_stall) begin
			stall_signal = 5'b11111;
		end else if (id_stall) begin
			stall_signal = 5'b00111;
		end else if (if_stall) begin
			stall_signal = 5'b00011;
		end else begin
			stall_signal = 5'b00000;
		end
	end

endmodule