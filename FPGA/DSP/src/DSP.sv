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

		// Data from I2S RX Async FIFO
		input logic [PKT_WIDTH-1:0] i2sRxPkt_i,        // Dry input audio sample
		input logic                 pktI2SRxChanged_i,   // Strobe: New valid sample from RX FIFO

		// User settings for LFO
		input logic [3:0]           freqSetting_i,
		input logic [3:0]           scaleFactor_i,
		//TODO: add a MIX setting for the mixer module

		// Data to I2S TX Async FIFO
		output logic [PKT_WIDTH-1:0] i2sTxPkt_o,       // Mixed wet/dry audio sample
		output logic                 i2sTxPktChanged_o,  // Strobe: New valid sample to TX FIFO
		
		output logic				rstI2S_n_o,	// The DSP reset synchronized to the I2S clock
		
		// Status/Error Outputs (optional)
		output logic                 errorLED_o         // Delay Buffer FSM error
	);
		// Internal DSP logic
		logic 					clkDSP;	// DSP System Clock (6 MHz)
		logic [PKT_WIDTH-1:0]	pktDry;
		logic 				  	pktDryChanged;// the same as pktI2SRxChanged_i??
		logic [PKT_WIDTH-1:0] 	pktWet;
		logic 				  	pktWetChanged;
		logic [PKT_WIDTH-1:0] 	delayLFO;
		logic [PKT_WIDTH-1:0] 	pktMixed;
		logic                 	LFOChanged;
		logic                 	pktMixedChanged;
		
		// Reset synchronizer to clkDSP
		synchronizer u_RstI2Ssync(
			.clk	( clkDSP ),
			.rst_n	( 1'd1 ), // never resets
			.d_a	( ~rst_n ),
			.q		( rstI2S_n_o )
		);
		
		// Generate clkDSP by instantiating high speed oscillator module from iCE40 library
		HSOSC #(
			.CLKHF_DIV( 2'b11 )
		) u_hf_osc (  // dividing HSOSC clock by 8 (clkDSP = 6 MHz)
			.CLKHFPU ( 1'b1 ), // input
			.CLKHFEN ( 1'b1 ), // input
			.CLKHF   ( clkDSP )     // output
		);

		// --- STF CDC FIFO ---
		CDC_FIFO #(
			.PKT_WIDTH( PKT_WIDTH ) // Must be 16 for chorus pedal design
		) u_STF_CDC_FIFO (
			// --- Clock & Global Reset Inputs ---
			.clkRead_i         (clkI2S), 	// For STF: slow clock (1.4122 MHz), for FTS: fast clock (6 MHz)
			.clkWrite_i        (clkDSP),   // For STF: fast clock (6 MHz), for FTS: slow clock (1.4122 MHz)
			.rstWrite_n_i      (~rst_n),		// Active low reset from write side (syncronize???)

			// --- Write Domain (Slow) Interface ---
			.pkt_i             (i2sRxPkt_i),      	// 16-bit audio packet to write
			.pktChanged_i      (pktI2SRxChanged_i), 	// Write Enable strobe (@ ~44.1kHz)
			.rdEN_i            (1'b1),		// Read pktOut_s_o Enable Strobe (For STF: 1'b1, for FTS: @ ~44.1kHz)

			// --- Read Domain (Fast) Interface ---
			.pktOut_s_o        (pktDry),  		// FIFO output
			.pktOutChanged_c_o (pktDryChanged) 	// Strobe: '1' when new sample is different from old
		);

		LFOgen u_DelayLFO(
			.clk_i         (clkDSP),
			.reset_i       (~rst_n),
			.freqSetting_i (freqSetting_i), 
			.scaleFactor_i (scaleFactor_i),      
			.FIFOupdate_i  (pktI2SRxChanged_i),
			.wave_o        (delayLFO),
			.newValFlag_o  (LFOChanged)
		);

		
		// --- Circular Delay Buffer FSM ---
		/*  */		
		DelayBufferFSM #(
			.BUF_DEPTH      (4410), 		// Default (100 ms)
			.AVG_DELAY      (882),		// Default (20 ms)
			.PKT_WIDTH      (PKT_WIDTH) // Should be 16
		) u_DelayBuffer (
			.rst_n                    (~rst_n),
			.clk                      (clkDSP),
			.pkt_s_i                (pktDry),              // Data In (Dry Signal)
			.pktChanged_s_i         (pktDryChanged),        // Write Strobe
			.extraDelay_s_i         (delayLFO),           // Variable Delay Offset
			.LFOChanged_s_i			(LFOChanged),		// New LFO value strobe
			.pktDelayed_s_o         (pktWet),              // Data Out (Wet/Delayed Signal)
			.pktDelayedChanged_c_o (pktWetChanged),       // Read Strobe (Wet Valid)
			.errorLED_s_o           (errorLED_o)            // Error Output
		);

		Mixer #(
			.WIDTH(PKT_WIDTH)
		) u_Mixer (
			.clk_i       		(clkDSP), 
			.rst_n_i     		(~rst_n),
		    .pktWet_i    		(pktWet),
            .pktDry_i    		(pktDry),
			.pktWetChanged_i		(pktWetChanged),
			.pktMixed_o  		(pktMixed),
			.pktMixedChanged_o 	(pktMixedChanged)
		);
		

		// --- FTS CDC FIFO ---
		CDC_FIFO #(
			.PKT_WIDTH(PKT_WIDTH) // Must be 16 for chorus pedal design
		) u_FTS_CDC_FIFO (
			// --- Clock & Global Reset Inputs ---
			.clkRead_i         (clkDSP),    		// For STF: slow clock (1.4122 MHz), for FTS: fast clock (6 MHz)
			.clkWrite_i        (clkI2S),        // For STF: fast clock (6 MHz), for FTS: slow clock (1.4122 MHz)
			.rstWrite_n_i      (~rst_n),      // Active low reset from write side

			// --- Write Domain (Slow) Interface ---
			.pkt_i             (pktMixed),      	// 16-bit audio packet to write
			.pktChanged_i      (pktMixedChanged), 	// Write Enable strobe (@ ~44.1kHz)
			.rdEN_i            (1'b1),			        // Read pktOut_s_o Enable Strobe (For STF: 1'b1, for FTS: @ ~44.1kHz)

			// --- Read Domain (Fast) Interface ---
			.pktOut_s_o        (i2sTxPkt_o),  		// FIFO output
			.pktOutChanged_c_o (i2sTxPktChanged_o) 	// Strobe: '1' when new sample is different from old
		);
		
	endmodule