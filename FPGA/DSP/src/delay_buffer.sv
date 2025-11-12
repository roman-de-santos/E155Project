// Lucas Lemos
// 11/6/2025
// llemos@hmc.edu

/*
 * Module: delay_buffer
 *
 * Description:
 * Implements a circular delay buffer (FIFO) intended for audio DSP.
 * It writes incoming valid packets (`pkt_i`) to a circular buffer and
 * reads them out after a variable delay. The delay is composed of a
 * fixed average delay (`AVG_DELAY`) and a variable extra delay
 * (`extra_delay_i`), which would be supplied by an LFO in a chorus
 * effect.
 *
 * This module infers a synchronous-read SPRAM, which is typical
 * for iCE40 FPGAs. This means the output data (`pkt_delayed_o`)
 * appears on the clock cycle *after* the read address is calculated.
 *
 * Parameters:
 * BUF_DEPTH   - Total number of samples in the buffer.
 * PKT_WIDTH   - Bit-width of each data sample (packet).
 * AVG_DELAY   - The fixed, average delay in samples.
 *
 * Ports:
 * rst_n         - Active-low synchronous reset.
 * clk           - System clock (CLK_DSP).
 * pkt_i         - Input data packet from the asynchronous FIFO.
 * pkt_valid_i   - '1' when `pkt_i` contains valid data to be written.
 * extra_delay_i - Additional variable delay (from LFO).
 * pkt_delayed_o - Delayed data packet output.
 */
module delay_buffer #(
    parameter BUF_DEPTH   = 7680,
    parameter PKT_WIDTH   = 16,
    parameter AVG_DELAY   = 882
) (
    input  logic                   rst_n,
    input  logic                   clk,
    input  logic [PKT_WIDTH-1:0]   pkt_i,
    input  logic                   pkt_valid_i,
    input  logic [PKT_CEILING-1:0] extra_delay_i,
    output logic [PKT_WIDTH-1:0]   pkt_delayed_o
);

    // Calculate the width of the extra_delay input port, as specified.
    localparam PKT_CEILING = $clog2(PKT_WIDTH);

    // Calculate the address width needed to index the buffer RAM.
    // $clog2(7680) = 13 bits
    localparam ADDR_WIDTH = $clog2(BUF_DEPTH);

    // This is the RAM inferred for the circular buffer.
    // iCE40 SPRAM is synchronous read.
    logic [PKT_WIDTH-1:0] buffer [BUF_DEPTH-1:0];

    // Registers for pointers and output
    logic [ADDR_WIDTH-1:0] write_ptr_reg;
    logic [PKT_WIDTH-1:0]  pkt_delayed_o_reg;

    // Combinational signals for next state/calculations
    logic [ADDR_WIDTH-1:0] write_ptr_next;
    logic [ADDR_WIDTH-1:0] read_addr_comb;

    // Combinational logic for the next write pointer
    // This pointer wraps around at BUF_DEPTH.
    always_comb begin
        if (write_ptr_reg == (BUF_DEPTH - 1'b1)) begin
            write_ptr_next = '0;
        end else begin
            write_ptr_next = write_ptr_reg + 1'b1;
        end
    end

    // Combinational logic for the read pointer calculation
    always_comb begin
        logic [ADDR_WIDTH-1:0] total_delay;

        // Calculate the total delay.
        // We assume AVG_DELAY + extra_delay_i will not exceed ADDR_WIDTH.
        // Max delay 882 + 15 = 897, which is < 7680 (13 bits).
        total_delay = AVG_DELAY[ADDR_WIDTH-1:0] + extra_delay_i;

        // Calculate the read pointer with wrap-around logic.
        // This implements: (write_ptr_reg - total_delay) % BUF_DEPTH
        // in a way that is friendly to synthesis (no modulo operator).
        if (write_ptr_reg >= total_delay) begin
            read_addr_comb = write_ptr_reg - total_delay;
        end else begin
            // Handle wrap-around (underflow)
            read_addr_comb = BUF_DEPTH + write_ptr_reg - total_delay;
        end
    end

    // Main sequential logic for writing and reading
    always_ff @(posedge clk) begin
        if (!rst_n) begin
            // Active-low synchronous reset
            write_ptr_reg     <= '0;
            pkt_delayed_o_reg <= '0;
            // Note: RAM contents are not explicitly reset
        end else begin
            // Write logic:
            // If new data is valid, write it to the *next* address
            // and update the write pointer.
            if (pkt_valid_i) begin
                buffer[write_ptr_next] <= pkt_i;
                write_ptr_reg <= write_ptr_next;
            end

            // Read logic (Synchronous Read):
            // The data from the address calculated *in this cycle*
            // (`read_addr_comb`) will be read from the buffer
            // and clocked into the output register on this clock edge.
            pkt_delayed_o_reg <= buffer[read_addr_comb];
        end
    end

    // Assign the registered output to the module's output port
    assign pkt_delayed_o = pkt_delayed_o_reg;

endmodule