# Verilog Digital Design Portfolio

A robust collection of synthesizable RTL modules and self-checking testbenches for digital design, featuring an ALU, Async FIFO, AXI4-Lite Slave, and SPI Master verified via Icarus Verilog.

## Project Structure

```text
.
├── src/                      # Synthesizable RTL Design Modules
│   ├── alu.v                 # Arithmetic Logic Unit
│   ├── async_fifo.v          # Asynchronous FIFO with CDC logic
│   ├── axi4_lite_slave.v     # AXI4-Lite Slave Interface
│   └── spi_master.v          # SPI Master Controller
│
└── sim/                      # Automated Self-Checking Testbenches
    ├── tb_alu.v
    ├── tb_async_fifo.v
    ├── tb_axi4_lite_slave.v
    └── tb_spi_master.v
