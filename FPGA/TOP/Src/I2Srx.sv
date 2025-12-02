module I2Srx #(
    parameter WIDTH = 16
)(
    input logic sclk_i,  // Clock
    input logic rst_i,   // Reset

    input logic ws_i,    // Word Select
    input logic sdata_i, // Audio Data

    // Audio Output
    output logic [WIDTH-1:0] leftChan_o,
    output logic [WIDTH-1:0] rightChan_o
);

logic [WIDTH-1:0] left;
logic [WIDTH-1:0] right;
logic wsPrev;
logic wsNEdge;
logic wsPEdge;

// Register ws_i to allow edge detection
always @(negedge sclk_i) begin
    wsPrev = ws_i;
end

// Combinational edge detection
assign wsNEdge = !ws_i & wsPrev;
assign wsPEdge = ws_i & !wsPrev;


// Check previous cycle since I2S runs on a 1 cycle delay
always @(posedge sclk_i) begin
	if (rst_i)begin
		left       = 0;
		right      = 0;
	end else if (wsPrev) begin
		right = {right[WIDTH-2:0], sdata_i};
	end else begin
		left = {left[WIDTH-2:0], sdata_i};
	end
end

// Latch L/R audio data
always @(posedge sclk_i) begin
    if (rst_i) begin
        leftChan_o  <= 0;
        rightChan_o <= 0;
    end else if (wsNEdge) begin
        // End of Right channel. Latch the *fully assembled* right data.
        rightChan_o <= right;
    end else if (wsPEdge) begin
        // End of Left channel. Latch the *fully assembled* left data.
        leftChan_o <= left;
		//ASYNCH FIFO ENABLE HERE AFTER FULL CYCLE
    end
end

endmodule