module Data_Fast_to_Slow #(
    parameter int WIDTH = 16,
    parameter int FAST_FREQ = 100,
    parameter int SLOW_FREQ = 12
)(
    input  logic             Clk_Fast,
    input  logic             Clk_Slow,
    input  logic             Rst,
    
    // Fast Domain Inputs
    input  logic [WIDTH-1:0] Data_In_Fast,
    input  logic             Valid_In_Fast, // Pulse this when DSP is done
    
    // Slow Domain Outputs
    output logic [WIDTH-1:0] Data_Out_Slow,
    output logic             Valid_Out_Slow // High for 1 cycle when new data arrives
);

    logic valid_extended;
    logic valid_sync_meta, valid_sync;
    logic valid_sync_prev;

    // 1. Instantiate the Pulse Extender for the "Valid" signal
    Fast_to_Slow_CDC #(
        .FAST_CLK_FREQ_MHZ(FAST_FREQ),
        .SLOW_CLK_FREQ_MHZ(SLOW_FREQ)
    ) Flag_Sync (
        .Clk_Fast(Clk_Fast),
        .Clk_Slow(Clk_Slow),
        .Rst(Rst),
        .Input_Signal(Valid_In_Fast),
        .Received_Sample(valid_extended) 
    );

    // 2. Data Latching Logic
    // We rely on the fact that the data is stable while the valid flag is being synchronized.
    
    // Edge detection in Slow Domain
    always_ff @(posedge Clk_Slow) begin
        valid_sync_prev <= valid_extended;
    end
    
    // Detect Rising Edge of the synchronized flag
    assign Valid_Out_Slow = valid_extended && !valid_sync_prev;

    // 3. Capture Data safely
    // Since Valid_In_Fast triggered the process, we assume Data_In_Fast 
    // was valid at that moment. We capture it into the slow domain 
    // ONLY when the slow sync flag arrives.
    
    // Note: For this to work perfectly, Data_In_Fast should ideally be held 
    // stable by the DSP until the handshake is complete, or we simply latch 
    // it into a register in the fast domain first (recommended).
    
    logic [WIDTH-1:0] data_holding_reg;
    
    always_ff @(posedge Clk_Fast) begin
        if (Valid_In_Fast) begin
            data_holding_reg <= Data_In_Fast;
        end
    end

    always_ff @(posedge Clk_Slow) begin
        if (Valid_Out_Slow) begin
            Data_Out_Slow <= data_holding_reg;
        end
    end

endmodule