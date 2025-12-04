module I2Srx #(
    parameter WIDTH = 16
)(
    input  logic sclk_i, 
    input  logic rst_n_i,
    input  logic ws_i,    
    input  logic sdata_i, 

    output logic [WIDTH-1:0] leftChan_o,
    output logic [WIDTH-1:0] rightChan_o,
    output logic             pktI2SRxChanged_o
);

    logic [WIDTH-1:0] shift_reg;
    logic ws_reg;
    logic [5:0] bit_cnt; // Counter to protect MSBs

    // Everything happens on the Rising Edge (Spec Compliant [cite: 95, 111])
    always @(posedge sclk_i) begin
        if (~rst_n_i) begin
            ws_reg      <= 0;
            bit_cnt     <= 0;
            leftChan_o  <= 0;
            rightChan_o <= 0;
            pktI2SRxChanged_o <= 0;
        end else begin
            // 1. Detect WS Edge (Compare current Input vs Registered)
            if (ws_i != ws_reg) begin
                // --- WS CHANGED (This is the Delay Bit Cycle) ---
                
                // A. Latch the COMPLETED channel to output
                // If WS was Low, Left just finished. If High, Right finished.
                if (ws_reg == 1'b0) leftChan_o  <= shift_reg;
                else                rightChan_o <= shift_reg;

                // B. Handle the Output Strobe
                // If WS is now Low (Left starting), it means Right just finished.
                if (ws_i == 1'b0) pktI2SRxChanged_o <= 1'b1; 
                else              pktI2SRxChanged_o <= 1'b0;

                // C. Reset for the New Word
                bit_cnt <= 0;      // Reset bit counter
                shift_reg <= 0;    // Clear shifter
                ws_reg <= ws_i;    // Update WS history
                
                // D. CRITICAL: Do NOT shift sdata_i in this cycle. 
                // We intentionally ignore the "Delay Bit".
            end 
            else begin
                // --- MIDDLE OF WORD ---
                pktI2SRxChanged_o <= 1'b0;

                // Only shift if we haven't filled the register yet.
                // This prevents 32-bit slots from overwriting our 16-bit data.
                if (bit_cnt < WIDTH) begin
                    shift_reg <= {shift_reg[WIDTH-2:0], sdata_i}; // Shift Left (MSB First)
                    bit_cnt   <= bit_cnt + 1'b1;
                end
            end
        end
    end

endmodule