// I2Stx.sv

module I2Stx #(
    parameter WIDTH = 16
)(
    input  logic                sclk_i,
    input  logic                rst_i,
    output logic                ws_o,
    output logic                sdata_o,
    input  logic [WIDTH-1:0] leftChan_i,
    input  logic [WIDTH-1:0] rightChan_i
);

    logic [7:0] bitCnt; 
    
    // Shift register for serializing data
    logic [(2*WIDTH):0] shift_reg; // 33 bits for Width=16

	// Counter
    always @(negedge sclk_i) begin
        if (~rst_i)
            bitCnt <= -1;
        else if (bitCnt >= ((WIDTH*2)-1))
            bitCnt <= 0;
        else
            bitCnt <= bitCnt + 1;
    end

	
	// Shifter
	always @(negedge sclk_i) begin

		// Assign value first to prevent logic overwriting LSB
		
		
		if (~rst_i) begin
			shift_reg <= {1'b0, leftChan_i, rightChan_i};
			sdata_o <= 1'b0;
		end else if (bitCnt == (WIDTH*2 - 2)) begin
			shift_reg <= {shift_reg[2*WIDTH],leftChan_i, rightChan_i};
			sdata_o <= shift_reg[2*WIDTH];
		end else begin
			shift_reg <= shift_reg << 1;	
			sdata_o <= shift_reg[2*WIDTH];
		end
		

	end
	
	// ws_o clock
	always @(negedge sclk_i) begin
		if (~rst_i) begin
			ws_o <= 0; 
		end else if ((bitCnt == (WIDTH-1)) || (bitCnt == (WIDTH*2-1))) begin
			ws_o <= ~ws_o; 
		end
	end
   

endmodule