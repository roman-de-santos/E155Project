`timescale 1ns / 1ps

module Data_Fast_to_Slow_tb;

    // =========================================================================
    // 1. Parameters & Signals
    // =========================================================================
    parameter WIDTH = 16;
    
    // Simulation Clocks
    logic Clk_Fast = 0; // 100 MHz (DSP Clock)
    logic Clk_Slow = 0; // ~12 MHz (I2S SCLK from MCU)
    
    // Control Signals
    logic Rst = 1;
    
    // Fast Domain Signals (Input to CDC)
    logic [WIDTH-1:0] Data_In_Fast;
    logic             Valid_In_Fast;
    
    // Slow Domain Signals (Output from CDC)
    logic [WIDTH-1:0] Data_Out_Slow;
    logic             Valid_Out_Slow;

    // Test Variables
    logic [WIDTH-1:0] expected_data;
    integer error_count = 0;
    integer transaction_count = 0;

    // =========================================================================
    // 2. DUT Instantiation (The Module we created)
    // =========================================================================
    Data_Fast_to_Slow #(
        .WIDTH(WIDTH),
        .FAST_FREQ(100), // 100 MHz
        .SLOW_FREQ(12)   // 12 MHz
    ) DUT (
        .Clk_Fast(Clk_Fast),
        .Clk_Slow(Clk_Slow),
        .Rst(Rst),
        .Data_In_Fast(Data_In_Fast),
        .Valid_In_Fast(Valid_In_Fast),
        .Data_Out_Slow(Data_Out_Slow),
        .Valid_Out_Slow(Valid_Out_Slow)
    );

    // =========================================================================
    // 3. Clock Generation
    // =========================================================================
    // 100 MHz Fast Clock (10ns period)
    always #5 Clk_Fast = ~Clk_Fast; 

    // ~12.288 MHz Slow Clock (Approx 81ns period)
    // We make this slightly asynchronous to the fast clock to test robustness
    always #40.7 Clk_Slow = ~Clk_Slow; 

    // =========================================================================
    // 4. Test Sequence
    // =========================================================================
    initial begin
        $display("=== Starting Fast to Slow CDC Testbench ===");
        
        // Initialize
        Rst = 1;
        Valid_In_Fast = 0;
        Data_In_Fast = 0;
        
        // Apply Reset
        #200;
        @(posedge Clk_Fast);
        Rst = 0;
        $display("Reset Released");
        #100;

        // --- Transaction Loop ---
        repeat (10) begin
            // 1. Generate Random Data
            expected_data = $urandom();
            
            // 2. Send Data in Fast Domain
            @(posedge Clk_Fast);
            Data_In_Fast  <= expected_data;
            Valid_In_Fast <= 1'b1; // Pulse "Ready" signal
            
            @(posedge Clk_Fast);
            Valid_In_Fast <= 1'b0; // Clear pulse
            
            // 3. Wait for Data in Slow Domain
            // We use a timeout to prevent infinite hanging if logic fails
            fork
                begin
                    // Wait for the Valid pulse in slow domain
                    @(posedge Valid_Out_Slow); 
                end
                begin
                    // Timeout watchdog (approx 20 slow cycles)
                    #2000; 
                    $display("ERROR: Timeout waiting for data transfer!");
                    $stop;
                end
            join_any
            disable fork; // Kill the timeout thread if data arrived

            // 4. Check Data
            if (Data_Out_Slow === expected_data) begin
                $display("[PASS] Sent: 0x%h | Received: 0x%h", expected_data, Data_Out_Slow);
            end else begin
                $display("[FAIL] Sent: 0x%h | Received: 0x%h", expected_data, Data_Out_Slow);
                error_count++;
            end

            transaction_count++;
            
            // Wait a random bit before next packet to simulate real DSP gaps
            repeat ($urandom_range(5, 20)) @(posedge Clk_Fast);
        end

        // --- Final Report ---
        #500;
        if (error_count == 0)
            $display("=== TEST PASSED: %0d Transactions Successful ===", transaction_count);
        else
            $display("=== TEST FAILED: %0d Errors Detected ===", error_count);
        
        $stop;
    end

endmodule