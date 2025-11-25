// Lucas Lemos
	// 11/6/2025
	// llemos@hmc.edu

	/*
	 * Module: DelayBuffer
	 *
	 * Description:
	 * Implements a circular delay buffer (FIFO) intended for audio DSP.
	 * It writes incoming valid packets (`pkt_i`) to a circular buffer and
	 * reads them out after a variable delay. The delay is composed of a
	 * fixed average delay (`AVG_DELAY`) and a variable extra delay
	 * (`extraDelay_reg_i`), which would be supplied by an LFO in a chorus
	 * effect.
	 * 
	 * This module uses the 256kbit iCE40 SPRAM primitive so it has a fixed
	 * packet size of 16 and a maximum depth of 16,000 x 16-bit samples.
	 * The default module is configured for a maximum delay of 100 ms and
	 * an average delay of 20 ms.
	 *
	 * Parameters:
	 * BUF_DEPTH   - Total number of samples in the buffer. Can be no larger
	 * than 16,000 samples.
	 * AVG_DELAY   - The fixed, average delay in samples. Must be less than BUF_DEPTH.
	 *
	 * Ports:
	 * rst_n         			- Active-low synchronous reset.
	 * clk           			- System clock (CLK_DSP).
	 * pkt_reg_i        			- Input data packet from the asynchronous FIFO.
	 * pktChanged_reg_i   		- '1' when `pkt_reg_i` contains valid data to be written.
	 * extraDelay_reg_i			- Additional variable delay (from LFO).
	 * pktDelayed_reg_o 			- Delayed data packet output.
	 * pktDelayedChanged_reg_o	- '1' when `pktDelayed_reg_o` is valid (1 cycle after `pktChanged_reg_i`).
	 */
	module DelayBuffer #(
		parameter 					BUF_DEPTH   = 4410, 	// At Fs = 44.1kHz, up to 100 ms delay
		parameter  					AVG_DELAY   = 882,	// At Fs = 44.1kHz, average 20 ms delay
		parameter					PKT_WIDTH   = 16	,	// fixed for SPRAM primitive
		parameter					ADDR_WIDTH = 14	// fixed for SPRAM primitive
	) (
		input logic                   			rst_n,
		input logic                   			clk,
		input logic 		[PKT_WIDTH-1:0] 	pkt_reg_i,
		input logic                   			pktChanged_reg_i,
		input logic signed 	[ADDR_WIDTH-1:0]	extraDelay_reg_i,
		
		output logic [PKT_WIDTH-1:0]   pktDelayed_reg_o,
		output logic                   pktDelayedChanged_reg_o
	);
		
		localparam					MAX_DEPTH = 16000;			// fixed for SPRAM primitive
		localparam [ADDR_WIDTH-1:0] 	MAX_DELAY = BUF_DEPTH - 3; 	// choice of 3 was arbitrary

		// Registered signals
		logic [ADDR_WIDTH-1:0] 	writeAddr_reg;
		logic [ADDR_WIDTH-1:0]	writeAddrOld_reg;
		logic					spramDOValid_reg;
		
		// Combinational internal signals
		logic [ADDR_WIDTH-1:0] 	writeAddrNxt_comb;
		logic [ADDR_WIDTH-1:0] 	readAddr_comb; //TODO: THIS MIGHT BE OFF BY ONE CLOCK EDGE
		logic [ADDR_WIDTH-1:0]	spramAddr_comb;
		logic [PKT_WIDTH-1:0]	spramDO_comb;

		
		// Compile-time validation
		generate
			if (BUF_DEPTH > MAX_DEPTH) begin
				$fatal(1, "ERROR: BUF_DEPTH (%0d) must be less than or equal to the SPRAM primitive depth (%0d).", BUF_DEPTH, MAX_DEPTH);
			end
			else if (AVG_DELAY > MAX_DELAY) begin
				$fatal(1, "ERROR: AVG_DELAY (%0d) must be less than or equal to the maximum delay (%0d).", AVG_DELAY, MAX_DELAY);
			end
			else if (PKT_WIDTH != 16) begin
				$fatal(1, "ERROR: PKT_WIDTH (%0d) must be 16 for the iCE40 SPRAM.", PKT_WIDTH);
			end
			else if (ADDR_WIDTH != 14) begin
				$fatal(1, "ERROR: ADDR_WIDTH (%0d) must be 14 for the iCE40 SPRAM.", ADDR_WIDTH);
			end
		endgenerate
		
		// Instantiate the iCE40 UltraPlus SPRAM primitive
		SP256K buffer (
			.CK(clk),

			// Write Port
			.WE(pktChanged_reg_i),		//WREN
			.AD(spramAddr_comb), 	//ADDRESS[13:0]
			.DI(pkt_reg_i),			//DATAIN[15:0]

			// Read Port (Shares Address and Clock w/ Write Port)
			.DO(spramDO_comb),		//DATAOUT[15:0]

			// Unused control signals
			.MASKWE(4'b1111),		//MASKWREN[3:0]
			.CS(1'b1),  			//CHIPSELECT
			.STDBY(1'b0),			//STANDBY
			.SLEEP(1'b0),			//SLEEP
			.PWROFF_N(1'b1)			//POWEROFF
		);

		// Calculate next write address (w/ wrap-around)
		always_comb begin
			if (writeAddr_reg == (BUF_DEPTH - 1'b1)) 	writeAddrNxt_comb = '0;
			else										writeAddrNxt_comb = writeAddr_reg + 1'b1;
		end
		
		// Calculate read address (w/ clamping and wrap-around)
		always_comb begin
			// Delay calculation local variables
			logic  signed 	[ADDR_WIDTH:0]		delaySum; // delaySum is 1 bit wider to prevent addition overflow
			logic 			[ADDR_WIDTH-1:0] 	totalDelay;
			
			// Max and min delay clamping
			delaySum = (ADDR_WIDTH+1)'(AVG_DELAY) + (ADDR_WIDTH+1)'(extraDelay_reg_i);
			if 		(delaySum < 0) 					totalDelay = '0;
			else if (delaySum > $signed(MAX_DELAY)) 	totalDelay = (ADDR_WIDTH'(MAX_DELAY));
			else									totalDelay = $unsigned(ADDR_WIDTH'(delaySum));

			// Calculate read address w/ wrap-around logic.
			if (writeAddr_reg >= totalDelay) begin
				readAddr_comb = writeAddrOld_reg - totalDelay;
			end else begin 	// Handle wrap-around (underflow)
				readAddr_comb = ADDR_WIDTH'(BUF_DEPTH) + writeAddr_reg - totalDelay; //BUG: I THINK writeAddr_reg SHOULD BE writeAddrOld_reg
			end
		end
		
		// Read address vs. write address mux
		assign spramAddr_comb = (pktChanged_reg_i ? writeAddr_reg : readAddr_comb);

		// Update registers
		always_ff @(posedge clk) begin
			if (!rst_n) begin
				pktDelayed_reg_o 		<= '0;
				pktDelayedChanged_reg_o 	<= 1'b0;
				writeAddr_reg    		<= '0;
				writeAddrOld_reg			<= '0;
				spramDOValid_reg			<= 1'b0;
				// Note: RAM contents are not explicitly reset. May cause a pop on startup.
			end else begin
				// Update internal registers
				spramDOValid_reg <= pktChanged_reg_i;
				if (pktChanged_reg_i) writeAddr_reg <= writeAddrNxt_comb;	
				writeAddrOld_reg <= writeAddr_reg;
					
				// Update output registers
				pktDelayedChanged_reg_o <= spramDOValid_reg;
				if (spramDOValid_reg) pktDelayed_reg_o <= spramDO_comb;
			end
		end
	endmodule