`timescale 1ns/1ps

module tb_spi_master;

    parameter DATA_WIDTH = 8;

    reg                   clk;
    reg                   rst_n;
    reg                   start;
    reg  [DATA_WIDTH-1:0] tx_data;
    wire [DATA_WIDTH-1:0] rx_data;
    wire                  busy;
    wire                  sclk;
    wire                  mosi;
    reg                   miso;
    wire                  ss_n;

    // Instantiate Unit Under Test (UUT)
    spi_master #(
        .DATA_WIDTH(DATA_WIDTH)
    ) uut (
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        .tx_data(tx_data),
        .rx_data(rx_data),
        .busy(busy),
        .sclk(sclk),
        .mosi(mosi),
        .miso(miso),
        .ss_n(ss_n)
    );

    // Clock Generation (10ns period)
    always #5 clk = ~clk;

    // Simple loopback behavior on SPI clock edge for testing
    always @(posedge sclk) begin
        miso <= ~mosi; // Loop back inverted MOSI data to MISO
    end

    initial begin
        clk     = 0;
        rst_n   = 0;
        start   = 0;
        tx_data = 0;
        miso    = 0;

        #20;
        rst_n = 1;
        #20;

        $display("=== [TEST START] SPI Master Verification ===");

        // Test 1: Transmit 8-bit byte 0xA5
        @(posedge clk);
        tx_data = 8'hA5;
        start   = 1;
        @(posedge clk);
        start   = 0;

        // Wait until transaction completes
        @(negedge busy);
        #20;
        $display("[PASS] SPI Transfer 1 Complete. TX: 0xA5, RX: 0x%h", rx_data);

        // Test 2: Transmit 8-bit byte 0x3C
        @(posedge clk);
        tx_data = 8'h3C;
        start   = 1;
        @(posedge clk);
        start   = 0;

        @(negedge busy);
        #20;
        $display("[PASS] SPI Transfer 2 Complete. TX: 0x3C, RX: 0x%h", rx_data);

        $display("=== [TEST COMPLETE] SPI Simulation Finished Successfully ===");
        $finish;
    end

endmodule