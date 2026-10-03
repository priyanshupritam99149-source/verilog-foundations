module async_fifo #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 3   // Depth = 8
)(
    // Write Domain
    input  wire                  wr_clk,
    input  wire                  wr_rst_n,
    input  wire                  wr_en,
    input  wire [DATA_WIDTH-1:0] din,
    output reg                   full,

    // Read Domain
    input  wire                  rd_clk,
    input  wire                  rd_rst_n,
    input  wire                  rd_en,
    output reg  [DATA_WIDTH-1:0] dout,
    output reg                   empty
);

    localparam DEPTH = (1 << ADDR_WIDTH);
    reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];

    // Pointers
    reg  [ADDR_WIDTH:0] wr_ptr_bin, wr_ptr_gray;
    reg  [ADDR_WIDTH:0] rd_ptr_bin, rd_ptr_gray;

    // Synchronized Pointers
    reg  [ADDR_WIDTH:0] rd_ptr_gray_sync1, rd_ptr_gray_sync2;
    reg  [ADDR_WIDTH:0] wr_ptr_gray_sync1, wr_ptr_gray_sync2;

    // ==========================================
    // 1. WRITE DOMAIN LOGIC
    // ==========================================
    wire push = wr_en && !full;
    wire [ADDR_WIDTH:0] wr_ptr_bin_next  = wr_ptr_bin + push;
    wire [ADDR_WIDTH:0] wr_ptr_gray_next = (wr_ptr_bin_next >> 1) ^ wr_ptr_bin_next;

    // Lookahead for full flag (breaks combinational loop)
    wire [ADDR_WIDTH:0] wr_ptr_bin_plus1  = wr_ptr_bin + 1'b1;
    wire [ADDR_WIDTH:0] wr_ptr_gray_plus1 = (wr_ptr_bin_plus1 >> 1) ^ wr_ptr_bin_plus1;

    always @(posedge wr_clk or negedge wr_rst_n) begin
        if (!wr_rst_n) begin
            wr_ptr_bin  <= 0;
            wr_ptr_gray <= 0;
        end else begin
            wr_ptr_bin  <= wr_ptr_bin_next;
            wr_ptr_gray <= wr_ptr_gray_next;
        end
    end

    // Memory Write
    always @(posedge wr_clk) begin
        if (push)
            mem[wr_ptr_bin[ADDR_WIDTH-1:0]] <= din;
    end

    // Read Gray Pointer Synchronizer (Write Domain)
    always @(posedge wr_clk or negedge wr_rst_n) begin
        if (!wr_rst_n) begin
            rd_ptr_gray_sync1 <= 0;
            rd_ptr_gray_sync2 <= 0;
        end else begin
            rd_ptr_gray_sync1 <= rd_ptr_gray;
            rd_ptr_gray_sync2 <= rd_ptr_gray_sync1;
        end
    end

    // Full Flag Generation (No circular dependency)
    always @(*) begin
        full = (wr_ptr_gray_plus1 == {~rd_ptr_gray_sync2[ADDR_WIDTH:ADDR_WIDTH-1], rd_ptr_gray_sync2[ADDR_WIDTH-2:0]});
    end

    // ==========================================
    // 2. READ DOMAIN LOGIC
    // ==========================================
    wire pop = rd_en && !empty;
    wire [ADDR_WIDTH:0] rd_ptr_bin_next  = rd_ptr_bin + pop;
    wire [ADDR_WIDTH:0] rd_ptr_gray_next = (rd_ptr_bin_next >> 1) ^ rd_ptr_bin_next;

    always @(posedge rd_clk or negedge rd_rst_n) begin
        if (!rd_rst_n) begin
            rd_ptr_bin  <= 0;
            rd_ptr_gray <= 0;
            dout        <= 0;
        end else begin
            rd_ptr_bin  <= rd_ptr_bin_next;
            rd_ptr_gray <= rd_ptr_gray_next;
        end
    end

    // Memory Read
    always @(posedge rd_clk) begin
        if (pop)
            dout <= mem[rd_ptr_bin[ADDR_WIDTH-1:0]];
    end

    // Write Gray Pointer Synchronizer (Read Domain)
    always @(posedge rd_clk or negedge rd_rst_n) begin
        if (!rd_rst_n) begin
            wr_ptr_gray_sync1 <= 0;
            wr_ptr_gray_sync2 <= 0;
        end else begin
            wr_ptr_gray_sync1 <= wr_ptr_gray;
            wr_ptr_gray_sync2 <= wr_ptr_gray_sync1;
        end
    end

    // Empty Flag Generation
    always @(*) begin
        empty = (rd_ptr_gray_next == wr_ptr_gray_sync2);
    end

endmodule