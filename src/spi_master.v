module spi_master #(
    parameter DATA_WIDTH = 8
)(
    input  wire                   clk,
    input  wire                   rst_n,
    input  wire                   start,
    input  wire [DATA_WIDTH-1:0]  tx_data,
    output reg  [DATA_WIDTH-1:0]  rx_data,
    output reg                    busy,
    output reg                    sclk,
    output reg                    mosi,
    input  wire                   miso,
    output reg                    ss_n
);

    reg [2:0] state;
    reg [3:0] bit_cnt;
    reg [DATA_WIDTH-1:0] tx_shft;
    reg [DATA_WIDTH-1:0] rx_shft;

    localparam IDLE        = 3'd0,
               START_TRANS = 3'd1,
               SAMPLE      = 3'd2,
               SHIFT       = 3'd3,
               DONE        = 3'd4;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state   <= IDLE;
            busy    <= 1'b0;
            sclk    <= 1'b0;
            mosi    <= 1'b0;
            ss_n    <= 1'b1;
            bit_cnt <= 0;
            rx_data <= 0;
            tx_shft <= 0;
            rx_shft <= 0;
        end else begin
            case (state)
                IDLE: begin
                    busy <= 1'b0;
                    ss_n <= 1'b1;
                    sclk <= 1'b0;
                    if (start) begin
                        tx_shft <= tx_data;
                        busy    <= 1'b1;
                        ss_n    <= 1'b0;
                        bit_cnt <= DATA_WIDTH - 1;
                        state   <= START_TRANS;
                    end
                end

                START_TRANS: begin
                    sclk <= 1'b0;
                    mosi <= tx_shft[bit_cnt];
                    state <= SAMPLE;
                end

                SAMPLE: begin
                    sclk <= 1'b1; // Rising edge: sample MISO
                    rx_shft <= {rx_shft[DATA_WIDTH-2:0], miso};
                    state <= SHIFT;
                end

                SHIFT: begin
                    sclk <= 1'b0; // Falling edge: shift next bit
                    if (bit_cnt == 0) begin
                        state <= DONE;
                    end else begin
                        bit_cnt <= bit_cnt - 1;
                        mosi <= tx_shft[bit_cnt - 1];
                        state <= SAMPLE;
                    end
                end

                DONE: begin
                    ss_n <= 1'b1;
                    busy <= 1'b0;
                    rx_data <= rx_shft;
                    state <= IDLE;
                end

                default: state <= IDLE;
            endcase
        end
    end

endmodule