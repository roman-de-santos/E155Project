`timescale 1ns / 1ps

module LFOgen_tb;

    // --- Parameters ---
    parameter CLK_PERIOD = 166.666; // 6MHz clock period (~166.667ns)
    parameter HALF_PERIOD = CLK_PERIOD / 2.0;

    // The module is set to tick every 125 cycles for 48kHz
    parameter CYCLES_PER_TICK = 125; 
    parameter TICK_PERIOD_NS = CLK_PERIOD * CYCLES_PER_TICK; // ~20.833 us

    // --- Signals for DUT interface ---
    logic clk;
    logic reset;
    logic [3:0] freqSetting;
    logic [3:0] scaleFactor;
    logic signed [15:0] waveOut;

    // --- Internal signals for monitoring ---
    logic         tick48k_mon;
    logic [31:0]  phaseAcc_mon;
    logic [31:0]  tuningVal_mon;

    // --- Instantiate the Device Under Test (DUT) ---
    LFOgen DUT (
        .clk(clk),
        .reset(reset),
        .freqSetting(freqSetting),
        .scaleFactor(scaleFactor),
        .waveOut(waveOut)
    );

    // Grab internal signals for verification (Requires simulator support for hierarchical access)
    assign tick48k_mon   = DUT.tick48k;
    assign phaseAcc_mon  = DUT.phaseAcc;
    assign tuningVal_mon = DUT.tuningVal;
    
    // --- Clock Generation ---
    initial begin
        clk = 1'b0;
        forever #(HALF_PERIOD) clk = ~clk;
    end

    // --- Main Test Stimulus ---
    initial begin
        $display("---------------------------------------------------------");
        $display("Starting LFOgen Testbench (6MHz System Clock)");
        $display("48kHz Sample Period: %0fns (~%0.3fus)", TICK_PERIOD_NS, TICK_PERIOD_NS / 1000.0);
        $display("---------------------------------------------------------");
        // IMPORTANT: The DUT uses $readmemh("./LFO-LUTs/sineFixed(256).mem", LUT);
        $display("NOTE: Ensure 'sineFixed(256).mem' is in a subdirectory named 'LFO-LUTs'");
        $display("relative to the directory where the simulation is being executed.");
        $display("---------------------------------------------------------");
        
        // 1. Initial Reset Phase
        reset = 1'b1;
        freqSetting = 4'b0000;
        scaleFactor = 4'b0000;
        # (CLK_PERIOD * 5); // Hold reset for 5 clocks

        $display("[%0t] Reset held high. phaseAcc: 0x%h, waveOut: %d", $time, phaseAcc_mon, waveOut);
        
        // 2. Release Reset and Initial Check
        reset = 1'b0;
        # (CLK_PERIOD); 

        $display("[%0t] Reset released. Waiting for first 48kHz tick...", $time);
        
        // 3. Test 48kHz Tick Timing (Wait for 125 cycles)
        @(posedge tick48k_mon); 
        $display("[%0t] First 48kHz Tick detected!", $time);
        
        // 4. Test Case 1: 1.0 Hz Frequency (4'b0011) and Full Scale (4'b1111)
        // Expected tuningVal for 4'b0011 is 89478 (0x0001_5d86)
        #1; // Wait for combinational logic to update
        freqSetting = 4'b0011;
        scaleFactor = 4'b1111;
        
        $display("[%0t] Case 1: Freq=1.0Hz (4'b0011, Tval=0x%h), Scale=Max (4'b1111)", $time, tuningVal_mon);

        // Wait for 10 samples (10 * 125 cycles)
        for (int i = 0; i < 10; i++) begin
            @(posedge tick48k_mon);
            $display("[%0t] Sample %0d: phaseAcc=0x%h, waveOut=%d", 
                     $time, i+1, phaseAcc_mon, $signed(waveOut));
            
            // Basic verification: Check that tuningVal is correct based on freqSetting:
            if (tuningVal_mon != 32'd89478) $error("Tuning Value Mismatch! Expected 89478, Got %d", tuningVal_mon);
        end
        
        // 5. Test Case 2: Change Frequency to 4.0 Hz (4'b1101) and Scale to Half (4'b1000)
        // Expected tuningVal for 4'b1101 is 357914 (0x0005_761a)
        @(posedge clk);
        freqSetting = 4'b1101;
        scaleFactor = 4'b1000;
        #1; // Wait for combinational logic to update
        
        $display("[%0t] Case 2: Freq=4.0Hz (4'b1101, Tval=0x%h), Scale=Half (4'b1000)", $time, tuningVal_mon);
        if (tuningVal_mon != 32'd357914) $error("Tuning Value Mismatch in Case 2! Expected 357914, Got %d", tuningVal_mon);

        // Wait for another 10 samples at the new settings
        for (int i = 0; i < 10; i++) begin
            @(posedge tick48k_mon);
            $display("[%0t] Sample %0d: phaseAcc=0x%h, waveOut=%d", 
                     $time, i+11, phaseAcc_mon, $signed(waveOut));
        end

        // 6. Test Case 3: Zero Scale
        @(posedge clk);
        scaleFactor = 4'b0000;
        #1; 
        $display("[%0t] Case 3: Scale Factor set to 0 (4'b0000). waveOut should be 0.", $time);
        
        @(posedge tick48k_mon);
        if (waveOut != 16'd0) $error("WaveOut Mismatch! Expected 0 with scaleFactor=0, Got %d", waveOut);
        $display("[%0t] Final Sample: waveOut=%d. Test complete.", $time, $signed(waveOut));

        $stop;
    end

endmodule