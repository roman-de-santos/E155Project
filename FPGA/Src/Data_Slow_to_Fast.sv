`timescale 1ns / 1ps

module Data_Slow_to_Fast #(
    parameter int WIDTH = 16
)(
    input  logic             Clk_Fast,      // 6 MHz System Clock
    input  logic             Rst,
    
    // Slow Domain Inputs (From I2S Rx)
    input  logic [WIDTH-1:0] Data_In_Slow,  
    input  logic             Valid_In_Slow, // Pulse/Flag created from WS edge
    
    // Fast Domain Outputs (To DSP)
    output logic [WIDTH-1:0] Data_Out_Fast, 
    output logic             Valid_Out_Fast // 1-cycle pulse in Fast Domain
);

    logic valid_meta, valid_sync;
    logic valid_prev;

    // Standard 2-Stage Synchronizer
    always_ff @(posedge Clk_Fast) begin
        if (Rst) begin
            valid_meta     <= 0;
            valid_sync     <= 0;
            valid_prev     <= 0;
            Data_Out_Fast  <= 0;
            Valid_Out_Fast <= 0;
        end else begin
            // 1. Synchronize the Slow "Valid" signal into Fast Domain
            valid_meta <= Valid_In_Slow;
            valid_sync <= valid_meta;
            
            // 2. Edge Detection
            // The slow signal stays high for a long time (relative to 6MHz).
            // We only want to trigger once when it rises.
            valid_prev <= valid_sync;
            
            if (valid_sync && !valid_prev) begin
                // Rising Edge found -> Capture Data
                Valid_Out_Fast <= 1'b1;
                Data_Out_Fast  <= Data_In_Slow; // Safe to sample now
            end else begin
                Valid_Out_Fast <= 1'b0;
            end
        end
    end

endmodule