//==============================================================================
// File: axi_master.v
// Description: AXI4-Lite Master Module
// Author: [Your Name]
// Date: [Today's Date]
//==============================================================================

module axi_master #(
    parameter ADDR_WIDTH = 32,    // Address bus width
    parameter DATA_WIDTH = 32     // Data bus width
)(
    // Clock and Reset
    input  wire                      clk,
    input  wire                      rst_n,     // Active low reset
    
    //==========================================================================
    // AXI4-Lite Write Address Channel (AW)
    //==========================================================================
    output reg  [ADDR_WIDTH-1:0]     awaddr,    // Write address
    output reg                       awvalid,   // Write address valid
    input  wire                      awready,   // Write address ready (from slave)
    
    //==========================================================================
    // AXI4-Lite Write Data Channel (W)
    //==========================================================================
    output reg  [DATA_WIDTH-1:0]     wdata,     // Write data
    output reg  [3:0]                wstrb,     // Write strobes (byte enables)
    output reg                       wvalid,    // Write data valid
    input  wire                      wready,    // Write data ready (from slave)
    
    //==========================================================================
    // AXI4-Lite Write Response Channel (B)
    //==========================================================================
    input  wire [1:0]                bresp,     // Write response (OKAY, SLVERR, etc.)
    input  wire                      bvalid,    // Write response valid (from slave)
    output reg                       bready,    // Write response ready
    
    //==========================================================================
    // AXI4-Lite Read Address Channel (AR)
    //==========================================================================
    output reg  [ADDR_WIDTH-1:0]     araddr,    // Read address
    output reg                       arvalid,   // Read address valid
    input  wire                      arready,   // Read address ready (from slave)
    
    //==========================================================================
    // AXI4-Lite Read Data Channel (R)
    //==========================================================================
    input  wire [DATA_WIDTH-1:0]     rdata,     // Read data (from slave)
    input  wire [1:0]                rresp,     // Read response
    input  wire                      rvalid,    // Read data valid (from slave)
    output reg                       rready,    // Read data ready
    
    //==========================================================================
    // Control Interface (from Testbench)
    //==========================================================================
    input  wire                      start_write,  // Start write transaction
    input  wire                      start_read,   // Start read transaction
    input  wire [ADDR_WIDTH-1:0]     addr_in,      // Address input
    input  wire [DATA_WIDTH-1:0]     data_in,      // Data input (for write)
    output reg  [DATA_WIDTH-1:0]     data_out,     // Data output (from read)
    output reg                       done,         // Transaction complete
    output reg                       error         // Transaction error
);


//==============================================================================
// FSM State Definitions
//==============================================================================
localparam [2:0] IDLE        = 3'b000,  // Idle state
                 WRITE_ADDR  = 3'b001,  // Sending write address
                 WRITE_DATA  = 3'b010,  // Sending write data
                 WRITE_RESP  = 3'b011,  // Waiting for write response
                 READ_ADDR   = 3'b100,  // Sending read address
                 READ_DATA   = 3'b101;  // Waiting for read data

// State registers
reg [2:0] current_state;
reg [2:0] next_state;

// Internal registers to hold address and data during transaction
reg [ADDR_WIDTH-1:0] addr_reg;
reg [DATA_WIDTH-1:0] data_reg;


//==============================================================================
// State Register - Sequential Logic
// Updates current state on every clock edge
//==============================================================================
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        current_state <= IDLE;          // Reset to IDLE
        addr_reg <= 32'h0;
        data_reg <= 32'h0;
    end else begin
        current_state <= next_state;    // Move to next state
        
        // Capture address and data when transaction starts
        if (current_state == IDLE && (start_write || start_read)) begin
            addr_reg <= addr_in;
            data_reg <= data_in;
        end
    end
end


