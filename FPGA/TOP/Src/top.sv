module top(
    input  logic sclk_i,
    input  logic rst_n_i,
    input  logic ws_i,
    input  logic sdata_i,
    output logic sclk_o,
    output logic ws_o,
    output logic sdata_o
           );

// Internal Logic
parameter WIDTH = 16;
logic [WIDTH-1:0] leftChan_o, rightChan_o, leftChan_i, rightChan_i;

// Instantiate modules

I2Srx #(WIDTH) I2Srx0 (sclk_i, ~rst_n_i, ws_i, sdata_i, leftChan_o, rightChan_0);

DSP DSP1 ();

I2Stx #(WIDTH) I2Stx0 (sclk_i, ~rst_n_i, ws_o, sdata_o, leftChan_i, rightChan_i);
assign sclk_o = sclk_i;

endmodule