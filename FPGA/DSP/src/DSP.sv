	// Lucas Lemos
	// 11/25/2025
	// llemos@hmc.edu
	
	/*
	 * Module: DSP
	 *
	 * Description:
	 * Top-level module for the Classic Chorus Effect DSP chain.
	 * It connects the CDCs, the Delay Buffer FSM, a Low-Frequency
	 * Oscillator (LFO) for variable delay, and a final Mixer stage.
	 *
	 * This module implements the following chain:
	 * (I2S RX Data) -> CDC In -> Delay Buffer & LFO -> Mixer -> CDC Out -> (I2S TX Data)
	 *
	 */
	module DSP #(
		parameter PKT_WIDTH = 16
	) (
		input logic                 	rst_n,   	// Active-low asynchronous reset
		input logic                 	clkI2S,  	// Asynchronous 1.4112 MHz I2S clock from MCU
		input logic						rstI2S_n;	// The same reset but synchronized to the I2S clock

		// Data from I2S RX Async FIFO
		input logic [PKT_WIDTH-1:0] i2sRxPkt_i,        // Dry input audio sample
		input logic                 i2sRxPktValid_i,   // Strobe: New valid sample from RX FIFO

		// Data to I2S TX Async FIFO
		output logic [PKT_WIDTH-1:0] i2sTxPkt_o,       // Mixed wet/dry audio sample
		output logic                 i2sTxPktValid_o,  // Strobe: New valid sample to TX FIFO
		
		// Status/Error Outputs (optional)
		output logic                 errorLED_o         // Delay Buffer FSM error
	);
		// Internal DSP logic
		logic clkDSP;	// DSP System Clock (6 MHz)
		logic pktDry;
		logic pktDryChanged;
		logic pktWet;
		logic pktWetChanged;
		logic delayLFO;
		logic rstDSP_n;
		
		// Reset synchronizer to clkDSP
		synchronizer rstDSP_sync(
			.clk	( clkDSP );
			.rst_n	(1'd1); // never resets
			.d_a	( rst_n );
			.q		( rstDSP_n );
		);
		
		// Generate clkDSP by instantiating high speed oscillator module from iCE40 library
		HSOSC #(.CLKHF_DIV( 2'b11 )) hf_osc(  // dividing HSOSC clock by 8 (clkDSP = 6 MHz)
			.CLKHFPU ( 1'b1 ), // input
			.CLKHFEN ( 1'b1 ), // input
			.CLKHF   ( clkDSP )     // output
		);
		
		// --- Circular Delay Buffer FSM ---
		/*  */		
		DelayBufferFSM #(
			.BUF_DEPTH      (4410), 		// Default (100 ms)
			.AVG_DELAY      (882),		// Default (20 ms)
			.PKT_WIDTH      (PKT_WIDTH), // Should be 16
		) u_delay_buffer (
			.rst_n                  (rst_n),
			.clk                    (clkDSP),
			.pkt_reg_i              (pktDry),              // Data In (Dry Signal)
			.pktChanged_reg_i       (pktDryChanged),        // Write Strobe
			.extraDelay_reg_i       (delayLFO),     // Variable Delay Offset
			.pktDelayed_reg_o       (pktWet),              // Data Out (Wet/Delayed Signal)
			.pktDelayedChanged_comb_o(pktWetChanged),       // Read Strobe (Wet Valid)
			.errorLED_reg_o         (errorLED_o)            // Error Output
		);
		
		
	endmodule