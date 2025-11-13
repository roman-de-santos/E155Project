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
 * (`extra_read_addr_delay_i`), which would be supplied by an LFO in a chorus
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
 * rst_n         			- Active-low synchronous reset.
 * clk           			- System clock (CLK_DSP).
 * pkt_i        			- Input data packet from the asynchronous FIFO.
 * pkt_valid_i   			- '1' when `pkt_i` contains valid data to be written.
 * extra_read_addr_delay_i 	- Additional variable delay (from LFO).
 * pkt_delayed_o 			- Delayed data packet output.
 */
module delay_buffer #(
    parameter BUF_DEPTH   = 7680, // Default buffer is small enough to fit within the EBR hardware limit if needed
    parameter PKT_WIDTH   = 16,
    parameter AVG_DELAY   = 882,
	parameter ADDR_WIDTH  = $clog2(BUF_DEPTH) // log_2(7680) = 13 bits
) (
    input  logic                   rst_n,
    input  logic                   clk,
    input  logic [PKT_WIDTH-1:0]   pkt_i,
    input  logic                   pkt_valid_i,
    input  logic [ADDR_WIDTH-1:0]  extra_read_addr_delay_i,
	
    output logic [PKT_WIDTH-1:0]   pkt_delayed_o
);
	
	localparam MAX_DELAY = BUF_DEPTH - 10; // choice of 10 was arbitrary

    // RAM inferred for the circular buffer. iCE40 SPRAM is synchronous read.
    logic [PKT_WIDTH-1:0] buffer [BUF_DEPTH-1:0];

    // Registers for storing write address and output packet
    logic [ADDR_WIDTH-1:0] write_addr_reg;
    logic [PKT_WIDTH-1:0]  pkt_delayed_o_reg;

    // Combinational internal signals
    logic [ADDR_WIDTH-1:0] write_addr_nxt;
    logic [ADDR_WIDTH-1:0] read_addr_comb;

    // Calculate next write address. Address wraps around at BUF_DEPTH.
    always_comb begin
        if (write_addr_reg == (BUF_DEPTH - 1'b1)) begin
            write_addr_nxt = '0;
        end else begin
            write_addr_nxt = write_addr_reg + 1'b1;
        end
    end

    // Calculate read address
    always_comb begin
        // Total delay local variable
		logic [ADDR_WIDTH-1:0] total_delay;
		total_delay = AVG_DELAY[ADDR_WIDTH-1:0] + extra_read_addr_delay_i;
		if (total_delay > MAX_DELAY) total_delay = MAX_DELAY;

        // Calculate the read address with wrap-around logic.
        // Implements: (write_addr_reg - total_delay) % BUF_DEPTH, in synthesis-friendly way
        if (write_addr_reg >= total_delay) begin
            read_addr_comb = write_addr_reg - total_delay;
        end else begin 	// Handle wrap-around (underflow)
            read_addr_comb = BUF_DEPTH[ADDR_WIDTH-1:0] + write_addr_reg - total_delay;
        end
    end

    // Main sequential logic for writing and reading
    always_ff @(posedge clk) begin
        if (!rst_n) begin
            write_addr_reg    <= '0;
            pkt_delayed_o_reg <= '0;
            // Note: RAM contents are not explicitly reset. May cause a pop on startup.
        end else begin
            // Write logic
            if (pkt_valid_i) begin
                buffer[write_addr_nxt] <= pkt_i;
                write_addr_reg <= write_addr_nxt;
            end

            // Read logic (Synchronous Read):
            // The data from the address calculated *in this cycle*
            // (`read_addr_comb`) will be read from the buffer
            // and clocked into the output register on this clock edge.
            pkt_delayed_o_reg <= buffer[read_addr_comb];
        end
    end

    assign pkt_delayed_o = pkt_delayed_o_reg;

endmodule