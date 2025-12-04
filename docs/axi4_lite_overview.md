# AXI4-Lite Protocol – Conceptual Overview (Project Notes)

This document is meant to be a **practical explanation** of AXI4-Lite in the context of this project.  
It’s not a full replacement for the ARM specification, but it should be enough for someone to understand what I implemented, why I made certain choices, and how the design behaves in simulation.

---

## 1. What is AXI4-Lite?

AXI4-Lite is a **simplified, lightweight subset** of the AMBA AXI4 protocol. It is typically used for:
- Register interfaces
- Control/status blocks
- Configuration paths inside SoCs

Key differences compared to full AXI4:
- **No bursts** (only single beat transfers)
- **No IDs**, **no out-of-order completion**
- Simpler logic, lower resource usage

For this project, AXI4-Lite was a good fit because the goal was to:
- Design **clean, readable RTL**
- Focus on **correct handshake behavior**
- Implement a **memory-mapped slave** with predictable behavior

---

## 2. AXI4-Lite Channels Implemented

AXI4-Lite uses **five independent channels**. In this design, all five are fully implemented and used:

### 2.1 Write Address Channel (AW)

- Signals (typical):
  - `AWADDR`  – address of the write
  - `AWVALID` – master says address is valid
  - `AWREADY` – slave says it can accept the address

The master asserts `AWVALID` with a valid address, and the slave asserts `AWREADY` when it is ready to capture it. A successful handshake happens when both are high on the same clock edge.

### 2.2 Write Data Channel (W)

- Signals:
  - `WDATA`   – write data
  - `WSTRB`   – write strobes (byte enables)
  - `WVALID`  – master says data is valid
  - `WREADY`  – slave says it can accept the data

Address and data are **decoupled**: AXI4-Lite does not require them to appear in the same cycle. My implementation respects this by allowing AW and W to handshake in any valid order (with proper internal tracking).

### 2.3 Write Response Channel (B)

- Signals:
  - `BRESP`   – response code (`OKAY`, `SLVERR`, etc.)
  - `BVALID`  – slave says response is valid
  - `BREADY`  – master is ready to accept response

After the slave completes the write to memory, it returns a response. In this project, all successful transactions return `OKAY` (`2'b00`).

### 2.4 Read Address Channel (AR)

- Signals:
  - `ARADDR`  – address of the read
  - `ARVALID` – master says address is valid
  - `ARREADY` – slave says it can accept address

Same idea as AW channel, but for reads.

### 2.5 Read Data Channel (R)

- Signals:
  - `RDATA`   – read data from slave
  - `RRESP`   – read response (OKAY / error)
  - `RVALID`  – slave says data is valid
  - `RREADY`  – master ready to accept data

The slave provides the data and keeps `RVALID` high until the master asserts `RREADY` for one cycle to complete the transfer.

---

## 3. VALID / READY Handshake Rule

The core rule for all channels is:

> **Nothing happens until VALID and READY are both high on the same rising clock edge.**

Some important points I followed in the implementation:

- The **source** of the data (master for AW/W/AR, slave for B/R) drives `VALID`.
- The **sink** of the data (slave for AW/W/AR, master for B/R) drives `READY`.
- Data/control signals must be stable **while VALID=1** and until a handshake occurs.
- Multiple cycles of “waiting” are allowed:
  - `VALID=1, READY=0` → source is waiting
  - `VALID=0, READY=1` → sink is waiting
  - `VALID=1, READY=1` → transfer completes on that edge

In the code and waveforms, I made sure there are **no changes on payload signals** (`ADDR`, `DATA`, `RESP`) mid-handshake.

---

## 4. Design Decisions in This Project

### 4.1 4KB Memory-Mapped Slave

The slave implements a simple **4KB memory region**:

- Address range: effectively 0 to 4095 (depending on how many address bits are wired)
- Backed by an internal memory array (e.g. `reg [31:0] mem [0:1023]` if using word addressing)
- `WSTRB` is honored, so partial word writes are supported:
  - Each bit of `WSTRB` corresponds to one byte lane in `WDATA`.
  - If a bit in `WSTRB` is 0, that byte is not updated.

### 4.2 Independent FSMs for Master and Slave

Both master and slave are implemented with **independent finite state machines (FSMs)**. Conceptually:

