module axi4_lite_slave #(
    parameter C_S_AXI_DATA_WIDTH = 32,
    parameter C_S_AXI_ADDR_WIDTH = 4   // 4 address bits = 16 bytes address space (4 registers)
)(
    // Global Signals
    input  wire                               S_AXI_ACLK,
    input  wire                               S_AXI_ARESETN,

    // Write Address Channel
    input  wire [C_S_AXI_ADDR_WIDTH-1:0]      S_AXI_AWADDR,
    input  wire                               S_AXI_AWVALID,
    output reg                                S_AXI_AWREADY,

    // Write Data Channel
    input  wire [C_S_AXI_DATA_WIDTH-1:0]      S_AXI_WDATA,
    input  wire [(C_S_AXI_DATA_WIDTH/8)-1:0]  S_AXI_WSTRB,
    input  wire                               S_AXI_WVALID,
    output reg                                S_AXI_WREADY,

    // Write Response Channel
    output reg  [1:0]                         S_AXI_BRESP,
    output reg                                S_AXI_BVALID,
    input  wire                               S_AXI_BREADY,

    // Read Address Channel
    input  wire [C_S_AXI_ADDR_WIDTH-1:0]      S_AXI_ARADDR,
    input  wire                               S_AXI_ARVALID,
    output reg                                S_AXI_ARREADY,

    // Read Data Channel
    output reg  [C_S_AXI_DATA_WIDTH-1:0]      S_AXI_RDATA,
    output reg  [1:0]                         S_AXI_RRESP,
    output reg                                S_AXI_RVALID,
    input  wire                               S_AXI_RREADY
);

    // Internal Register File (4 registers of 32-bit)
    reg [C_S_AXI_DATA_WIDTH-1:0] loc_addr [0:3];

    // Local signals for handshaking control
    reg [C_S_AXI_ADDR_WIDTH-1:0] axi_awaddr;
    reg [C_S_AXI_ADDR_WIDTH-1:0] axi_araddr;

    // ==========================================
    // 1. WRITE ADDRESS & DATA HANDSHAKE
    // ==========================================
    always @(posedge S_AXI_ACLK) begin
        if (!S_AXI_ARESETN) begin
            S_AXI_AWREADY <= 1'b0;
            S_AXI_WREADY  <= 1'b0;
            axi_awaddr    <= 0;
        end else begin
            // Ready to accept Write Address
            if (!S_AXI_AWREADY && S_AXI_AWVALID && S_AXI_WVALID) begin
                S_AXI_AWREADY <= 1'b1;
                axi_awaddr    <= S_AXI_AWADDR;
            end else begin
                S_AXI_AWREADY <= 1'b0;
            end

            // Ready to accept Write Data
            if (!S_AXI_WREADY && S_AXI_WVALID && S_AXI_AWVALID) begin
                S_AXI_WREADY <= 1'b1;
            end else begin
                S_AXI_WREADY <= 1'b0;
            end
        end
    end

    // ==========================================
    // 2. WRITE TO REGISTER FILE
    // ==========================================
    wire slv_reg_wren = S_AXI_AWREADY && S_AXI_AWVALID && S_AXI_WREADY && S_AXI_WVALID;
    wire [1:0] reg_index = axi_awaddr[3:2]; // Map address to 4 words

    always @(posedge S_AXI_ACLK) begin
        if (!S_AXI_ARESETN) begin
            loc_addr[0] <= 0;
            loc_addr[1] <= 0;
            loc_addr[2] <= 0;
            loc_addr[3] <= 0;
        end else if (slv_reg_wren) begin
            case (reg_index)
                2'h0: if (S_AXI_WSTRB[0]) loc_addr[0] <= S_AXI_WDATA;
                2'h1: if (S_AXI_WSTRB[0]) loc_addr[1] <= S_AXI_WDATA;
                2'h2: if (S_AXI_WSTRB[0]) loc_addr[2] <= S_AXI_WDATA;
                2'h3: if (S_AXI_WSTRB[0]) loc_addr[3] <= S_AXI_WDATA;
                default: ;
            endcase
        end
    end

    // ==========================================
    // 3. WRITE RESPONSE CHANNEL
    // ==========================================
    always @(posedge S_AXI_ACLK) begin
        if (!S_AXI_ARESETN) begin
            S_AXI_BVALID <= 1'b0;
            S_AXI_BRESP  <= 2'b00; // OKAY response
        end else begin
            if (slv_reg_wren && !S_AXI_BVALID) begin
                S_AXI_BVALID <= 1'b1;
                S_AXI_BRESP  <= 2'b00;
            end else if (S_AXI_BREADY && S_AXI_BVALID) begin
                S_AXI_BVALID <= 1'b0;
            end
        end
    end

    // ==========================================
    // 4. READ ADDRESS & DATA CHANNEL
    // ==========================================
    always @(posedge S_AXI_ACLK) begin
        if (!S_AXI_ARESETN) begin
            S_AXI_ARREADY <= 1'b0;
            axi_araddr    <= 0;
        end else begin
            if (!S_AXI_ARREADY && S_AXI_ARVALID) begin
                S_AXI_ARREADY <= 1'b1;
                axi_araddr    <= S_AXI_ARADDR;
            end else begin
                S_AXI_ARREADY <= 1'b0;
            end
        end
    end

    always @(posedge S_AXI_ACLK) begin
        if (!S_AXI_ARESETN) begin
            S_AXI_RVALID <= 1'b0;
            S_AXI_RRESP  <= 2'b00;
            S_AXI_RDATA  <= 0;
        end else begin
            if (S_AXI_ARREADY && S_AXI_ARVALID && !S_AXI_RVALID) begin
                S_AXI_RVALID <= 1'b1;
                S_AXI_RRESP  <= 2'b00; // OKAY response
                case (axi_araddr[3:2])
                    2'h0: S_AXI_RDATA <= loc_addr[0];
                    2'h1: S_AXI_RDATA <= loc_addr[1];
                    2'h2: S_AXI_RDATA <= loc_addr[2];
                    2'h3: S_AXI_RDATA <= loc_addr[3];
                    default: S_AXI_RDATA <= 32'h0;
                endcase
            end else if (S_AXI_RREADY && S_AXI_RVALID) begin
                S_AXI_RVALID <= 1'b0;
            end
        end
    end

endmodule