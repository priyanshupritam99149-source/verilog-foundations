// Module: ALU Testbench
// Description: Applies test vectors with time delays to verify ALU operations

`timescale 1ns / 1ps

module alu_tb;

    // 1. Declare inputs as 'reg' so we can drive them inside initial blocks
    reg [7:0] a;
    reg [7:0] b;
    reg [2:0] op_sel;

    // 2. Declare outputs as 'wire' to read from the ALU module
    wire [7:0] result;
    wire       zero_flag;

    // 3. Instantiate the Unit Under Test (UUT)
    alu uut (
        .a(a),
        .b(b),
        .op_sel(op_sel),
        .result(result),
        .zero_flag(zero_flag)
    );

    // 4. Apply test vectors with time delays
    initial begin
        // Open waveform dump file for GTKWave simulation inspection
        $dumpfile("waveforms/alu_waveform.vcd");
        $dumpvars(0, alu_tb);

        // Initialize inputs
        a = 8'd0; b = 8'd0; op_sel = 3'b000;

        // Test Case 1: Addition (15 + 10 = 25)
        #10;
        a = 8'd15; b = 8'd10; op_sel = 3'b000; 

        // Test Case 2: Subtraction (50 - 20 = 30)
        #10;
        a = 8'd50; b = 8'd20; op_sel = 3'b001; 

        // Test Case 3: Bitwise AND (12 & 10)
        #10;
        a = 8'b00001100; b = 8'b00001010; op_sel = 3'b010; 

        // Test Case 4: Zero Flag Test (5 - 5 = 0, zero_flag should go high)
        #10;
        a = 8'd5; b = 8'd5; op_sel = 3'b001; 

        // End simulation after a final delay
        #20;
        $finish;
    end

endmodule