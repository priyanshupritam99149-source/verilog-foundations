// Module: 8-bit Arithmetic Logic Unit (ALU)
// Description: Pure combinational logic block for basic math and bitwise operations.

module alu (
    input wire [7:0] a,       // Operand A (8-bit data)
    input wire [7:0] b,       // Operand B (8-bit data)
    input wire [2:0] op_sel,  // Operation Select input (3 bits -> 8 possible operations)
    output reg [7:0] result,  // Result of the operation
    output wire      zero_flag // High (1) if the result is 0
);

    // Combinational logic block evaluated whenever inputs change
    always @(*) begin
        case (op_sel)
            3'b000: result = a + b;       // Addition
            3'b001: result = a - b;       // Subtraction
            3'b010: result = a & b;       // Bitwise AND
            3'b011: result = a | b;       // Bitwise OR
            3'b100: result = a ^ b;       // Bitwise XOR
            default: result = 8'b00000000; // Default safety fallback
        endcase
    end

    // Continuous assignment for a zero flag (useful for processor branching)
    assign zero_flag = (result == 8'b00000000) ? 1'b1 : 1'b0;

endmodule