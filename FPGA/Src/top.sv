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
logic [WIDTH-1:0] left_tx_chan, right_tx_chan;
logic [WIDTH-1:0] left_rx_chan, right_rx_chan;

// Instantiate modules
I2Stx #(WIDTH) I2Stx0 (sclk_in, rst, ws_out, sdata_out, left_tx_chan, right_tx_chan);
I2Srx #(WIDTH) I2Srx0 (sclk_in, rst, ws_in, sdata_in, left_rx_chan, right_rx_chan);

assign sclk_out = sclk_in;

endmodule