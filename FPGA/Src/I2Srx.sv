module I2S_rx #(
    parameter WIDTH = 16
)(
    input sclk,  // Clock
    input rst,   // Reset

    input ws,    // Word Select
    input sdata, // Audio Data

    // Audio Output
    output logic [WIDTH-1:0] left_chan,
    output logic [WIDTH-1:0] right_chan
);

logic [WIDTH-1:0] left;
logic [WIDTH-1:0] right;
logic ws_r;
logic ws_nedge;
logic ws_pedge;

// Register ws to allow edge detection
always @(posedge sclk) begin
    ws_r <= ws;
end

// Combinational edge detection
assign ws_nedge = !ws & ws_r;
assign ws_pedge = ws & !ws_r; 


// for the I2S standard (MSB is valid *after* the WS change).
always @(posedge sclk) begin
    if (ws_r)
        right <= {right[WIDTH-2:0], sdata};
    else
        left <= {left[WIDTH-2:0], sdata};
end

// Latch L/R audio data
always @(posedge sclk) begin
    if (rst) begin
        left_chan <= 0;
        right_chan <= 0;
    end else if (ws_nedge) begin
        // End of Right channel. Latch the right data.
        right_chan <= {right[WIDTH-2:0], sdata};
    end else if (ws_pedge) begin
        left_chan <= {left[WIDTH-2:0], sdata};
    end
end

endmodule