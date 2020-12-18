// RISCV32I CPU top module
// port modification allowed for debugging purposes
module cpu(
    input  wire                 clk_in,			// system clock signal
    input  wire                 rst_in,			// reset signal
    input  wire					        rdy_in,			// ready signal, pause cpu when low

    input  wire [7 : 0]         mem_din,		// data input bus
    output wire [7 : 0]         mem_dout,		// data output bus
    output wire [31 : 0]        mem_a,			// address bus (only 17:0 is used)
    output wire                 mem_wr,			// write/read signal (1 for write)

    input  wire                 io_buffer_full, // 1 if uart buffer is full

    output wire [31 : 0]			  dbgreg_dout		// cpu register output (debugging demo)
);

// implementation goes here

// Specifications:
// - Pause cpu(freeze pc, registers, etc.) when rdy_in is low
// - Memory read result will be returned in the next cycle. Write takes 1 cycle(no need to wait)
// - Memory is of size 128KB, with valid address ranging from 0x0 to 0x20000
// - I/O port is mapped to address higher than 0x30000 (mem_a[17:16]==2'b11)
// - 0x30000 read: read a byte from input
// - 0x30000 write: write a byte to output (write 0x00 is ignored)
// - 0x30004 read: read clocks passed since cpu starts (in dword, 4 bytes)
// - 0x30004 write: indicates program stop (will output '\0' through uart tx)

  assign rst_in_ = rst_in | ~rdy_in ;

  //pc_reg >> if
  wire [31 : 0] if_pc_i;

  wire jump_flag;
  wire branch_taken;
  wire [31 : 0] branch_pc;
  wire [31 : 0] branch_to;

  //if >> if_id
  wire [31 : 0] if_pc_o;
  wire [31 : 0] if_inst_o;

  //if_id >> id
  wire [31 : 0] id_pc_i;
  wire [31 : 0] id_inst_i;

  //id <--> register
  wire [31 : 0] id_r1_data_i;
  wire [31 : 0] id_r2_data_i;

  wire [4 : 0] id_r1_addr_o;
  wire [4 : 0] id_r2_addr_o;
  wire id_r1_enable_o;
  wire id_r2_enable_o;

  //id >> id_ex
  wire [31 : 0] id_r1_o;
  wire [31 : 0] id_r2_o;
  wire [31 : 0] id_imm_o;
  wire [4 : 0] id_rd_o;
  wire id_rd_enable_o;
  wire [4 : 0] id_aluop_o;
  wire [2 : 0] id_alusel_o;
  wire [31 : 0] id_pc_o;

  //id_ex >> ex
  wire [31 : 0] ex_r1_i;
  wire [31 : 0] ex_r2_i;
  wire [31 : 0] ex_imm_i;
  wire [4 : 0] ex_rd_i;
  wire ex_rd_enable_i;
  wire [4 : 0] ex_aluop_i;
  wire [2 : 0] ex_alusel_i;
  wire [31 : 0] ex_pc_i;

  //ex >> ex_mem
  wire [4 : 0] ex_aluop_o;
  wire [4 : 0] ex_rd_addr_o;
  wire [31 : 0] ex_mem_addr_o;
  wire ex_rd_enable_o;
  wire [31 : 0] ex_output_o;
  wire ex_ld_flag_o;

  //ex_mem >> mem
  wire [4 : 0] mem_aluop_i;
  wire [31 : 0] mem_data_i;
  wire [4 : 0] mem_rd_addr_i;
  wire [31 : 0] mem_rd_data_i;
  wire [31 : 0] mem_mem_addr_i;
  wire mem_rd_enable_i;

  //mem >> mem_wb
  wire [4 : 0] mem_rd_addr_o;
  wire [31 : 0] mem_rd_data_o;
  wire mem_rd_enable_o;

  //mem_ctrl
  wire [31 : 0] if_inst_i;
  wire mem_ram_r_req_o;
  wire mem_ram_w_req_o;
  wire mem_ram_done_i;
  wire [31 : 0] mem_ram_addr_o;
  wire [31 : 0] mem_ram_w_data_o;
  wire [31 : 0] mem_ram_r_data_i;
  wire inst_req;
  wire inst_done;
  wire [31 : 0] inst_addr_o;
  wire [31 : 0] inst_pc;
  wire [3 : 0] buffer_pointer;

  //wb
  wire [4 : 0] wb_addr;
  wire wb_enable;
  wire [31 : 0] wb_data;

  //stall
  wire if_stall_o;
  wire id_stall_o;
  wire mem_stall_o;
  wire [4 : 0] stall_signal;

  pc_reg pc_reg_unit(
    .clk(clk_in), .rst(rst_in_), .jump_flag(jump_flag), .branch_to(branch_to), .branch_taken(branch_taken), .branch_pc(branch_pc),
    .pc(if_pc_i), .stall_signal(stall_signal)
  );

  if_ if_unit(
    .clk(clk_in), .rst(rst_in_),
    .pc_i(if_pc_i), .inst_i(if_inst_i), 
    .inst_req(inst_req), .inst_addr_o(inst_addr_o),
    .inst_o(if_inst_o), .pc_o(if_pc_o), .inst_done(inst_done), .inst_pc(inst_pc),
    .if_stall(if_stall_o)
  );

  if_id if_id_unit(
    .clk(clk_in), .rst(rst_in_),
    .pc_i(if_pc_o), .inst_i(if_inst_o),
    .pc_o(id_pc_i), .inst_o(id_inst_i),
    .stall_signal(stall_signal), .jump_flag(jump_flag)
  );

  id id_unit(
    .rst(rst_in_),
    .pc_i(id_pc_i), .inst(id_inst_i),
    .r1_data_i(id_r1_data_i), .r2_data_i(id_r2_data_i),
    .ld_flag(ex_ld_flag_o), .ex_wb_flag(ex_rd_enable_o), .ex_wb_addr(ex_rd_addr_o), .ex_forward(ex_output_o),
    .mem_wb_flag(mem_rd_enable_o), .mem_wb_addr(mem_rd_addr_o), .mem_forward(mem_rd_data_o),
    .r1_addr(id_r1_addr_o), .r1_read_enable(id_r1_enable_o), .r2_addr(id_r2_addr_o), .r2_read_enable(id_r2_enable_o), .pc_o(id_pc_o), 
    .r1(id_r1_o), .r2(id_r2_o), .imm(id_imm_o), .rd(id_rd_o), .rd_enable(id_rd_enable_o), .aluop(id_aluop_o), .alusel(id_alusel_o),
    .id_stall(id_stall_o)
  );

  register register_unit(
    .clk(clk_in), .rst(rst_in_),
    .write_enable(wb_enable), .write_addr(wb_addr), .write_data(wb_data),
    .read_enable1(id_r1_enable_o), .read_addr1(id_r1_addr_o), .read_data1(id_r1_data_i), 
    .read_enable2(id_r2_enable_o), .read_addr2(id_r2_addr_o), .read_data2(id_r2_data_i)
  );

  id_ex id_ex_unit(
    .clk(clk_in), .rst(rst_in_),
    .r1_i(id_r1_o), .r2_i(id_r2_o), .imm_i(id_imm_o), .rd_i(id_rd_o), .rd_enable_i(id_rd_enable_o), .aluop_i(id_aluop_o), .alusel_i(id_alusel_o),
    .pc_i(id_pc_o), .pc_o(ex_pc_i), 
    .r1_o(ex_r1_i), .r2_o(ex_r2_i), .imm_o(ex_imm_i), .rd_o(ex_rd_i), .rd_enable_o(ex_rd_enable_i), .aluop_o(ex_aluop_i), .alusel_o(ex_alusel_i),
    .stall_signal(stall_signal), .jump_flag(jump_flag)
  );

  ex ex_unit(
    .rst(rst_in_),
    .r1(ex_r1_i), .r2(ex_r2_i), .imm(ex_imm_i), .rd(ex_rd_i), .rd_enable(ex_rd_enable_i), 
    .aluop(ex_aluop_i), .alusel(ex_alusel_i), .pc(ex_pc_i), .if_pc(if_pc_o), .id_pc(id_pc_o),
    .aluop_o(ex_aluop_o), .rd_addr_o(ex_rd_addr_o), .mem_addr_o(ex_mem_addr_o), .rd_enable_o(ex_rd_enable_o), 
    .branch_to(branch_to), .jump_flag(jump_flag), .branch_taken(branch_taken), .branch_pc(branch_pc),
    .output_(ex_output_o), .ld_flag(ex_ld_flag_o)
  );

  ex_mem ex_mem_unit(
    .clk(clk_in), .rst(rst_in_),
    .rd_data_i(ex_output_o), .rd_addr_i(ex_rd_addr_o), .mem_addr_i(ex_mem_addr_o),
    .aluop_i(ex_aluop_o), .rd_enable_i(ex_rd_enable_o),
    .aluop_o(mem_aluop_i), .rd_data_o(mem_rd_data_i), .rd_addr_o(mem_rd_addr_i), .mem_addr_o(mem_mem_addr_i), .rd_enable_o(mem_rd_enable_i),
    .stall_signal(stall_signal)
  );

  mem mem_unit(
    .rst(rst_in_),
    .rd_data_i(mem_rd_data_i), .rd_addr_i(mem_rd_addr_i), .aluop_i(mem_aluop_i), .rd_enable_i(mem_rd_enable_i),
    .rd_data_o(mem_rd_data_o), .rd_addr_o(mem_rd_addr_o), .rd_enable_o(mem_rd_enable_o), 
    .mem_addr_i(mem_mem_addr_i), .ram_done_i(mem_ram_done_i), .ram_r_data_i(mem_ram_r_data_i), 
    .ram_r_req_o(mem_ram_r_req_o), .ram_w_req_o(mem_ram_w_req_o), .ram_addr_o(mem_ram_addr_o), .ram_w_data_o(mem_ram_w_data_o),  
    .mem_stall(mem_stall_o), .buffer_pointer_o(buffer_pointer)
  );

  mem_ctrl mem_ctrl_unit(
    .clk(clk_in), .rst(rst_in_),
    .ram_r_req(mem_ram_r_req_o), .ram_w_req(mem_ram_w_req_o), .ram_addr_i(mem_ram_addr_o), .ram_w_data_i(mem_ram_w_data_o), 
    .ram_r_data_o(mem_ram_r_data_i), .ram_done_o(mem_ram_done_i), 
    .inst_addr_i(inst_addr_o), .inst_req(inst_req), .inst_o(if_inst_i), .inst_done_o(inst_done), .inst_pc(inst_pc),
    .mem_din(mem_din), .mem_dout(mem_dout), .mem_wr(mem_wr), .mem_a(mem_a), .buffer_pointer_i(buffer_pointer)
  );

  mem_wb mem_wb_unit(
    .clk(clk_in), .rst(rst_in_), 
    .rd_data_i(mem_rd_data_o), .rd_addr_i(mem_rd_addr_o), 
    .rd_enable_i(mem_rd_enable_o), 
    .rd_data_o(wb_data), .rd_addr_o(wb_addr), .rd_enable_o(wb_enable),
    .stall_signal(stall_signal)
  );

  stall stall_unit(
    .if_stall(if_stall_o), .id_stall(id_stall_o), .mem_stall(mem_stall_o),
    .stall_signal(stall_signal)
  );

endmodule