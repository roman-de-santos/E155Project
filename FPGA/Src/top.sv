module top(
    input  logic sclk_in,
    input  logic rst,
    input  logic ws_in,
    input  logic sdata_in,
    output logic sclk_out,
    output logic ws_out,
    output logic sdata_out
           );

// Internal Logic
parameter WIDTH = 16;
logic [WIDTH-1:0] left_chan, right_chan;

// Instantiate modules
I2Stx #(WIDTH) I2Stx0 (sclk_in, ~rst, ws_out, sdata_out, left_chan, right_chan);

logic [15:0] dsp_left_out, dsp_right_out;
logic        dsp_data_ready; // DSP must pulse this when calculation is done

// ... CDC from DSP to TX ...
logic [15:0] tx_left_in, tx_right_in;
logic        tx_load_en;

Data_Fast_to_Slow #(
    .WIDTH(16),
    .FAST_FREQ(100), 
    .SLOW_FREQ(12)   // Adjust to match your sclk freq
) CDC_Left (
    .Clk_Fast(clk_100mhz),
    .Clk_Slow(sclk_in),     // Use the I2S SCLK
    .Rst(rst),
    .Data_In_Fast(dsp_left_out),
    .Valid_In_Fast(dsp_data_ready),
    .Data_Out_Slow(tx_left_in),
    .Valid_Out_Slow(tx_load_en) 
);

// Reuse the valid signal for Right channel if they update together
Data_Fast_to_Slow #(
    .WIDTH(16),
    .FAST_FREQ(100), 
    .SLOW_FREQ(12)
) CDC_Right (
    .Clk_Fast(clk_100mhz),
    .Clk_Slow(sclk_in),
    .Rst(rst),
    .Data_In_Fast(dsp_right_out),
    .Valid_In_Fast(dsp_data_ready),
    .Data_Out_Slow(tx_right_in),
    .Valid_Out_Slow() // Ignore duplicate valid
);


I2Srx #(WIDTH) I2Srx0 (sclk_in, ~rst, ws_in, sdata_in, left_chan, right_chan);

assign sclk_out = sclk_in;

endmodule