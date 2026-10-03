`timescale 1ns/1ps

module tb_axi4_lite_slave;

    parameter DATA_WIDTH = 32;
    parameter ADDR_WIDTH = 4;

    // Global Signals
    reg                       S_AXI_ACLK;
    reg                       S_AXI_ARESETN;

    // Write Address Channel
    reg  [ADDR_WIDTH-1:0]     S_AXI_AWADDR;
    reg                       S_AXI_AWVALID;
    wire                      S_AXI_AWREADY;

    // Write Data Channel
    reg  [DATA_WIDTH-1:0]     S_AXI_WDATA;
    reg  [(DATA_WIDTH/8)-1:0] S_AXI_WSTRB;
    reg                       S_AXI_WVALID;
    wire                      S_AXI_WREADY;

    // Write Response Channel
    wire [1:0]                S_AXI_BRESP;
    wire                      S_AXI_BVALID;
    reg                       S_AXI_BREADY;

    // Read Address Channel
    reg  [ADDR_WIDTH-1:0]     S_AXI_ARADDR;
    reg                       S_AXI_ARVALID;
    wire                      S_AXI_ARREADY;

    // Read Data Channel
    wire [DATA_WIDTH-1:0]     S_AXI_RDATA;
    wire [1:0]                S_AXI_RRESP;
    wire                      S_AXI_RVALID;
    reg                       S_AXI_RREADY;

    // Instantiate Unit Under Test (UUT)
    axi4_lite_slave #(
        .C_S_AXI_DATA_WIDTH(DATA_WIDTH),
        .C_S_AXI_ADDR_WIDTH(ADDR_WIDTH)
    ) uut (
        .S_AXI_ACLK(S_AXI_ACLK),
        .S_AXI_ARESETN(S_AXI_ARESETN),
        .S_AXI_AWADDR(S_AXI_AWADDR),
        .S_AXI_AWVALID(S_AXI_AWVALID),
        .S_AXI_AWREADY(S_AXI_AWREADY),
        .S_AXI_WDATA(S_AXI_WDATA),
        .S_AXI_WSTRB(S_AXI_WSTRB),
        .S_AXI_WVALID(S_AXI_WVALID),
        .S_AXI_WREADY(S_AXI_WREADY),
        .S_AXI_BRESP(S_AXI_BRESP),
        .S_AXI_BVALID(S_AXI_BVALID),
        .S_AXI_BREADY(S_AXI_BREADY),
        .S_AXI_ARADDR(S_AXI_ARADDR),
        .S_AXI_ARVALID(S_AXI_ARVALID),
        .S_AXI_ARREADY(S_AXI_ARREADY),
        .S_AXI_RDATA(S_AXI_RDATA),
        .S_AXI_RRESP(S_AXI_RRESP),
        .S_AXI_RVALID(S_AXI_RVALID),
        .S_AXI_RREADY(S_AXI_RREADY)
    );

    // Clock Generation (10ns period -> 100 MHz)
    always #5 S_AXI_ACLK = ~S_AXI_ACLK;

    // Task for AXI Write Transaction
    task axi_write(input [ADDR_WIDTH-1:0] addr, input [DATA_WIDTH-1:0] data);
        begin
            @(posedge S_AXI_ACLK);
            S_AXI_AWADDR  <= addr;
            S_AXI_AWVALID <= 1'b1;
            S_AXI_WDATA   <= data;
            S_AXI_WSTRB   <= 4'hf; // Enable all byte lanes
            S_AXI_WVALID  <= 1'b1;
            S_AXI_BREADY  <= 1'b1;

            @(posedge S_AXI_ACLK);
            while (!(S_AXI_AWREADY && S_AXI_WREADY)) @(posedge S_AXI_ACLK);

            S_AXI_AWVALID <= 1'b0;
            S_AXI_WVALID  <= 1'b0;

            @(posedge S_AXI_ACLK);
            while (!S_AXI_BVALID) @(posedge S_AXI_ACLK);
            
            $display("[WRITE] Address: 0x%h | Data Written: 0x%h | Response: 0x%h", addr, data, S_AXI_BRESP);
            
            S_AXI_BREADY  <= 1'b0;
            @(posedge S_AXI_ACLK);
        end
    endtask

    // Task for AXI Read Transaction
    task axi_read(input [ADDR_WIDTH-1:0] addr, output [DATA_WIDTH-1:0] data);
        begin
            @(posedge S_AXI_ACLK);
            S_AXI_ARADDR  <= addr;
            S_AXI_ARVALID <= 1'b1;
            S_AXI_RREADY  <= 1'b1;

            @(posedge S_AXI_ACLK);
            while (!S_AXI_ARREADY) @(posedge S_AXI_ACLK);
            S_AXI_ARVALID <= 1'b0;

            @(posedge S_AXI_ACLK);
            while (!S_AXI_RVALID) @(posedge S_AXI_ACLK);
            data = S_AXI_RDATA;

            $display("[READ]  Address: 0x%h | Data Read: 0x%h | Response: 0x%h", addr, data, S_AXI_RRESP);

            S_AXI_RREADY  <= 1'b0;
            @(posedge S_AXI_ACLK);
        end
    endtask

    reg [DATA_WIDTH-1:0] read_data;

    initial begin
        // Initialize Signals
        S_AXI_ACLK    = 0;
        S_AXI_ARESETN = 0;
        S_AXI_AWADDR  = 0;
        S_AXI_AWVALID = 0;
        S_AXI_WDATA   = 0;
        S_AXI_WSTRB   = 0;
        S_AXI_WVALID  = 0;
        S_AXI_BREADY  = 0;
        S_AXI_ARADDR  = 0;
        S_AXI_ARVALID = 0;
        S_AXI_RREADY  = 0;

        #20;
        S_AXI_ARESETN = 1; // Release reset
        #20;

        $display("=== [TEST START] AXI4-Lite Slave Verification ===");

        // Test 1: Write and Read Register 0 (Address 0x0)
        axi_write(4'h0, 32'hDEADBEEF);
        axi_read(4'h0, read_data);
        if (read_data == 32'hDEADBEEF)
            $display("[PASS] Reg 0 Match: Expected 0xDEADBEEF, Got 0x%h", read_data);
        else
            $error("[FAIL] Reg 0 Mismatch: Expected 0xDEADBEEF, Got 0x%h", read_data);

        // Test 2: Write and Read Register 2 (Address 0x8)
        axi_write(4'h8, 32'h12345678);
        axi_read(4'h8, read_data);
        if (read_data == 32'h12345678)
            $display("[PASS] Reg 2 Match: Expected 0x12345678, Got 0x%h", read_data);
        else
            $error("[FAIL] Reg 2 Mismatch: Expected 0x12345678, Got 0x%h", read_data);

        $display("=== [TEST COMPLETE] AXI4-Lite Simulation Finished Successfully ===");
        $finish;
    end

endmodule