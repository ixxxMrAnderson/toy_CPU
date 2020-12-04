module register(
    input wire clk,
    input wire rst,
    //write
    input wire write_enable,
    input wire [4 : 0] write_addr,
    input wire [31 : 0] write_data,
    //read 1
    input wire read_enable1,   
    input wire [4 : 0] read_addr1,
    output reg [31 : 0] read_data1,
    //read 2
    input wire read_enable2,   
    input wire [4 : 0] read_addr2,
    output reg [31 : 0] read_data2
    );
    
    reg[31 : 0] regs[31 : 0];
    
    //write 1
    always @ (posedge clk) begin
        if (!rst && write_enable) begin
            if (write_addr != 5'b00000) //not zero register
                regs[write_addr] <= write_data;
        end
    end

    //read 1
    always @ (*) begin
        if (!rst && read_enable1) begin
            if (read_addr1 == 5'b00000) 
                read_data1 = `Zero;
            else if (read_addr1 == write_addr && write_enable)
                read_data1 = write_data;
            else
                read_data1 = regs[read_addr1];
        end else begin
            read_data1 = `Zero;
        end
    end

    //read 2
    always @ (*) begin
        if (!rst && read_enable2) begin
            if (read_addr2 == 5'b00000) 
                read_data2 = `Zero;
            else if (read_addr2 == write_addr && write_enable)
                read_data2 = write_data;
            else
                read_data2 = regs[read_addr2];
        end else begin
            read_data2 = `Zero;
        end
    end

endmodule
