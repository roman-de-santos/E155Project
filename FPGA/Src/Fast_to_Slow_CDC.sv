`timescale 1ns / 1ps

module Fast_to_Slow_CDC #(
    parameter int FAST_CLK_FREQ_MHZ = 100,
    parameter int SLOW_CLK_FREQ_MHZ = 12    // Example: I2S SCLK freq
)(
    input  logic Clk_Fast,       // 100 MHz System Clock
    input  logic Clk_Slow,       // Connect this to your I2S sclk
    input  logic Rst,            // System Reset
    input  logic Input_Signal,   // The fast signal (e.g., a "valid" flag)
    output logic Received_Sample // The signal synchronized to the slow clock
);

    // --- Calculation of Extension Ratio ---
    // We need to extend the pulse to be at least 1.5x the period of the slow clock
    // so the slow clock is guaranteed to sample it high at least once.
    localparam int RATIO = FAST_CLK_FREQ_MHZ / SLOW_CLK_FREQ_MHZ;
    localparam int EXTEND_LIMIT = RATIO + (RATIO / 2); 

    // --- Internal Signals ---
    logic fast_sample_prev;
    logic extend_active;
    int   extend_cntr;
    logic fast_sample_extended;
    
    // Synchronizers
    logic fast_sample_extended_meta;
    logic rst_sync_fast_meta, rst_sync_fast;
    logic rst_sync_slow_meta, rst_sync_slow;

    // -------------------------------------------------------------------------
    // 1. Reset Synchronization (Standard 2-FF Sync)
    // -------------------------------------------------------------------------
    always_ff @(posedge Clk_Fast) begin
        rst_sync_fast_meta <= Rst;
        rst_sync_fast      <= rst_sync_fast_meta;
    end
    
    always_ff @(posedge Clk_Slow) begin
        rst_sync_slow_meta <= Rst;
        rst_sync_slow      <= rst_sync_slow_meta;
    end

    // -------------------------------------------------------------------------
    // 2. Signal Extension (Fast Domain)
    // -------------------------------------------------------------------------
    // This logic detects a rising edge on input and holds the output high
    // long enough for the slow clock to capture it.
    always_ff @(posedge Clk_Fast) begin
        if (rst_sync_fast) begin
            fast_sample_prev     <= 1'b0;
            extend_active        <= 1'b0;
            extend_cntr          <= 0;
            fast_sample_extended <= 1'b0;
        end else begin
            fast_sample_prev <= Input_Signal;

            // Detect Rising Edge of Input
            if (!fast_sample_prev && Input_Signal && !extend_active) begin
                extend_active <= 1'b1;
                extend_cntr   <= 0;
            end

            // Extend Logic
            if (extend_active) begin
                if (extend_cntr < EXTEND_LIMIT) begin
                    fast_sample_extended <= 1'b1;
                    extend_cntr          <= extend_cntr + 1;
                end else begin
                    fast_sample_extended <= 1'b0;
                    extend_active        <= 1'b0; // Ready for next pulse
                end
            end else begin
                fast_sample_extended <= 1'b0;
            end
        end
    end

    // -------------------------------------------------------------------------
    // 3. Output Synchronization (Slow Domain)
    // -------------------------------------------------------------------------
    always_ff @(posedge Clk_Slow) begin
        if (rst_sync_slow) begin
            fast_sample_extended_meta <= 1'b0;
            Received_Sample           <= 1'b0;
        end else begin
            fast_sample_extended_meta <= fast_sample_extended;
            Received_Sample           <= fast_sample_extended_meta;
        end
    end

endmodule