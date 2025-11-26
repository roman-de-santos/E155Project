// Lucas Lemos
// 11/25/2025
// llemos@hmc.edu

/*
 * Module: CDC_STF
 *
 * Description:
 * Implements a Clock Domain Crossing (CDC) path from the slow I2S RX domain
 * (1.4112 MHz bit clock) to the fast DSP domain (6 MHz system clock). I.e.,
 * slow to fast (STF).
 *
 * This module instantiates the Lattice FIFO_DC IP (configured for EBR-based
 * storage and First-Word Fall-Through (FWFT)).
 *
 * The module includes a robust, synchronous-release reset architecture to
 * prevent metastability issues on the FIFO's reset port, ensuring safe
 * operation across the two clock domains.
 *
 * Write side (Slow): A 16-bit audio packet is written every ~44.1kHz.
 * Read side (Fast): Data is consumed (popped) every 48 MHz cycle that the FIFO is not empty.
 *
 * Naming Conventions:
 * _clk_i: Clock Input
 * _rst_i: Reset Input
 * _data_i/_o: Data Input/Output (Registered/Port)
 * _comb: Combinational internal signal
 */
module CDC_STF #(
	parameter PKT_WIDTH = 16 // Must be 16 for this design
) (
    // --- Clock & Global Reset Inputs ---
	input  logic        			clkI2SBit_i,    	// Slow Domain: 1.4112 MHz BCLK
	input  logic        			clkDSP_i,        // Fast Domain: 6 MHz DSP Clock
	input  logic        			rstDSP_n_i,        	// Active low reset from DSP side

    // --- Write Domain (Slow) Interface ---
    input  logic [PKT_WIDTH-1:0]	pktI2S_i,      // 16-bit audio packet to write
    input  logic        			pktValidI2S_i, // Write Enable strobe @ ~44.1kHz

    // --- Read Domain (Fast) Interface ---
    output logic [PKT_WIDTH-1:0]	pktDSP_reg_o,  		// Output data sample (FIFO output)
    output logic        			pktChangedDSP_comb_o 	// Changed strobe: '1' when new sample is different from old
);
	// Internal control signals
    logic fifoEmpty_comb;
    logic fifoFull_comb;
    logic [PKT_WIDTH-1:0] fifoPktOut_reg;
	logic [PKT_WIDTH-1:0] fifoPktOut_old_reg;

    // Write Control (Slow Domain)
    logic wrEN_comb;
    assign wrEN_comb = pktValidI2S_i && !fifoFull_comb;
	
    // Dual Clock FIFO IP Instantiation
    /*
     * IP Configuration:
	 * - Depth: 4
	 * - Width: 16
     * - Implementation: EBR
     * - Output Mode: First-Word Fall-Through (FWFT)
     * - Output register: enabled (1 cycle delay)
     */
    AsyncFIFO CDC_AFIFO_STF (
        .wr_clk_i   (clkI2SBit_i),
        .rd_clk_i   (clkDSP_i),
        .rst_i      (!rstDSP_n_i),
        .rp_rst_i   (1'd1), 	   // Never reset only the read port (MAY CAUSE BUG)
        .wr_en_i    (wrEN_comb),
        .rd_en_i    (1'd1), // TEMP (!fifoEmpty_comb)
        .wr_data_i  (pktI2S_i),
		
        .full_o     (fifoFull_comb),
        .empty_o    (fifoEmpty_comb), // NOT WORKING
        .rd_data_o  (fifoPktOut_reg)
    );
	
	always_ff @( posedge clkDSP_i ) begin
		if 	(~rstDSP_n_i) 	fifoPktOut_old_reg <= '0;
		else				fifoPktOut_old_reg <= fifoPktOut_reg;
	end

    // Output Assignments
    assign pktDSP_reg_o  = fifoPktOut_reg;
    assign pktChangedDSP_comb_o = fifoPktOut_old_reg ^ fifoPktOut_reg; // If packet is new, strobe pktChangedDSP_comb_o
	//TODO^ this generated a warning that the 16 bit xor is being crushed to a 1 bit signal

endmodule