//==============================================================================
// File: axi_slave.v
// Description: AXI4-Lite Slave Module with Memory Interface
// Author: Tanmay Rambha
// Date: [Today's Date]
//==============================================================================

module axi_slave #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32,
    parameter MEM_DEPTH  = 1024    // 4KB = 1024 words of 32 bits
)(
    // Clock and Reset
    input  wire                      clk,
    input  wire                      rst_n,
    
    //==========================================================================
    // AXI4-Lite Write Address Channel (AW)
    //==========================================================================
    input  wire [ADDR_WIDTH-1:0]     awaddr,    // Write address from master
    input  wire                      awvalid,   // Write address valid from master
    output reg                       awready,   // Write address ready (to master)
    
    //==========================================================================
    // AXI4-Lite Write Data Channel (W)
    //==========================================================================
    input  wire [DATA_WIDTH-1:0]     wdata,     // Write data from master
    input  wire [3:0]                wstrb,     // Write strobes (byte enables)
    input  wire                      wvalid,    // Write data valid from master
    output reg                       wready,    // Write data ready (to master)
    
    //==========================================================================
    // AXI4-Lite Write Response Channel (B)
    //==========================================================================
    output reg  [1:0]                bresp,     // Write response (OKAY, SLVERR)
    output reg                       bvalid,    // Write response valid (to master)
    input  wire                      bready,    // Write response ready from master
    
    //==========================================================================
    // AXI4-Lite Read Address Channel (AR)
    //==========================================================================
    input  wire [ADDR_WIDTH-1:0]     araddr,    // Read address from master
    input  wire                      arvalid,   // Read address valid from master
    output reg                       arready,   // Read address ready (to master)
    
    //==========================================================================
    // AXI4-Lite Read Data Channel (R)
    //==========================================================================
    output reg  [DATA_WIDTH-1:0]     rdata,     // Read data (to master)
    output reg  [1:0]                rresp,     // Read response
    output reg                       rvalid,    // Read data valid (to master)
    input  wire                      rready     // Read data ready from master
);

//==============================================================================
// Memory Array - 4KB storage
//==============================================================================
reg [DATA_WIDTH-1:0] memory [0:MEM_DEPTH-1];

//==============================================================================
// FSM State Definitions
//==============================================================================
localparam [2:0] IDLE        = 3'b000,
                 WRITE_ADDR  = 3'b001,
                 WRITE_DATA  = 3'b010,
                 WRITE_RESP  = 3'b011,
                 READ_ADDR   = 3'b100,
                 READ_DATA   = 3'b101;

// State registers
reg [2:0] write_state;
reg [2:0] next_write_state;
reg [2:0] read_state;
reg [2:0] next_read_state;

// Internal registers to store address during transaction
reg [ADDR_WIDTH-1:0] write_addr_reg;
reg [ADDR_WIDTH-1:0] read_addr_reg;

// Word address (dividing byte address by 4 for 32-bit words)
wire [9:0] write_word_addr = write_addr_reg[11:2];  // Bits [11:2] for word addressing
wire [9:0] read_word_addr  = read_addr_reg[11:2];

//==============================================================================
// Write Path State Register - Sequential Logic
//==============================================================================
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        write_state <= IDLE;
        write_addr_reg <= 32'h0;
    end else begin
        write_state <= next_write_state;
        
        // Capture write address when it arrives
        if (write_state == IDLE && awvalid) begin
            write_addr_reg <= awaddr;
        end
    end
end

//==============================================================================
// Write Path Next State Logic - Combinational
//==============================================================================
always @(*) begin
    next_write_state = write_state;
    
    case (write_state)
        //======================================================================
        // IDLE - Wait for write address
        //======================================================================
        IDLE: begin
            if (awvalid) begin
                next_write_state = WRITE_ADDR;
            end
        end
        
        //======================================================================
        // WRITE_ADDR - Accept write address
        //======================================================================
        WRITE_ADDR: begin
            if (awvalid && awready) begin
                next_write_state = WRITE_DATA;
            end
        end
        
        //======================================================================
        // WRITE_DATA - Accept write data and write to memory
        //======================================================================
        WRITE_DATA: begin
            if (wvalid && wready) begin
                next_write_state = WRITE_RESP;
            end
        end
        
        //======================================================================
        // WRITE_RESP - Send write response
        //======================================================================
        WRITE_RESP: begin
            if (bvalid && bready) begin
                next_write_state = IDLE;
            end
        end
        
        default: begin
            next_write_state = IDLE;
        end
    endcase
