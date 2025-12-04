module I2Stx #(
    parameter WIDTH = 16
)(
    input  logic                sclk_i,      // SCK from MCU
    input  logic                rst_n_i,
    input  logic                ws_i,        // WS from MCU (Use this!)
    output logic                sdata_o,     // SD to MCU
    
    input  logic [WIDTH-1:0]    leftChan_i,
    input  logic [WIDTH-1:0]    rightChan_i
);

    // Shift register: 2*WIDTH + 1 bit for the I2S delay
    logic [WIDTH*2:0] shift_reg; 
    logic ws_prev;
    
    // We detect edges to know when the MCU wants data
    logic ws_rising;  // Start of Right Channel [cite: 132]
    logic ws_falling; // Start of Left Channel [cite: 131]

    // 1. Edge Detection
    // The spec says data is clocked out on the falling edge.
    always @(negedge sclk_i) begin
        if (~rst_n_i) ws_prev <= 0;
        else        ws_prev <= ws_i;
    end
    
    assign ws_falling = (ws_prev == 1'b1) && (ws_i == 1'b0);
    assign ws_rising  = (ws_prev == 1'b0) && (ws_i == 1'b1);

    // 2. Data Transmission Logic
    always @(negedge sclk_i) begin
        if (~rst_n_i) begin
            shift_reg <= '0;
            sdata_o   <= 1'b0;
        end else begin
            // Handling the "1 clock period" delay [cite: 116, 135]
            if (ws_falling) begin
                // WS dropped (Start Left). Load Left Data.
                // We pad with 0 at the LSB to handle the 1-cycle delay naturally.
                shift_reg <= {leftChan_i, rightChan_i, 1'b0};
                sdata_o   <= 1'b0; // Output 0 for the first cycle (The Delay Bit)
            end 
            else if (ws_rising) begin
                // WS rose (Start Right). Load Right Data.
                // Note: We only need to load Right, but we pad to match the reg size.
                shift_reg <= {rightChan_i, {WIDTH{1'b0}}, 1'b0};
                sdata_o   <= 1'b0; // Output 0 for the first cycle (The Delay Bit)
            end 
            else begin
                // Shift out the MSB
                sdata_o   <= shift_reg[WIDTH*2]; 
                shift_reg <= shift_reg << 1;
            end
        end
    end

endmodule