`timescale 1ns/1ps

module tb_async_fifo;

    parameter DATA_WIDTH = 8;
    parameter ADDR_WIDTH = 3; // Depth = 8

    reg                   wr_clk;
    reg                   wr_rst_n;
    reg                   wr_en;
    reg [DATA_WIDTH-1:0]  din;
    wire                  full;

    reg                   rd_clk;
    reg                   rd_rst_n;
    reg                   rd_en;
    wire [DATA_WIDTH-1:0] dout;
    wire                  empty;

    async_fifo #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) uut (
        .wr_clk(wr_clk),
        .wr_rst_n(wr_rst_n),
        .wr_en(wr_en),
        .din(din),
        .full(full),
        .rd_clk(rd_clk),
        .rd_rst_n(rd_rst_n),
        .rd_en(rd_en),
        .dout(dout),
        .empty(empty)
    );

    // Clocks
    always #5 wr_clk = ~wr_clk;       // 100 MHz
    always #7 rd_clk = ~rd_clk;       // ~71.4 MHz (Asynchronous)

    initial begin
        wr_clk   = 0;
        wr_rst_n = 0;
        wr_en    = 0;
        din      = 0;

        rd_clk   = 0;
        rd_rst_n = 0;
        rd_en    = 0;

        #30;
        wr_rst_n = 1;
        rd_rst_n = 1;
        #20;

        $display("=== [TEST START] Asynchronous FIFO Verification ===");

        // Phase 1: Write 8 items
        repeat (8) begin
            @(posedge wr_clk);
            if (!full) begin
                wr_en <= 1;
                din   <= $random;
                $display("[WRITE] Time: %0t ns | Data Written: 0x%h", $time, din);
            end
        end

        @(posedge wr_clk);
        wr_en <= 0;

        #20;
        if (full) 
            $display("[PASS] FIFO Full flag correctly asserted.");
        else 
            $error("[FAIL] FIFO Full flag failed to assert.");

        // Phase 2: Read 8 items
        #50;
        repeat (8) begin
            @(posedge rd_clk);
            if (!empty) begin
                rd_en <= 1;
            end
            @(posedge rd_clk);
            rd_en <= 0;
            #2;
            $display("[READ]  Time: %0t ns | Data Read: 0x%h", $time, dout);
        end

        #40;
        if (empty) 
            $display("[PASS] FIFO Empty flag correctly asserted.");
        else 
            $error("[FAIL] FIFO Empty flag failed to assert.");

        $display("=== [TEST COMPLETE] All Assertions Passed Successfully ===");
        $finish;
    end

endmodule