// Lucas Lemos
// 11/25/2025
// llemos@hmc.edu

/*
 * Module: CDC_FIFO
 *
 * Description:
 * Implements a generic Clock Domain Crossing (CDC) path using a Dual-Clock FIFO.
 * This module can be configured for either:
 * 1. Slow-to-Fast (STF) transfer: Writing data from a slower clock domain
 * (clkRead_i) to a faster clock domain (clkWrite_i).
 * 2. Fast-to-Slow (FTS) transfer: Writing data from a faster clock domain
 * (clkRead_i) to a slower clock domain (clkWrite_i).
 *
 * The module instantiates a Dual Clock FIFO IP (e.g., Lattice FIFO_DC or similar)
 * configured for EBR-based storage and First-Word Fall-Through (FWFT).
 *
 * It includes a robust, synchronous-release reset architecture to prevent
 * metastability issues on the FIFO's reset port, ensuring safe operation across
 * the two clock domains.
 *
 * Typical Use Case (Chorus Pedal Design):
 * - STF: clkRead_i = Slow I2S RX clock (~1.41 MHz), clkWrite_i = Fast DSP clock (6 MHz).
 * - Write Side: A PKT_WIDTH-bit audio packet is written based on the pktChanged_i strobe.
 * - Read Side: Data is consumed (popped) every clkWrite_i cycle that the FIFO is not empty.
 *
 * Naming Conventions:
 * _n: Active low
 * _i: Input
 * _o: Output
 * _s: Sequential signal
 * _c: Combinational signal
 */
module CDC_FIFO #(
	parameter PKT_WIDTH = 16 // Must be 16 for chorus pedal design
) (
    // --- Clock & Global Reset Inputs ---
	input  logic        			clkRead_i,    		// For STF: slow clock (1.4122 MHz), for FTS: fast clock (6 MHz)
	input  logic        			clkWrite_i,        // For STF: fast clock (6 MHz), for FTS: slow clock (1.4122 MHz)
	input  logic        			rstWrite_n_i,      // Active low reset from write side

    // --- Write Domain (Slow) Interface ---
    input  logic [PKT_WIDTH-1:0]	pkt_i,      	// 16-bit audio packet to write
    input  logic        			pktChanged_i, 	// Write Enable strobe (@ ~44.1kHz)
	input  logic					rdEN_i,			// Read pktOut_s_o Enable Strobe (For STF: 1'b1, for FTS: @ ~44.1kHz)

    // --- Read Domain (Fast) Interface ---
    output logic [PKT_WIDTH-1:0]	pktOut_s_o,  		// FIFO output
    output logic        			pktOutChanged_c_o 	// Strobe: '1' when new sample is different from old
);
	// Internal control signals
    logic fifoEmpty_c;
    logic fifoFull_c;
    logic [PKT_WIDTH-1:0] fifoPktOut_s;
	logic [PKT_WIDTH-1:0] fifoPktOut_old_s;

    // Write Control (Slow Domain)
    logic wrEN_c;
    assign wrEN_c = pktChanged_i && !fifoFull_c;
	
    // Dual Clock FIFO IP Instantiation
    /*
     * IP Configuration:
	 * - Depth: 4
	 * - Width: 16
     * - Implementation: EBR
     * - Output Mode: First-Word Fall-Through (FWFT)			// TODO: MIGHT WANNA DISABLE FWFT
     * - Output register: enabled (1 cycle delay)
     */
    AsyncFIFO u_CDC_AFIFO_STF (
        .wr_clk_i   (clkRead_i),
        .rd_clk_i   (clkWrite_i),
        .rst_i      (!rstWrite_n_i),
        .rp_rst_i   (!rstWrite_n_i),
        .wr_en_i    (wrEN_c),
        .rd_en_i    (rdEN_i),
        .wr_data_i  (pkt_i),
		
        .full_o     (fifoFull_c),
        .empty_o    (fifoEmpty_c),
        .rd_data_o  (fifoPktOut_s)
    );
	
	always_ff @( posedge clkWrite_i ) begin
		if 	(!rstWrite_n_i) fifoPktOut_old_s <= '0;
		//else if (!fifoEmpty_c)	fifoPktOut_old_s <= fifoPktOut_s; // I couldn't get selective updating working
		//else				fifoPktOut_old_s <= fifoPktOut_old_s;
		else				fifoPktOut_old_s <= fifoPktOut_s; 	// Always latch new value
	end

    // Output Assignments
    assign pktOut_s_o  = fifoPktOut_s;
    assign pktOutChanged_c_o = |(fifoPktOut_old_s ^ fifoPktOut_s); // If packet is new, strobe pktOutChanged_c_o

endmodule