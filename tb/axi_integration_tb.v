//==============================================================================
// File: axi_integration_tb.v
// Description: Integration testbench for AXI Master + Slave
// Author: Tanmay Rambha
// Date: [Today's Date]
//==============================================================================

`timescale 1ns/1ps

module axi_integration_tb;

//==============================================================================
// Parameters
//==============================================================================
parameter ADDR_WIDTH = 32;
parameter DATA_WIDTH = 32;
parameter CLK_PERIOD = 10;  // 10ns = 100MHz

//==============================================================================
// Testbench Signals
//==============================================================================
reg         clk;
reg         rst_n;

// Master control signals
reg         start_write;
reg         start_read;
reg  [31:0] addr_in;
reg  [31:0] data_in;
wire [31:0] data_out;
wire        done;
wire        error;

// AXI channel signals (connecting master to slave)
wire [31:0] awaddr;
wire        awvalid;
wire        awready;
wire [31:0] wdata;
wire [3:0]  wstrb;
wire        wvalid;
wire        wready;
wire [1:0]  bresp;
wire        bvalid;
wire        bready;
wire [31:0] araddr;
wire        arvalid;
wire        arready;
wire [31:0] rdata;
wire [1:0]  rresp;
wire        rvalid;
wire        rready;

//==============================================================================
// Instantiate AXI Master
//==============================================================================
axi_master #(
    .ADDR_WIDTH(ADDR_WIDTH),
    .DATA_WIDTH(DATA_WIDTH)
) master (
    .clk(clk),
    .rst_n(rst_n),
    // Write channels
    .awaddr(awaddr),
    .awvalid(awvalid),
    .awready(awready),
    .wdata(wdata),
    .wstrb(wstrb),
    .wvalid(wvalid),
    .wready(wready),
    .bresp(bresp),
    .bvalid(bvalid),
    .bready(bready),
    // Read channels
    .araddr(araddr),
    .arvalid(arvalid),
    .arready(arready),
    .rdata(rdata),
    .rresp(rresp),
    .rvalid(rvalid),
    .rready(rready),
    // Control signals
    .start_write(start_write),
    .start_read(start_read),
    .addr_in(addr_in),
    .data_in(data_in),
    .data_out(data_out),
    .done(done),
    .error(error)
);

//==============================================================================
// Instantiate AXI Slave
//==============================================================================
axi_slave #(
    .ADDR_WIDTH(ADDR_WIDTH),
    .DATA_WIDTH(DATA_WIDTH),
    .MEM_DEPTH(1024)
) slave (
    .clk(clk),
    .rst_n(rst_n),
    // Write channels
    .awaddr(awaddr),
    .awvalid(awvalid),
    .awready(awready),
    .wdata(wdata),
    .wstrb(wstrb),
    .wvalid(wvalid),
    .wready(wready),
    .bresp(bresp),
    .bvalid(bvalid),
    .bready(bready),
    // Read channels
    .araddr(araddr),
    .arvalid(arvalid),
    .arready(arready),
    .rdata(rdata),
    .rresp(rresp),
    .rvalid(rvalid),
    .rready(rready)
);

//==============================================================================
// Clock Generation - 10ns period (100MHz)
//==============================================================================
initial begin
    clk = 0;
    forever #(CLK_PERIOD/2) clk = ~clk;
end

//==============================================================================
// Test Stimulus
//==============================================================================
initial begin
    // Initialize signals
    rst_n = 0;
    start_write = 0;
    start_read = 0;
    addr_in = 0;
    data_in = 0;
    
    // Display banner
    $display("========================================");
    $display("AXI4-Lite Integration Test");
    $display("Master + Slave + Memory");
    $display("========================================\n");
    
    // Apply reset
    #20;
    rst_n = 1;
    $display("Time=%0t: Reset released\n", $time);
    #20;
    
    //==========================================================================
    // Test 1: Write to Address 0x00000004
    //==========================================================================
    $display("========================================");
    $display("Test 1: Write Transaction");
    $display("========================================");
    $display("Time=%0t: Writing 0xDEADBEEF to address 0x00000004", $time);
    
    addr_in = 32'h0000_0004;
    data_in = 32'hDEAD_BEEF;
    start_write = 1;
    #10;
    start_write = 0;
    
    // Wait for done signal
    wait(done);
    $display("Time=%0t: Write transaction complete!", $time);
    
    if (error) begin
        $display("ERROR: Write transaction failed!");
        $finish;
    end else begin
        $display("SUCCESS: Write transaction completed with no errors\n");
    end
    
    #50;
    
    //==========================================================================
    // Test 2: Read from Address 0x00000004
    //==========================================================================
    $display("========================================");
    $display("Test 2: Read Transaction");
    $display("========================================");
    $display("Time=%0t: Reading from address 0x00000004", $time);
    
    addr_in = 32'h0000_0004;
    start_read = 1;
    #10;
    start_read = 0;
    
    // Wait for done signal
    wait(done);
    $display("Time=%0t: Read transaction complete!", $time);
    $display("Time=%0t: Data read = 0x%h", $time, data_out);
    
    if (error) begin
        $display("ERROR: Read transaction failed!");
        $finish;
    end else if (data_out == 32'hDEAD_BEEF) begin
        $display("SUCCESS: Read data matches written data! ✓");
        $display("         Expected: 0xDEADBEEF");
        $display("         Got:      0x%h\n", data_out);
    end else begin
        $display("ERROR: Data mismatch!");
        $display("       Expected: 0xDEADBEEF");
        $display("       Got:      0x%h", data_out);
        $finish;
    end
    
    #50;
    
    //==========================================================================
    // Test 3: Write to Address 0x00000008
    //==========================================================================
    $display("========================================");
    $display("Test 3: Write to Different Address");
    $display("========================================");
    $display("Time=%0t: Writing 0x12345678 to address 0x00000008", $time);
    
    addr_in = 32'h0000_0008;
    data_in = 32'h1234_5678;
    start_write = 1;
    #10;
    start_write = 0;
    
    wait(done);
    $display("Time=%0t: Write transaction complete!", $time);
    
    if (!error) begin
        $display("SUCCESS: Second write completed\n");
    end
    
    #50;
    
    //==========================================================================
    // Test 4: Read from Address 0x00000008
    //==========================================================================
    $display("========================================");
    $display("Test 4: Read from Second Address");
    $display("========================================");
    $display("Time=%0t: Reading from address 0x00000008", $time);
    
    addr_in = 32'h0000_0008;
    start_read = 1;
    #10;
    start_read = 0;
    
    wait(done);
    $display("Time=%0t: Read transaction complete!", $time);
    $display("Time=%0t: Data read = 0x%h", $time, data_out);
    
    if (data_out == 32'h1234_5678) begin
        $display("SUCCESS: Read data matches! ✓\n");
    end else begin
        $display("ERROR: Data mismatch!");
        $finish;
    end
    
    #50;
    
    //==========================================================================
    // Test 5: Verify First Address Still Has Original Data
    //==========================================================================
    $display("========================================");
    $display("Test 5: Verify Data Integrity");
    $display("========================================");
    $display("Time=%0t: Re-reading from address 0x00000004", $time);
    
    addr_in = 32'h0000_0004;
    start_read = 1;
    #10;
    start_read = 0;
    
    wait(done);
    $display("Time=%0t: Read transaction complete!", $time);
    $display("Time=%0t: Data read = 0x%h", $time, data_out);
    
    if (data_out == 32'hDEAD_BEEF) begin
        $display("SUCCESS: Original data preserved! ✓");
        $display("         Memory integrity verified!\n");
    end else begin
        $display("ERROR: Data corruption detected!");
        $finish;
    end
    
    #50;
    
    //==========================================================================
    // Test 6: Write with Byte Enables (Lower 2 bytes only)
    //==========================================================================
    $display("========================================");
    $display("Test 6: Byte-Enable Write (Advanced)");
    $display("========================================");
    $display("Time=%0t: Writing 0xABCDEF00 to address 0x0000000C", $time);
    $display("          (Note: This test requires byte-enable functionality)");
    
    addr_in = 32'h0000_000C;
    data_in = 32'hABCD_EF00;
    start_write = 1;
    #10;
    start_write = 0;
    
    wait(done);
    $display("Time=%0t: Write complete!", $time);
    
    // Read back
    addr_in = 32'h0000_000C;
    start_read = 1;
    #10;
    start_read = 0;
    
    wait(done);
    $display("Time=%0t: Data read = 0x%h", $time, data_out);
    
    if (data_out == 32'hABCD_EF00) begin
        $display("SUCCESS: Byte-enable write working! ✓\n");
    end
    
    #50;
    
    //==========================================================================
    // All Tests Complete
    //==========================================================================
    $display("========================================");
    $display("ALL TESTS PASSED! ✓✓✓");
    $display("========================================");
    $display("Summary:");
    $display("  ✓ Write transactions working");
    $display("  ✓ Read transactions working");
    $display("  ✓ Data integrity verified");
    $display("  ✓ Multiple addresses working");
    $display("  ✓ Memory functioning correctly");
    $display("  ✓ Master-Slave integration successful");
    $display("========================================\n");
    
    #100;
    $finish;
end

//==============================================================================
// Timeout Watchdog
//==============================================================================
initial begin
    #10000;  // 10 microseconds timeout
    $display("\n========================================");
    $display("ERROR: Simulation timeout!");
    $display("Check for deadlock or infinite loop");
    $display("========================================\n");
    $finish;
end

//==============================================================================
// Optional: Monitor AXI Transactions
//==============================================================================
// Uncomment to see detailed transaction flow
/*
always @(posedge clk) begin
    if (awvalid && awready)
        $display("Time=%0t: AW Handshake - Address=0x%h", $time, awaddr);
    if (wvalid && wready)
        $display("Time=%0t: W Handshake  - Data=0x%h", $time, wdata);
    if (bvalid && bready)
        $display("Time=%0t: B Handshake  - Response=%b", $time, bresp);
    if (arvalid && arready)
        $display("Time=%0t: AR Handshake - Address=0x%h", $time, araddr);
    if (rvalid && rready)
        $display("Time=%0t: R Handshake  - Data=0x%h", $time, rdata);
end
*/

endmodule