**Master FSM responsibilities:**
- Drive write address → wait for handshake
- Drive write data → wait for handshake
- Wait for write response (`BVALID/BREADY`)
- Drive read address → wait for handshake
- Wait for read data (`RVALID/RREADY`)
- Sequence multiple transactions (back-to-back tests)

**Slave FSM responsibilities:**
- Accept address on AW/AR channels
- For writes:
  - Wait for both valid address and data
  - Perform memory write with `WSTRB` decoding
  - Assert `BVALID` and send `BRESP`
- For reads:
  - Latch address on AR handshake
  - Fetch memory data
  - Assert `RVALID` with `RDATA` and `RRESP`

The master and slave don’t “know” about each other’s internals—they only talk via the AXI4-Lite signals, which makes this a clean demonstration of **interface-based design**.

---

## 5. Write and Read Transaction Flow (Project Perspective)

### 5.1 Write Transaction (Typical Sequence)

1. **Address phase**
   - Master sets `AWADDR` and `AWVALID = 1`.
   - Slave eventually asserts `AWREADY = 1`.
   - On the cycle where both are 1 → address handshake completes.

2. **Data phase**
   - Master sets `WDATA`, `WSTRB` and `WVALID = 1`.
   - Slave asserts `WREADY = 1` when ready.
   - Handshake occurs on `WVALID && WREADY`.

3. **Response phase**
   - After processing the write, the slave asserts `BVALID` with `BRESP = OKAY`.
   - Master asserts `BREADY` when it is ready to accept the response.
   - Handshake on `BVALID && BREADY` completes the transaction.

In my waveforms, I specifically verified:
- Address and data do **not have to** be in the same cycle.
- Multiple writes can occur back-to-back.
- Response always matches the completion of the write.

### 5.2 Read Transaction (Typical Sequence)

1. **Address phase**
   - Master sets `ARADDR` and `ARVALID = 1`.
   - Slave asserts `ARREADY` to accept the address.
   - `ARVALID && ARREADY` completes address handshake.

2. **Data phase**
   - Slave reads from internal memory and places data on `RDATA`.
   - Slave asserts `RVALID` with `RRESP = OKAY`.
   - Master asserts `RREADY` once it can take the data.
   - `RVALID && RREADY` completes the read.

The project also checks **read-after-write correctness**:
- Write data to an address
- Read from the same address
- Compare read data with expected value

---

## 6. Verification Approach Used in This Project

Although this document is about the concept, it’s helpful to link it to how I verified the design:

- **Unit testbench** (`axi4_lite_master_simple_tb.v`):
  - Exercises basic write and read transactions.
  - Good for sanity checking the master behavior and simple slave responses.

- **Integration testbench** (`axi_integration_tb.v`):
  - Connects the master and slave.
  - Runs multiple transactions close together.
  - Shows end-to-end behavior on waveforms.

- **Comprehensive testbench** (`axi_comprehensive_tb.v`):
  - Runs a directed suite of **45 tests**.
  - Tracks:
    - `test_count`
    - `pass_count`
    - `fail_count`
  - Final waveform clearly indicates:  
    `TESTS = 45, PASS = 45, FAIL = 0`

The idea was to go beyond “it works for one example” and instead show **systematic verification** of the protocol behavior.

---

## 7. Limitations & Possible Extensions

To keep the project focused and manageable, a few things were intentionally **not** implemented:

- No error injection (e.g. SLVERR/DECERR responses)
- No wait-state modeling beyond basic READY control
- No support for multiple outstanding transactions
- No burst transfers (AXI4-Lite doesn’t require them anyway)

If I extend this project in the future, possible directions are:

- Add configurable error responses for certain address ranges
- Add randomized wait states on the slave side to stress the handshake
- Introduce a coverage model or migrate to a SystemVerilog/UVM environment
- Extend to full AXI4 with bursts and IDs

---

## 8. Why This Project Matters (Personally)

From a learning point of view, this project forced me to:

- Think in terms of **interfaces and protocols**, not just signals
- Be disciplined about **VALID/READY timing**
- Keep master and slave logic **modular and independent**
- Use waveforms and regression tests as **evidence**, not just intuition

It’s also the kind of design that maps directly to what is used inside real SoCs for register interfaces and control paths, which is why I chose to implement and verify AXI4-Lite in this level of detail.

