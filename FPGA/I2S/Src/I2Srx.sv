module I2Srx #(
    parameter WIDTH = 16
)(
    input logic sclk,  // Clock
    input logic rst,   // Reset

    input logic ws,    // Word Select
    input logic sdata, // Audio Data

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
always @(negedge sclk) begin
    ws_r = ws;
end

// Combinational edge detection
assign ws_nedge = !ws & ws_r;
assign ws_pedge = ws & !ws_r;


// Check previous cycle since I2S runs on a 1 cycle delay
always @(posedge sclk) begin
	if (rst)begin
		left       = 0;
		right      = 0;
	end else if (ws_r) begin
		right = {right[WIDTH-2:0], sdata};
	end else begin
		left = {left[WIDTH-2:0], sdata};
	end
end

// Latch L/R audio data
always @(posedge sclk) begin
    if (rst) begin
        left_chan  <= 0;
        right_chan <= 0;
    end else if (ws_nedge) begin
        // End of Right channel. Latch the *fully assembled* right data.
        right_chan <= right;
    end else if (ws_pedge) begin
        // End of Left channel. Latch the *fully assembled* left data.
        left_chan <= left;
		//ASYNCH FIFO ENABLE HERE AFTER FULL CYCLE
    end
end

endmodule