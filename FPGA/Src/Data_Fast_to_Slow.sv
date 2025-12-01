`timescale 1ns / 1ps

module Data_Fast_to_Slow #(
    parameter int WIDTH = 16,
    parameter int FAST_FREQ = 100,
    parameter int SLOW_FREQ = 12
)(
    input  logic             Clk_Fast,
    input  logic             Clk_Slow,
    input  logic             Rst,
    
    // Fast Domain Inputs
    input  logic [WIDTH-1:0] Data_In_Fast,
    input  logic             Valid_In_Fast,
    
    // Slow Domain Outputs
    output logic [WIDTH-1:0] Data_Out_Slow,
    output logic             Valid_Out_Slow
);

    // --- 1. Pulse Extender Logic (Fast Domain) ---
    // We extend the pulse so the slow clock doesn't miss it.
    localparam int RATIO = FAST_FREQ / SLOW_FREQ;
    localparam int EXTEND_LIMIT = RATIO + (RATIO / 2); // 1.5x width

    logic extend_active;
    int   extend_cntr;
    logic valid_extended;

    // --- 2. Data Holding Register (The Fix) ---
    // We latch the data IMMEDIATELY when the DSP says it's ready.
    // This holds the data stable while the flags are synchronizing.
    logic [WIDTH-1:0] data_latched;

    always_ff @(posedge Clk_Fast or posedge Rst) begin
        if (Rst) begin
            extend_active  <= 0;
            extend_cntr    <= 0;
            valid_extended <= 0;
            data_latched   <= 0;
        end else begin
            // Latch data and Start Pulse
            if (Valid_In_Fast && !extend_active) begin
                extend_active  <= 1;
                extend_cntr    <= 0;
                valid_extended <= 1;
                data_latched   <= Data_In_Fast; // <--- CAPTURE DATA HERE
            end 
            // Extend the pulse
            else if (extend_active) begin
                if (extend_cntr < EXTEND_LIMIT) begin
                    extend_cntr    <= extend_cntr + 1;
                    valid_extended <= 1;
                end else begin
                    extend_active  <= 0;
                    valid_extended <= 0;
                end
            end 
            // Idle
            else begin
                valid_extended <= 0;
            end
        end
    end

    // --- 3. Output Synchronization (Slow Domain) ---
    logic valid_meta, valid_sync;
    logic valid_sync_prev;
    
    always_ff @(posedge Clk_Slow or posedge Rst) begin
        if (Rst) begin
            valid_meta      <= 0;
            valid_sync      <= 0;
            valid_sync_prev <= 0;
            Data_Out_Slow   <= 0;
            Valid_Out_Slow  <= 0;
        end else begin
            // Double-Flop Synchronizer for the Flag
            valid_meta <= valid_extended;
            valid_sync <= valid_meta;
            
            // Edge Detection
            valid_sync_prev <= valid_sync;
            
            // Rising Edge = Safe to sample data
            if (valid_sync && !valid_sync_prev) begin
                Valid_Out_Slow <= 1'b1;
                Data_Out_Slow  <= data_latched; // <--- Sample the STABLE latched data
            end else begin
                Valid_Out_Slow <= 1'b0;
            end
        end
    end

endmodule