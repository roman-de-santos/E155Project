module I2Stx #(
    parameter WIDTH = 16
)(
    input  logic                sclk,
    input  logic                rst,
    output logic                ws,
    output logic                sdata,
    input  logic [WIDTH-1:0] left_chan,
    input  logic [WIDTH-1:0] right_chan
);

    logic [7:0] bitCnt; 
    
    // Shift register for serializing data
    logic [(2*WIDTH):0] shift_reg; // 33 bits for Width=16

	// Counter
    always @(negedge sclk) begin
        if (rst)
            bitCnt <= 0;
        else if (bitCnt >= WIDTH*2)
            bitCnt <= 0;
        else
            bitCnt <= bitCnt + 1;
    end

	
	// Shifter
	always @(negedge sclk) begin

		// Assign value first to prevent logic overwriting LSB
		
		
		if (rst) begin
			shift_reg <= {1'b0, left_chan, right_chan};
			sdata <= 1'b0;
		end else if (bitCnt == (WIDTH*2 - 2)) begin
			shift_reg <= {shift_reg[2*WIDTH],left_chan, right_chan};
			sdata <= shift_reg[2*WIDTH];
		end else begin
			shift_reg <= shift_reg << 1;	
			sdata <= shift_reg[2*WIDTH];
		end
		

	end
	
	// WS clock
	always @(negedge sclk) begin
		if (rst) begin
			ws <= 1;    // start with left channel
		end else if ((bitCnt == (WIDTH)) || (bitCnt == (WIDTH*2))) begin
			ws <= ~ws; 
		end
	end
   

endmodule