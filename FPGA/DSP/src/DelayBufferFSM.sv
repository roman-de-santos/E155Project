	// Lucas Lemos
	// 11/24/2025
	// llemos@hmc.edu

/*
	 * Module: DelayBufferFSM
	 *
	 * Description:
	 * Implements a configurable-depth **circular delay buffer (FIFO)** using an iCE40
	 * SPRAM primitive, operating under a **Finite State Machine (FSM)** control.
	 * It provides a variable delay path for input data packets (`pkt_s_i`),
	 * designed for audio DSP applications like chorus or flanger effects.
	 *
	 * The total delay is calculated as the sum of a fixed average delay (`AVG_DELAY`)
	 * and a variable offset (`extraDelay_s_i`) provided by an external source (e.g., an LFO).
	 *
	 * The module utilizes the iCE40 SPRAM primitive, which dictates a fixed packet
	 * size (`PKT_WIDTH`=16) and a maximum physical depth (`MAX_DEPTH`=16,000 samples).
	 *
	 * Ports operate under the system clock (`clk`). The FSM ensures proper
	 * **read-after-write** control and address management to avoid data corruption.
	 *
	 * Parameters:
	 * BUF_DEPTH - Configured size of the circular buffer in samples (must be <= MAX_DEPTH).
	 * AVG_DELAY - The fixed, average delay component in samples. Must be < BUF_DEPTH.
	 * PKT_WIDTH - Fixed data width of the packet (must be 16).
	 * ADDR_WIDTH- Fixed address width for the SPRAM primitive (must be 14).
	 *
	 * Ports:
	 * rst_nÃ‚Â  Ã‚Â 					- Active-low synchronous reset.
	 * clk						- System clock (CLK_DSP).
	 * pkt_s_iÃ‚Â  				- Input data packet to be written.
	 * pktChanged_s_i Ã‚Â   Ã‚Â 	- Strobe: '1' for one cycle when `pkt_s_i` is valid data to be written.
	 * extraDelay_s_i			- Signed, variable delay offset in samples (from LFO).
	 * pktDelayed_s_o 		- Delayed data packet output (registered/latched).
	 * pktDelayedChanged_c_o	- Strobe: '1' for one cycle indicating a new valid output sample is ready.
	 * errorLED_s_o			- Latched error indicator for state machine failure or invalid transition.
	 *
	 * Naming Conventions:
	 * _n: Active low
	 * _i: Input
	 * _o: Output
	 * _s: Sequential signal
	 * _c: Combinational signal
	 */
	module DelayBufferFSM #(
		parameter 					BUF_DEPTH   = 4410, // At Fs = 44.1kHz, up to 100 ms delay
		parameter  					AVG_DELAY   = 882,	// At Fs = 44.1kHz, average 20 ms delay
		parameter					PKT_WIDTH   = 16,	// fixed for SPRAM primitive
		parameter					ADDR_WIDTH = 14		// fixed for SPRAM primitive
	) (
		input logic                   			rst_n,
		input logic                   			clk,
		input logic 		[PKT_WIDTH-1:0] 	pkt_s_i,
		input logic                   			pktChanged_s_i,
		input logic  signed [ADDR_WIDTH-1:0]		extraDelay_s_i,
		input logic								LFOChanged_s_i,
		
		output logic [PKT_WIDTH-1:0]   	pktDelayed_s_o,
		output logic                   	pktDelayedChanged_c_o,
		output logic				  	errorLED_s_o
	);
		
		localparam					MAX_DEPTH = 16000;			// fixed for SPRAM primitive
		localparam [ADDR_WIDTH-1:0] MAX_DELAY = BUF_DEPTH - 3; 	// choice of 3 was arbitrary

		// Registered internal signals
		logic [ADDR_WIDTH-1:0] 	writeAddr_s;
		logic					LFOValid_s;
		
		// Combinational internal signals
		logic 					spramWE_c;
		logic [PKT_WIDTH-1:0]	spramDI_c;
		logic [ADDR_WIDTH-1:0]	spramAD_c;
		logic [PKT_WIDTH-1:0]	spramDO_c;
		logic [ADDR_WIDTH-1:0] 	readAddr_c;
		
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
		
		// State logic
		typedef enum logic [2:0]
			{RESET, IDLE, WRITE, WAIT, READ, OUTPUT, ERROR}
			statetype;
		statetype state, next_state;
		
		// State register
		always_ff @(posedge clk) begin
			if ( ~rst_n ) state <= RESET;
			else 		  state <= next_state;
		end
		
		// Instantiate the iCE40 UltraPlus SPRAM primitive
		SP256K buffer (
			.CK(clk),

			// Write Port
			.WE(spramWE_c),		//WREN
			.AD(spramAD_c), 	//ADDRESS[13:0]
			.DI(spramDI_c),			//DATAIN[15:0]

			// Read Port (Shares Address and Clock w/ Write Port)
			.DO(spramDO_c),		//DATAOUT[15:0]

			// Unused control signals
			.MASKWE(4'b1111),		//MASKWREN[3:0]
			.CS(1'b1),  			//CHIPSELECT
			.STDBY(1'b0),			//STANDBY
			.SLEEP(1'b0),			//SLEEP
			.PWROFF_N(1'b1)			//POWEROFF
		);
		
		// Next state logic
		always_comb begin
			case ( state )
				RESET:	if (!rst_n) 			next_state = RESET;
						else					next_state = IDLE;
				// TODO: add a LOAD state here
				IDLE:	if (pktChanged_s_i) 	next_state = WRITE;
						else					next_state = state;
				WRITE:							next_state = WAIT;
				WAIT:	if (LFOValid_s)			next_state = READ;
						else					next_state = WAIT;
				READ:							next_state = OUTPUT;
				OUTPUT:	if (pktChanged_s_i) 		next_state = WRITE; // skip IDLE if next packet is ready
						else					next_state = IDLE;
				ERROR:	 						next_state = RESET; // NOTE: THIS TRANSITION MAY CAUSE A BUG
				default: 						next_state = ERROR;
			endcase
		end
		
		// LFO valid logic
		always_ff @(posedge clk) begin
			if 		(!rst_n)			LFOValid_s <= 1'b0;
			else if	(pktChanged_s_i)		LFOValid_s <= 1'b0;
			else if (LFOChanged_s_i)		LFOValid_s <= 1'b1;
			else						LFOValid_s <= LFOValid_s;
		end
		
		// SPRAM logic
		assign spramWE_c = ( state == WRITE );
		assign spramDI_c = pkt_s_i;
		assign spramAD_c = ( state == WRITE ) ? writeAddr_s : readAddr_c;
		//assign spramDO_c =  // assigned via the SPRAM primitive
		
		// Read address logic (w/ clamping and wrap-around)
		always_comb begin
			// Delay calculation local variables
			logic  signed 	[ADDR_WIDTH:0]		delaySum; // delaySum is 1 bit wider to prevent addition overflow
			logic 			[ADDR_WIDTH-1:0] 	totalDelay;
			
			// Max and min delay clamping
			delaySum = (ADDR_WIDTH+1)'(AVG_DELAY) + (ADDR_WIDTH+1)'(extraDelay_s_i);
			if 		(delaySum < 0) 						totalDelay = '0;
			else if (delaySum > $signed(MAX_DELAY)) 	totalDelay = (ADDR_WIDTH'(MAX_DELAY));
			else										totalDelay = $unsigned(ADDR_WIDTH'(delaySum));

			// Calculate read address w/ wrap-around logic.
			if (writeAddr_s >= totalDelay) begin
				readAddr_c = writeAddr_s - totalDelay;
			end else begin 	// Handle wrap-around (underflow)
				readAddr_c = ADDR_WIDTH'(BUF_DEPTH) + writeAddr_s - totalDelay;
			end
		end
		
		// Write address logic
		always_ff @( posedge clk ) begin
			if 		(state == OUTPUT) 	begin
					// Wrap around logic
					if 	(writeAddr_s == (BUF_DEPTH - 1'b1)) 	writeAddr_s <= '0;
					else										writeAddr_s <= writeAddr_s + 1'b1;
			end
			else if (state == RESET) 	writeAddr_s <= '0;
			else 				  		writeAddr_s <= writeAddr_s;
		end
		
		
		// Output (READ & RESET) logic
		// The output packet is latching
		always_ff @( posedge clk ) begin
			case ( state )
				RESET:		pktDelayed_s_o <= '0;
				READ:		pktDelayed_s_o <= spramDO_c;
				default:	pktDelayed_s_o <= pktDelayed_s_o;
			endcase
			case ( state )
				RESET:		errorLED_s_o <= 1'b0;
				ERROR:		errorLED_s_o <= 1'b1;
				default:	errorLED_s_o <= errorLED_s_o;
			endcase
		end
		assign pktDelayedChanged_c_o = (state == OUTPUT); // Goes high 1 cycle after READ
	endmodule