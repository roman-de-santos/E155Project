`timescale 1ns / 1ps

module LFOgen_tb;

    // --- Parameters ---
    parameter CLK_PERIOD = 166.666; // 6MHz clock period (~166.667ns)
    parameter HALF_PERIOD = CLK_PERIOD / 2.0;

    // The module is set to tick every 136 cycles for 44.1kHz
    parameter CYCLES_PER_TICK = 136; 
    parameter TICK_PERIOD_NS = CLK_PERIOD * CYCLES_PER_TICK; // ~22.675 us

    // --- Signals for DUT interface ---
    logic clk;
    logic reset;
    logic [3:0] freqSetting;
    logic [3:0] scaleFactor;
    logic signed [15:0] waveOut;
	logic newValFlag;
	logic FIFOupdate;

    // --- Internal signals for monitoring ---
    logic [31:0]  phaseAcc_mon;
    logic [31:0]  tuningVal_mon;

    // --- Instantiate the Device Under Test (DUT) ---
    LFOgen DUT (
        .clk_i(clk),
        .rst_n_i(reset),
        .freqSetting_i(freqSetting),
        .scaleFactor_i (scaleFactor),
		.FIFOupdate_i(FIFOupdate),
        .wave_o (waveOut),
		.newValFlag_o (newValFlag)		
    );

    // Grab internal signals for verification
    assign phaseAcc_mon  = DUT.phaseAcc;
    assign tuningVal_mon = DUT.tuningVal;
    
    // --- Clock Generation ---
    initial begin
        clk = 1'b0;
        forever #(HALF_PERIOD) clk = ~clk;
    end

    // --- Strobe Generation ---
    initial begin
        FIFOupdate = 1'b0;
		
        
        // Optional: Align start with the main clock to avoid race conditions
        @(posedge clk); 

        forever begin
            // 1. Drive High
            FIFOupdate = 1'b1;
            
            // 2. Wait exactly 1 Clock Period
            #(CLK_PERIOD);
            
            // 3. Drive Low
            FIFOupdate = 1'b0;
            
            // 4. Wait for the remainder of the 44.1kHz period
            // (136 total cycles - 1 cycle used for high pulse = 135 cycles wait)
            #(CLK_PERIOD * (CYCLES_PER_TICK - 1));
        end
    end

    // --- Main Test Stimulus ---
    initial begin
        $display("---------------------------------------------------------");
        $display("Starting LFOgen Testbench (6MHz System Clock)");
        $display("48kHz Sample Period: %0fns (~%0.3fus)", TICK_PERIOD_NS, TICK_PERIOD_NS / 1000.0);
        $display("---------------------------------------------------------");
        $display("NOTE: Ensure 'sineFixed(256).mem' is in a subdirectory named 'LFO-LUTs'");
        $display("relative to the directory where the simulation is being executed.");
        $display("---------------------------------------------------------");
        
        // 1. Initial Reset Phase
        reset = 1'b0;
        freqSetting = 4'b0000;
        scaleFactor = 4'b0000;
        # (CLK_PERIOD * 5); 

        $display("[%0t] Reset held high. phaseAcc: 0x%h, waveOut: %d", $time, phaseAcc_mon, waveOut);
        
        // 2. Release Reset
        reset = 1'b1;
		DUT.phaseAcc = 32'h80000000; //start at -108 ish
        # (CLK_PERIOD); 
        
        // 3. Sync to 48kHz tick
        @(posedge FIFOupdate); 
        $display("[%0t] First FIFOupdate Tick detected!", $time);
        
        // 4. Test Case 1: 1.0 Hz (Too slow to see change in short sim, but we check accum)
        #1; 
        freqSetting = 4'b0011; // 1.0 Hz
        scaleFactor = 4'b1111; // Max scale
        
        $display("[%0t] Case 1: Freq=1.0Hz. Running 10 samples to check Accumulator logic...", $time);

        for (int i = 0; i < 10; i++) begin
            @(posedge FIFOupdate);
            // We expect waveOut to be 0 here because phaseAcc hasn't reached Index 1 yet
        end
        $display("[%0t] Case 1 PhaseAcc check: 0x%h (Should be increasing)", $time, phaseAcc_mon);
        
        // 5. Test Case 2: 4.0 Hz - Run longer to see transition!
        // At 4Hz, it takes ~47 samples to increment the LUT index
        @(posedge clk);
        freqSetting = 4'b1101; // 4.0 Hz
        scaleFactor = 4'b1111; // Max scale (Easier to see than half scale)
        #1; 
        
        $display("[%0t] Case 2: Freq=4.0Hz. Running 120 samples to wait for LUT Index change twice...", $time);
        $display("        (Transition from Index 0 -> 1 expected around Sample 47)");

        for (int i = 0; i < 120; i++) begin
            @(posedge FIFOupdate);
            // Only print if waveOut changes or periodically
            if (waveOut != 0 || i > 40) begin
                 $display("[%0t] Sample %0d: phaseAcc=0x%h (Idx: %0d), waveOut=%d", 
                     $time, i+1, phaseAcc_mon, phaseAcc_mon[31:24], $signed(waveOut));
            end
        end
		
		$display("Test another scale Factor");
		scaleFactor = 4'b1000; 
		
		for (int i = 0; i < 60; i++) begin
            @(posedge FIFOupdate);
            // Only print if waveOut changes or periodically
            if (waveOut != 0 || i > 40) begin
                 $display("[%0t] Sample %0d: phaseAcc=0x%h (Idx: %0d), waveOut=%d", 
                     $time, i+1, phaseAcc_mon, phaseAcc_mon[31:24], $signed(waveOut));
            end
        end

        $display("[%0t] Test complete.", $time);
        $stop;
    end

endmodule