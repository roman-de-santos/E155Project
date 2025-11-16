module i2s_tx #(
    parameter AUDIO_DW = 16
)(
    input  logic                sclk,
    input  logic                rst,
    input  logic [5:0]          prescaler, // Number of sclks per channel (e.g., 16, 24, 32)
    output logic                ws,
    output logic                sdata,
    input  logic [AUDIO_DW-1:0] left_chan,
    input  logic [AUDIO_DW-1:0] right_chan
);

    reg [5:0] bitCnt; 
    
    // Internal registers for double-buffering audio data
    reg [AUDIO_DW-1:0] left;
    reg [AUDIO_DW-1:0] right;
    
    // Shift register for serializing data
    reg [AUDIO_DW-1:0] shift_reg; 

    // but rst is active-high
    // Note: I2S is typically synchronous, so a posedge clock is more common.
    // But negedge works if the whole system uses it.
    always @(negedge sclk) begin
        if (rst)
            bitCnt <= 1;
        else if (bitCnt >= prescaler)
            bitCnt <= 1;
        else
            bitCnt <= bitCnt + 1;
    end

    // Word Select (WS) logic
    always @(negedge sclk) begin
        if (rst)
            ws <= 1; // Start with right channel
        else if (bitCnt == prescaler)
            ws <= ~ws;
    end

    // Data sampling logic
    // Samples new data at the end of the right channel for the next frame
    always @(negedge sclk) begin
        if (bitCnt == prescaler && ws) begin
            left <= left_chan;
            right <= right_chan;
        end
    end

    // This implements the shift register and I2S 1-bit delay
    always @(negedge sclk) begin
        if (rst) begin
            sdata <= 1'b0;
            shift_reg <= 0;
        end
        else begin
            // On the first bit of a new channel
            if (bitCnt == 1) begin
                
                // Data is not sent on the first clock edge after a WS change. ?? DOUBLE CHECK THIS WITH THE PROTOCAL
                sdata <= 1'b0; 
                
                // Load the shift register for the upcoming channel
                if (ws == 0) // Left Channel
                    shift_reg <= left;
                else // Right Channel
                    shift_reg <= right;
            end
            
            // For the rest of the audio data bits
            // (e.g., bits 2 through 17 for 16-bit audio)
            else if (bitCnt <= AUDIO_DW + 1) begin
                sdata <= shift_reg[AUDIO_DW - 1]; // Output MSB
                shift_reg <= shift_reg << 1;     // Shift for next bit
            end
            
            // Pad with zeros if prescaler > AUDIO_DW
            else begin
                sdata <= 1'b0;
            end
        end
    end

endmodule