end

//==============================================================================
// Write Path Output Logic
//==============================================================================
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        awready <= 1'b0;
        wready  <= 1'b0;
        bresp   <= 2'b00;
        bvalid  <= 1'b0;
    end else begin
        case (write_state)
            //==================================================================
            // IDLE State
            //==================================================================
            IDLE: begin
                awready <= 1'b0;
                wready  <= 1'b0;
                bvalid  <= 1'b0;
            end
            
            //==================================================================
            // WRITE_ADDR State - Accept address
            //==================================================================
            WRITE_ADDR: begin
                awready <= 1'b1;    // Ready to accept address
                
                if (awready && awvalid) begin
                    awready <= 1'b0;
                end
            end
            
            //==================================================================
            // WRITE_DATA State - Accept data and write to memory
            //==================================================================
            WRITE_DATA: begin
                wready <= 1'b1;     // Ready to accept data
                
                if (wready && wvalid) begin
                    // Write to memory with byte enables
                    if (wstrb[0]) memory[write_word_addr][7:0]   <= wdata[7:0];
                    if (wstrb[1]) memory[write_word_addr][15:8]  <= wdata[15:8];
                    if (wstrb[2]) memory[write_word_addr][23:16] <= wdata[23:16];
                    if (wstrb[3]) memory[write_word_addr][31:24] <= wdata[31:24];
                    
                    wready <= 1'b0;
                end
            end
            
            //==================================================================
            // WRITE_RESP State - Send response
            //==================================================================
            WRITE_RESP: begin
                bresp  <= 2'b00;    // OKAY response
                bvalid <= 1'b1;     // Response valid
                
                if (bvalid && bready) begin
                    bvalid <= 1'b0;
                end
            end
            
            default: begin
                awready <= 1'b0;
                wready  <= 1'b0;
                bvalid  <= 1'b0;
            end
        endcase
    end
end

//==============================================================================
// Read Path State Register - Sequential Logic
//==============================================================================
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        read_state <= IDLE;
        read_addr_reg <= 32'h0;
    end else begin
        read_state <= next_read_state;
        
        // Capture read address when it arrives
        if (read_state == IDLE && arvalid) begin
            read_addr_reg <= araddr;
        end
    end
end

//==============================================================================
// Read Path Next State Logic - Combinational
//==============================================================================
always @(*) begin
    next_read_state = read_state;
    
    case (read_state)
        //======================================================================
        // IDLE - Wait for read address
        //======================================================================
        IDLE: begin
            if (arvalid) begin
                next_read_state = READ_ADDR;
            end
        end
        
        //======================================================================
        // READ_ADDR - Accept read address
        //======================================================================
        READ_ADDR: begin
            if (arvalid && arready) begin
                next_read_state = READ_DATA;
            end
        end
        
        //======================================================================
        // READ_DATA - Fetch from memory and send to master
        //======================================================================
        READ_DATA: begin
            if (rvalid && rready) begin
                next_read_state = IDLE;
            end
        end
        
        default: begin
            next_read_state = IDLE;
        end
    endcase
end

//==============================================================================
// Read Path Output Logic
//==============================================================================
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        arready <= 1'b0;
        rdata   <= 32'h0;
        rresp   <= 2'b00;
        rvalid  <= 1'b0;
    end else begin
        case (read_state)
            //==================================================================
            // IDLE State
            //==================================================================
            IDLE: begin
                arready <= 1'b0;
                rvalid  <= 1'b0;
            end
            
            //==================================================================
            // READ_ADDR State - Accept address
            //==================================================================
            READ_ADDR: begin
                arready <= 1'b1;    // Ready to accept address
                
                if (arready && arvalid) begin
                    arready <= 1'b0;
                end
            end
            
            //==================================================================
            // READ_DATA State - Send data from memory
            //==================================================================
            READ_DATA: begin
                rdata  <= memory[read_word_addr];  // Fetch from memory
                rresp  <= 2'b00;                   // OKAY response
                rvalid <= 1'b1;                    // Data valid
                
                if (rvalid && rready) begin
                    rvalid <= 1'b0;
                end
            end
            
            default: begin
                arready <= 1'b0;
                rvalid  <= 1'b0;
            end
        endcase
    end
end

//==============================================================================
// Initialize memory to zero (for simulation)
//==============================================================================
integer i;
initial begin
    for (i = 0; i < MEM_DEPTH; i = i + 1) begin
        memory[i] = 32'h0;
    end
end

endmodule  // axi_slave