//==============================================================================
// Next State Logic - Combinational
// Determines next state based on current state and inputs
//==============================================================================
always @(*) begin
    // Default: stay in current state
    next_state = current_state;
    
    case (current_state)
        //======================================================================
        // IDLE State
        //======================================================================
        IDLE: begin
            if (start_write) begin
                next_state = WRITE_ADDR;        // Start write transaction
            end else if (start_read) begin
                next_state = READ_ADDR;         // Start read transaction
            end else begin
                next_state = IDLE;              // Stay in IDLE
            end
        end
        
        //======================================================================
        // WRITE_ADDR State - Sending write address
        //======================================================================
        WRITE_ADDR: begin
            if (awvalid && awready) begin       // Handshake complete?
                next_state = WRITE_DATA;        // Move to data phase
            end else begin
                next_state = WRITE_ADDR;        // Wait for awready
            end
        end
        
        //======================================================================
        // WRITE_DATA State - Sending write data
        //======================================================================
        WRITE_DATA: begin
            if (wvalid && wready) begin         // Handshake complete?
                next_state = WRITE_RESP;        // Move to response phase
            end else begin
                next_state = WRITE_DATA;        // Wait for wready
            end
        end
        
        //======================================================================
        // WRITE_RESP State - Waiting for write response
        //======================================================================
        WRITE_RESP: begin
            if (bvalid && bready) begin         // Handshake complete?
                next_state = IDLE;              // Transaction done
            end else begin
                next_state = WRITE_RESP;        // Wait for bvalid
            end
        end
        
        //======================================================================
        // READ_ADDR State - Sending read address
        //======================================================================
        READ_ADDR: begin
            if (arvalid && arready) begin       // Handshake complete?
                next_state = READ_DATA;         // Move to data phase
            end else begin
                next_state = READ_ADDR;         // Wait for arready
            end
        end
        
        //======================================================================
        // READ_DATA State - Waiting for read data
        //======================================================================
        READ_DATA: begin
            if (rvalid && rready) begin         // Handshake complete?
                next_state = IDLE;              // Transaction done
            end else begin
                next_state = READ_DATA;         // Wait for rvalid
            end
        end
        
        //======================================================================
        // Default case
        //======================================================================
        default: begin
            next_state = IDLE;
        end
    endcase
end


//==============================================================================
// Output Logic - What to do in each state
//==============================================================================
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        // Reset all outputs
        awaddr  <= 32'h0;
        awvalid <= 1'b0;
        wdata   <= 32'h0;
        wstrb   <= 4'b0000;
        wvalid  <= 1'b0;
        bready  <= 1'b0;
        araddr  <= 32'h0;
        arvalid <= 1'b0;
        rready  <= 1'b0;
        data_out<= 32'h0;
        done    <= 1'b0;
        error   <= 1'b0;
    end else begin
        // Default values (important to avoid latches!)
        done <= 1'b0;
        error <= 1'b0;
        
        case (current_state)
            //==================================================================
            // IDLE State - All outputs inactive
            //==================================================================
            IDLE: begin
                awvalid <= 1'b0;
                wvalid  <= 1'b0;
                bready  <= 1'b0;
                arvalid <= 1'b0;
                rready  <= 1'b0;
            end
            
            //==================================================================
            // WRITE_ADDR State - Assert write address
            //==================================================================
            WRITE_ADDR: begin
                awaddr  <= addr_reg;            // Send address
                awvalid <= 1'b1;                // Assert valid
                
                // Once handshake happens, prepare for next phase
                if (awready) begin
                    awvalid <= 1'b0;            // Can deassert after handshake
                end
            end
            
            //==================================================================
            // WRITE_DATA State - Assert write data
            //==================================================================
            WRITE_DATA: begin
                wdata  <= data_reg;             // Send data
                wstrb  <= 4'b1111;              // Write all 4 bytes
                wvalid <= 1'b1;                 // Assert valid
                
                if (wready) begin
                    wvalid <= 1'b0;
                end
            end
            
            //==================================================================
            // WRITE_RESP State - Accept write response
            //==================================================================
            WRITE_RESP: begin
                bready <= 1'b1;                 // Ready to receive response
                
                if (bvalid) begin
                    // Check response
                    if (bresp == 2'b00) begin   // OKAY
                        done <= 1'b1;           // Signal completion
                    end else begin              // ERROR
                        error <= 1'b1;
                    end
                    bready <= 1'b0;
                end
            end
            
            //==================================================================
            // READ_ADDR State - Assert read address
            //==================================================================
            READ_ADDR: begin
                araddr  <= addr_reg;            // Send address
                arvalid <= 1'b1;                // Assert valid
                
                if (arready) begin
                    arvalid <= 1'b0;
                end
            end
            
            //==================================================================
            // READ_DATA State - Accept read data
            //==================================================================
            READ_DATA: begin
                rready <= 1'b1;                 // Ready to receive data
                
                if (rvalid) begin
                    data_out <= rdata;          // Capture read data
                    
                    if (rresp == 2'b00) begin   // OKAY
                        done <= 1'b1;
                    end else begin              // ERROR
                        error <= 1'b1;
                    end
                    rready <= 1'b0;
                end
            end
            
            //==================================================================
            // Default case
            //==================================================================
            default: begin
                awvalid <= 1'b0;
                wvalid  <= 1'b0;
                bready  <= 1'b0;
                arvalid <= 1'b0;
                rready  <= 1'b0;
            end
        endcase
    end
end

endmodule  // axi_master