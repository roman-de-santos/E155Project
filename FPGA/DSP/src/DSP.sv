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

		// --- STF CDC FIFO ---
		CDC_FIFO #(
			parameter PKT_WIDTH = 16 // Must be 16 for chorus pedal design
		) 
		STF_CDC_FIFO
		(
			// --- Clock & Global Reset Inputs ---
			.clkI2S  (clkRead_i),    		// For STF: slow clock (1.4122 MHz), for FTS: fast clock (6 MHz)
			.clkDSP_n (clkWrite_i),        // For STF: fast clock (6 MHz), for FTS: slow clock (1.4122 MHz)
			(rstWrite_n_i),      // Active low reset from write side

			// --- Write Domain (Slow) Interface ---
			(pkt_i),      	// 16-bit audio packet to write
			(pktChanged_i), 	// Write Enable strobe (@ ~44.1kHz)
			(rdEN_i),			// Read pktOut_s_o Enable Strobe (For STF: 1'b1, for FTS: @ ~44.1kHz)

			// --- Read Domain (Fast) Interface ---
			(pktOut_s_o),  		// FIFO output
			(pktOutChanged_c_o) 	// Strobe: '1' when new sample is different from old
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
		

		// --- FTS CDC FIFO ---
		CDC_FIFO #(
			parameter PKT_WIDTH = 16 // Must be 16 for chorus pedal design
		) 
		FTS_CDC_FIFO
		(
			// --- Clock & Global Reset Inputs ---
			.clkDSP_n  (clkRead_i),    		// For STF: slow clock (1.4122 MHz), for FTS: fast clock (6 MHz)
			.clkI2S (clkWrite_i),        // For STF: fast clock (6 MHz), for FTS: slow clock (1.4122 MHz)
			(rstWrite_n_i),      // Active low reset from write side

			// --- Write Domain (Slow) Interface ---
			(pkt_i),      	// 16-bit audio packet to write
			(pktChanged_i), 	// Write Enable strobe (@ ~44.1kHz)
			(rdEN_i),			// Read pktOut_s_o Enable Strobe (For STF: 1'b1, for FTS: @ ~44.1kHz)

			// --- Read Domain (Fast) Interface ---
			(pktOut_s_o),  		// FIFO output
			(pktOutChanged_c_o) 	// Strobe: '1' when new sample is different from old
		);
		
	endmodule