module top_I2S(
    input  logic sclk_in,
    input  logic rst,
    input  logic ws_in,
    input  logic sdata_in,
    output logic sclk_out,
    output logic ws_out,
    output logic sdata_out,
	output logic pktI2SRxChanged_o
           );

// Internal Logic
parameter WIDTH = 16;
logic [WIDTH-1:0] left_chan, right_chan;

// Instantiate modules
I2Stx #(WIDTH) I2Stx0 (sclk_in, ~rst, ws_out, sdata_out, left_chan, right_chan);
I2Srx #(WIDTH) I2Srx0 (sclk_in, ~rst, ws_in, sdata_in, left_chan, right_chan, pktI2SRxChanged_o);

assign sclk_out = sclk_in;

endmodule