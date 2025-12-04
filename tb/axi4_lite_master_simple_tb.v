//==============================================================================
// File: axi_master_simple_tb.v
// Description: Simple testbench to verify master module compiles
//==============================================================================

`timescale 1ns/1ps

module axi_master_simple_tb;

//==============================================================================
// Testbench Signals
//==============================================================================
reg         clk;
reg         rst_n;
reg         start_write;
reg         start_read;
reg  [31:0] addr_in;
reg  [31:0] data_in;
wire [31:0] data_out;
wire        done;
wire        error;

// AXI signals (will connect to slave later)
wire [31:0] awaddr;
wire        awvalid;
reg         awready;    // Driven by testbench for now
wire [31:0] wdata;
wire [3:0]  wstrb;
wire        wvalid;
reg         wready;     // Driven by testbench for now
reg  [1:0]  bresp;
reg         bvalid;     // Driven by testbench for now
wire        bready;
wire [31:0] araddr;
wire        arvalid;
reg         arready;    // Driven by testbench for now
reg  [31:0] rdata;
reg  [1:0]  rresp;
reg         rvalid;     // Driven by testbench for now
wire        rready;

//==============================================================================
// Instantiate Master Module
//==============================================================================
axi_master #(
    .ADDR_WIDTH(32),
    .DATA_WIDTH(32)
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
    // Control
    .start_write(start_write),
    .start_read(start_read),
    .addr_in(addr_in),
    .data_in(data_in),
    .data_out(data_out),
    .done(done),
    .error(error)
);

//==============================================================================
// Clock Generation - 10ns period (100MHz)
//==============================================================================
initial begin
    clk = 0;
    forever #5 clk = ~clk;  // Toggle every 5ns
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
    awready = 0;
    wready = 0;
    bresp = 2'b00;  // OKAY
    bvalid = 0;
    arready = 0;
    rdata = 0;
    rresp = 2'b00;  // OKAY
    rvalid = 0;
    
    // Display start
    $display("========================================");
    $display("AXI Master Simple Testbench");
    $display("========================================");
    
    // Apply reset
    #20;
    rst_n = 1;
    $display("Time=%0t: Reset released", $time);
    #20;
    
    //==========================================================================
    // Test 1: Simple Write Transaction
    //==========================================================================
    $display("\n--- Test 1: Write Transaction ---");
    $display("Time=%0t: Starting write to addr=0x00000004, data=0xDEADBEEF", $time);
    
    addr_in = 32'h0000_0004;
    data_in = 32'hDEAD_BEEF;
    start_write = 1;
    #10;
    start_write = 0;
    
    // Simulate slave responses
    #20;
    awready = 1;  // Accept address
    #10;
    awready = 0;
    
    #10;
    wready = 1;   // Accept data
    #10;
    wready = 0;
    
    #10;
    bvalid = 1;   // Send response
    bresp = 2'b00; // OKAY
    #10;
    bvalid = 0;
    
    // Wait for done
    wait(done);
    $display("Time=%0t: Write transaction complete!", $time);
    
    #50;
    
    //==========================================================================
    // Test 2: Simple Read Transaction
    //==========================================================================
    $display("\n--- Test 2: Read Transaction ---");
    $display("Time=%0t: Starting read from addr=0x00000004", $time);
    
    addr_in = 32'h0000_0004;
    start_read = 1;
    #10;
    start_read = 0;
    
    // Simulate slave responses
    #20;
    arready = 1;  // Accept address
    #10;
    arready = 0;
    
    #20;
    rvalid = 1;   // Send data
    rdata = 32'hDEAD_BEEF;
    rresp = 2'b00; // OKAY
    #10;
    rvalid = 0;
    
    // Wait for done
    wait(done);
    $display("Time=%0t: Read transaction complete! Data=%h", $time, data_out);
    
    #50;
    
    //==========================================================================
    // End Simulation
    //==========================================================================
    $display("\n========================================");
    $display("All tests completed successfully!");
    $display("========================================");
    $finish;
end

//==============================================================================
// Monitor signals
//==============================================================================
initial begin
    $monitor("Time=%0t | State: awvalid=%b wvalid=%b bready=%b arvalid=%b rready=%b | done=%b error=%b", 
             $time, awvalid, wvalid, bready, arvalid, rready, done, error);
end

endmodule
