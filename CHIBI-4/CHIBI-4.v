// ----------------------------- Program EEPROM (16-bit) -----------------------------
// Harvard program memory: 256 words of 16 bits.
// In real hardware this would be two 8-bit EEPROMs in parallel (high byte + low byte),
// both addressed by the same PC. Here it is modeled as a single 16-bit ROM.

module imem_16bit(
    input  [7:0]  pc,
    output [15:0] instruction
);
    reg [15:0] rom [0:255];

    // Program load (simulation / FPGA initialization only).
    // In real hardware, the EEPROM is already programmed.
    initial begin
        // $readmemh("program.hex", rom);
    end

    assign instruction = rom[pc];

endmodule

// ----------------------------- 4-bit Register File -----------------------------

module reg_file(
    input clk,
    input reg_write,
    input [1:0] rs1,
    input [1:0] rs2,
    input [1:0] rd,
    input [3:0] write_data,
    output [3:0] read_data1,
    output [3:0] read_data2
);

// 4 registers of 4 bits each
reg [3:0] registers [3:0];

always @(posedge clk) begin
    if (reg_write) begin
        registers[rd] <= write_data;
    end
end

assign read_data1 = registers[rs1];
assign read_data2 = registers[rs2];

endmodule

// ----------------------------- 4-bit ALU -----------------------------


module alu_4bit(
    input [3:0] A,
    input [3:0] B,
    input [2:0] OP,
    output reg [3:0] Result,
    output zero,
    output equal,
    output carry
);

// Operations
wire [4:0] full_sum = {1'b0, A} + {1'b0, B}; // 5-bit sum to capture carry
wire [3:0] sum_result = full_sum[3:0];
wire [4:0] full_sub = {1'b0, A} - {1'b0, B}; // 5-bit subtraction to capture borrow
wire [3:0] sub_result = full_sub[3:0];

wire [3:0] nand_result = ~(A & B);
wire [3:0] xor_result = A ^ B;
wire [3:0] nor_result = ~(A | B); 

always @(*) begin
    case (OP)
        3'b000: Result = sum_result; // Addition
        3'b100: Result = sub_result; // Subtraction
        3'b001 | 3'b101: Result = nand_result; // NAND
        3'b010 | 3'b110: Result = xor_result; // XOR
        3'b011 | 3'b111: Result = nor_result; // NOR
        default: Result = 4'b0000; // Default case
    endcase
end

// Flags

assign zero = (Result == 4'b0000);
assign equal = (A == B);
assign carry = (OP == 3'b000) ? full_sum[4] : (OP == 3'b100) ? full_sub[4] : 1'b0;

endmodule

// ----------------------------- Flag Register -----------------------------
// following the model of 74HC173

module flag_register(
    input        clk,
    input        flag_write_n,
    input        zero_in,
    input        equal_in,
    input        carry_in,
    output reg   zero_out,
    output reg   equal_out,
    output reg   carry_out
);
    always @(posedge clk) begin
        if (!flag_write_n) begin
            zero_out  <= zero_in;
            equal_out <= equal_in;
            carry_out <= carry_in;
        end
    end
endmodule

// ----------------------------- 256B Memory -----------------------------

module memory_256B(
    input        clk,
    input        mem_write,
    input        ram_high_or_low,
    input  [7:0] address,
    input  [3:0] write_data,
    output [3:0] read_data
);
    reg [7:0] mem [0:255];

    always @(posedge clk) begin
        if (mem_write) begin
            if (ram_high_or_low == 1'b0) mem[address][3:0] <= write_data;
            else                         mem[address][7:4] <= write_data;
        end
    end

    assign read_data = (ram_high_or_low == 1'b0) ? mem[address][3:0] : mem[address][7:4];
    
endmodule