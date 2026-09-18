

# IC3.IE Tutorial: Building the Next Generation of Chips with GenAI

Welcome to the IC3.IE tutorial on integrating Large Language Models (LLMs) into the hardware design, synthesis, and verification lifecycle. In this tutorial, we will use an LLM to design an integer square root module, simulate it, optimize its area, and verify its coverage using industry-standard open-source tools.

## Environment Setup

Before we begin, ensure your system has the required open-source hardware tools installed: **Yosys** (synthesis), **Icarus Verilog** & **Verilator** (simulation), and **Cocotb** (Python-based verification).

### macOS

Open your terminal and run:

```bash
# Install hardware tools via Homebrew
brew install yosys icarus-verilog verilator

# Install Python verification libraries
pip install pytest cocotb

```

### Ubuntu / Windows Subsystem for Linux (WSL)

Open your terminal and run:

```bash
# Install hardware tools via APT
sudo apt update
sudo apt install yosys icarus-verilog verilator gtkwave

# Install Python verification libraries
pip install pytest cocotb

```
---
# Module 1: Design Generation & Synthesis Optimization
---

## Preparing for Synthesis

To synthesize our hardware design and calculate its physical area, we need a standard cell library.

1. Download the `gscl45nm.lib` (Generic Standard Cell Library, 45nm).
2. Download the baseline testbench provided for this tutorial: `problem1_tb.v`.
3. Place both files in your working directory.

---
## 1.1 Basic design generation using LLMs 

Select two LLMs. Copy and paste the following prompt into the LLM:

> **Prompt for LLM:**
> Write a synthesizable combinational Verilog module named `signed_isqrt` to compute the integer square root of $x$, where $x$ is an input signed 16-bit integer and the output $y$ is an unsigned 8-bit integer.
> **Specifications:**
> * `x`: Signed 16-bit input representing the value for integer square root computation (operational range: -32,768 to +32,767). Negative values should be handled as special cases and output 0.
> * `y`: Unsigned 8-bit output containing the computed integer square root value (operational range: 0 to 181 for valid positive inputs, 0 for negative inputs).
  

Save the generated Verilog code into a file named `signed_isqrt.v`.

Before synthesizing, we must ensure the LLM's design is functionally correct. We will use Verilator to compile and run the provided testbench against the generated design.

Run the following commands in your terminal:

```bash
# Compile the design and testbench
verilator -Wno-LATCH -Wno-WIDTH --binary --top-module signed_isqrt_tb problem1_tb.v signed_isqrt.v

# Execute the compiled simulation
./obj_dir/Vsigned_isqrt_tb

```

Inspect the out, and make sure everything is marked "SUCCESS".

**Iterative Debugging (manual Agentic flow for generation):** 

If the testbench reports failures, copy the terminal errors and paste them back into the LLM. Ask it to analyze the failure and provide a corrected `signed_isqrt.v` file. Repeat this until the testbench prints `SUCCESS`.

---
## 1.2 LLM-based PPA quality

Once the design is functionally correct, we will synthesize it using **Yosys** to map the behavioral Verilog to actual logic gates and measure its silicon area.

1. Create a script file named `synth.ys` and add the following Yosys commands:
```tcl
# Read the design file
read_verilog signed_isqrt.v

# Check design hierarchy
hierarchy -check -top signed_isqrt

# Generic synthesis and optimization
proc; opt; opt; techmap; opt

# Map flip-flops and logic to the 45nm library
dfflibmap -liberty gscl45nm.lib
abc -liberty gscl45nm.lib

# Generate statistics (Area)
stat -liberty gscl45nm.lib

# Write out the synthesized netlist
write_verilog signed_isqrt_syn.v

```


2. Run the script:
```bash
yosys -s synth.ys

```


3. Look at the terminal output for the `Chip area` statistic.

4. Repeat steps using the design from the second LLM and contrast the design area

---
   
## 1.3 LLM-based synthesis script

1. Select at least two LLMs: Claude, Gemini, ChatGPT, etc

2. Prompt the LLM: 
Generate a Yosys synthesis script to aggressively optimize the area of module named signed_isqrt.v in the design file signed_isqrt.v using the library gscl45nm.lib

3. Save the script as script1.ys

4. Run the synthesis tool using the library  and identify the total design area
yosys -s script1.ys

5. Compare the design area to the output from  1.2. Do you see improvement?

6. Repeat using the second LLM

---
##  1.4 Prompting with CoT for PPA optimization
 
Go back to the LLM and prompt:
> Here is my working Verilog code and design area. Optimize the algorithm to use fewer hardware resources (smaller area) while maintaining functional correctness

Save your code, re-verify with Verilator (1.1), and re-run Yosys (1.2) to see how much the LLM reduced your design area!

Try various prompting and CoT strategies to further reduce the area, until you cannot get further improvements. For example, try

> You are a hardware synthesis and optimization expert. Your goal is to optimize the provided Verilog code to minimize design area (LUTs, registers, and gate count) without changing its functional behavior.
> 
> Follow these steps strictly before writing any modified code:
>
>  Resource Identification: Analyze the current code and list every hardware resource it will infer (e.g., how many adders, multipliers, comparators, and registers of what bit-widths).
>
> Resource Sharing Analysis: Identify operations that do not happen simultaneously. Can we reuse a single adder or multiplier across different FSM states using a multiplexer?
>
> Bit-Width Pruning: Look at every register, counter, and wire. Are there variables where the maximum possible value is smaller than the allocated bit-width?
>
> Logic Simplification: Identify redundant states in the FSM, unused default branches, or mathematical expressions that can be simplified using boolean algebra.
>
> Optimized Verilog: Rewrite the Verilog code incorporating all the area-saving strategies identified above. Include comments explaining where resources were shared.
>
> Explain how the changes you made the code map into various optimizations

Replace your code, re-verify with Verilator (1.1), and re-run Yosys (1.2) to see how much the LLM reduced your design area!

## 1.5 Agentic PPA optimization

This exercise requires integration of a coding agent in your IDE environment.

Prompt the Agentic coding as follows

> You are a hardware synthesis and optimization expert. 
> Write a synthesizable combinational Verilog module named signed_isqrt to compute the integer square root of x, where x is an input signed 16-bit integer and the output y is an unsigned 8-bit integer.Specifications:
> x: Signed 16-bit input representing the value for integer square root computation (operational range: -32,768 to +32,767). Negative values should be handled as special cases and output 0.
> y: Unsigned 8-bit output containing the computed integer square root value (operational range: 0 to 181 for valid positive inputs, 0 for negative inputs).


> Optimize the provided Verilog code to minimize design area without changing its functional behavior.

> Ensure the design works with no errors with verilator using the testbench  Problem1_tb.v

> Synthesis the design using Yosys and the lib file gscl45nm.lib, use synthesis commands that minimize area as much as possible

> Extract the area metrics from the yosys output log
> iterate through the design improving its area and the synthesis script until it is no longer possible 

---
# Module 2: Design Verification

## 2.1 Generating test benches from  Natural Specs 

1. Prompt an LLM:

Generate a Verilog testbench ventilator_ctrl_tb  for a design with the following specifications. Assume the top module of the design under test has the name ventilator_ctrl. 

The Medical Ventilator Pressure Controller (VPC) protects patient safety by continuously monitoring airway pressure and actuating an emergency relief valve whenever measured pressure exceeds safe medical limits.

**Interface Description**

| Signal Name | Direction | Bit Width | Type | Description |
| --- | --- | --- | --- | --- |
| `clk` | Input | 1 | Wire | Master system clock signal. |
| `rst_n` | Input | 1 | Wire | Active-low asynchronous global reset. |
| `pressure_in` | Input | 8 | Unsigned Wire | Current measured airway pressure in $\text{cmH}_2\text{O}$ (range: 0 to 255). |
| `valve_open` | Output | 1 | Register | Relief valve actuation signal (1 = Open, 0 = Closed). |

**Functional Requirements**

* **REQ-1 (Active-Low Reset):** When `rst_n` is driven low (`0`), `valve_open` must immediately deassert to `0` (closed valve), overriding any pressure conditions.
* **REQ-2 (Overpressure Relief):** When `pressure_in` strictly exceeds the safe maximum threshold ($P_{max} = 100\text{ cmH}_2\text{O}$), the module must assert `valve_open` high (`1`) to release pressure.
* **REQ-3 (Normal Operation):** When `pressure_in` is less than or equal to $100\text{ cmH}_2\text{O}$, the module must maintain `valve_open` low (`0`).
* **REQ-4 (Data Representation):** The input `pressure_in` operates as an unsigned 8-bit bus, accommodating pressure measurements up to $255\text{ cmH}_2\text{O}$.

**Timing & Output Latency**

* **REQ-5 (Synchronous Registration):** Pressure evaluation occurs on the rising edge of `clk`. Output state transitions (`valve_open`) manifest with exactly **1 clock cycle** of latency relative to changes on `pressure_in`.

Save the LLM outcome as ventilator_ctrl_tb.v

2. Download the synthesizable module ventilator_ctrl.v
3.  Compile Using Verilator
 verilator -Wno-LATCH -Wno-WIDTH --binary --coverage --top-module ventilator_ctrl_tb ventilator_ctrl_tb.v ventilator_ctrl.v
4. Run and check the output
5. Generate the coverage report
 verilator_coverage --annotate coverage_out coverage.dat
6. Inspect coverage_out/ventilator_ctrl.v to check execution counts per line (lines with C0 indicate unexecuted branches).

   
---
## 2.2 Verification using Verilog + Python 

### Step 1 — Prompt the LLM to write the Verilog testbench

> Design a synthesizable Verilog module named `crc8` that computes an
> 8-bit CRC over a stream of bytes, one byte per clock cycle.
>
> **Algorithm**: Standard CRC-8 (as catalogued by the CRC RevEng
> database), defined by:
> - Polynomial: `0x07` (representing `x^8 + x^2 + x + 1`, top bit
>   implicit)
> - Initial value: `0x00`
> - Input reflection: none (process each byte MSB-first)
> - Output reflection: none
> - Final XOR: none
> - Reference self-check: `CRC8("123456789") == 0xF4`
>
> **Interface**:
> ```
> module crc8 (
>     input        clk,
>     input        rst_n,     // active-low synchronous reset
>     input        valid,     // pulse: data_in holds a new byte this cycle
>     input  [7:0] data_in,   // next byte of the message
>     output [7:0] crc_out    // running CRC value (registered)
> );
> ```
>
> **Behavior**:
> - On `rst_n == 0`, the internal CRC register synchronously clears to
>   `0x00`.
> - On each rising edge of `clk` where `valid == 1`, fold `data_in` into
>   the running CRC register using the standard bit-serial CRC update
>   (MSB-first, 8 steps, XOR with the polynomial `0x07` whenever the
>   top bit of the shifted register disagrees with the incoming data
>   bit), fully unrolled into one combinational function evaluated once
>   per byte. `crc_out` is the registered result.
> - When `valid == 0`, `crc_out` holds its previous value.
> - To checksum a whole message: reset once, then present each byte for
>   one cycle each, in order. After the last byte's cycle, `crc_out` is
>   the final checksum.
>
> **Required test coverage** (used to shape the verification, regardless
> of which testbench style is used):
> 1. Reset value is `0x00`.
> 2. Standard check vector `"123456789"` → `0xF4`.
> 3. Empty message (no bytes) leaves `crc_out` at `0x00`.
> 4. Exhaustive sweep of all 256 single-byte messages.
> 5. A batch of randomized multi-byte messages (varying length).
> 6. Back-to-back messages with a reset between them, to confirm no
>    state leaks across messages.

```
Using the CRC-8 functional specification above, write a self-checking
*stimulus* Verilog testbench named crc8_tb.v for a DUT module `crc8`
(interface as specified). Requirements:

- Do NOT compute or check any CRC value inside this Verilog file — no
  golden-model logic in Verilog at all. This testbench's only job is to
  drive the DUT and record what it produces.
- Generate a 10ns-period clock and implement task `reset_dut` and task
  `send_byte(byte)` that pulses `valid` for exactly one cycle per byte,
  matching the interface timing in the spec.
- Implement the 6 required test-coverage cases from the spec as a
  sequence of messages (standard check vector, empty message, all 256
  single-byte messages, ~40 randomized multi-byte messages using
  $random with a fixed seed for reproducibility, and a few fixed
  back-to-back messages).
- For every message: reset, stream the message in, then write one line
  to an output file `crc8_verilog_results.txt` of the form
  `<message_as_hex>,<captured_crc_out_as_hex>` (empty hex string for the
  empty message).
- Use `$fopen`/`$fwrite`/`$fclose` and call `$finish` at the end.
```

### Step 2 — Prompt the LLM to write the synthesizable DUT

```
Using the CRC-8 functional specification above, write the synthesizable
Verilog module crc8.v implementing exactly the described interface and
behavior:
- Fully combinational per-byte CRC update (8 bit-serial XOR/shift steps
  unrolled into one always @(*) block, MSB-first, polynomial 0x07),
  registered once per clock cycle on `posedge clk`.
- Synchronous active-low reset (`rst_n`) clearing the register to 0x00.
- Register updates only when `valid` is high; holds otherwise.
- No latches, no combinational output path bypassing the register —
  crc_out must be a registered output.
```

### Step 3 — Prompt the LLM to write the Python golden-model checker

```
Write a standalone Python script check_crc8_golden.py (no cocotb, no
simulator dependency) that:

- Reads crc8_verilog_results.txt, where each line is
  <message_hex>,<captured_crc_hex> (message_hex may be empty).
- Uses the third-party `crc8` PyPI package as the golden reference
  (pip install crc8) to compute the expected CRC-8 of each message —
  do not hand-roll the CRC polynomial math in Python; that would defeat
  the purpose of using an independent reference.
- For every line, prints PASS/FAIL comparing the DUT's captured value
  against the golden value.
- Prints a final TOTAL/PASS/FAIL summary line.
- Exits with code 0 if all rows match, exits 1 (with a list of failing
  rows) if any mismatch.
```

Install the golden-model dependency once:

```bash
pip install crc8
```

### Step 4 — Run Verilator and produce the final validation output

Verilator can compile the self-contained Verilog testbench directly into
a standalone executable — no separate C++ harness is needed here because
`crc8_tb.v` already drives itself with an `initial` block and `$finish`.

```bash
# Build crc8.v + crc8_tb.v into a Verilator binary.
# --timing is required because crc8_tb.v uses `#5` clock delays.
# -Wno-fatal keeps lint warnings (e.g. missing timescale) from
# stopping the build; they don't affect functional correctness here.
verilator --binary --timing -Wno-fatal \
    --top-module crc8_tb \
    -o crc8_tb_sim \
    --Mdir obj_dir_crc8_tb \
    crc8.v crc8_tb.v

# Run the simulation. This produces crc8_verilog_results.txt.
./obj_dir_crc8_tb/crc8_tb_sim

# Grade the captured results against the Python golden model.
python3 check_crc8_golden.py
```



---
## 2.3 Verification using Python and Cocotb

Same spec, same DUT. This time the testbench driving the DUT and the
golden-model comparison both live in one Python file executed by cocotb,
with no intermediate results file.

### Step 1 — Prompt the LLM to write the cocotb testbench + golden model

```
Using the CRC-8 functional specification above, write a cocotb testbench
test_crc8.py for a DUT module `crc8` (interface as specified). Requirements:

- Golden reference model: a small function golden_crc8(message: bytes) ->
  int that uses the third-party `crc8` PyPI package (pip install crc8)
  to compute the expected checksum. Do not hand-roll the CRC polynomial
  math — the golden model must be independent of however the DUT is
  implemented.
- Helper coroutines: start_clock(dut) (10ns period), reset_dut(dut)
  (drive rst_n low then high, synchronized to the clock), send_byte(dut,
  byte) (drive data_in + pulse valid for one clock cycle), and
  send_message(dut, message: bytes) (send every byte of a message, then
  wait one extra idle clock cycle so the DUT's registered crc_out has
  settled before the caller reads it — reading crc_out on the same
  RisingEdge that triggers the update races the simulator's non-blocking
  assignment region).
- Implement one @cocotb.test() per required test-coverage case from the
  spec: reset value, standard check vector "123456789" == 0xF4, empty
  message, exhaustive sweep of all 256 single-byte messages, ~40
  randomized multi-byte messages (use Python's random module with a
  fixed seed for reproducibility), and back-to-back messages with resets
  between them to confirm no state leaks.
- Every test must assert dut.crc_out.value against golden_crc8(...) for
  the same message, with a clear failure message showing both values in
  hex on mismatch.
```

### Step 2 — Prompt the LLM to write the synthesizable DUT

Identical to Tutorial 1, Step 2 — the DUT is verification-style-agnostic:

```
Using the CRC-8 functional specification above, write the synthesizable
Verilog module crc8.v implementing exactly the described interface and
behavior:
- Fully combinational per-byte CRC update (8 bit-serial XOR/shift steps
  unrolled into one always @(*) block, MSB-first, polynomial 0x07),
  registered once per clock cycle on `posedge clk`.
- Synchronous active-low reset (`rst_n`) clearing the register to 0x00.
- Register updates only when `valid` is high; holds otherwise.
- No latches, no combinational output path bypassing the register —
  crc_out must be a registered output.
```

(If you already built `crc8.v` in Tutorial 1, reuse it as-is — it's the
same DUT regardless of which testbench style verifies it.)

### Step 3 — Prompt the LLM to write the cocotb + Verilator runner script

```
Write a Python script run_crc8_tb_verilator.py that uses cocotb's
cocotb_tools.runner API to:
- Get a Verilator runner via get_runner("verilator").
- Build crc8.v with hdl_toplevel="crc8", into build_dir
  "sim_build_crc8_verilator", with timescale=("1ns", "1ps") (Verilator
  needs an explicit timescale since crc8.v has no `timescale directive
  and the testbench clock period is specified in nanoseconds).
- Run runner.test() with hdl_toplevel="crc8", test_module="test_crc8",
  the same build_dir, test_dir set to the script's own directory, and
  the same timescale.
```

### Step 4 — Run Verilator + cocotb and produce the final validation output

```bash
pip install cocotb crc8
python3 run_crc8_tb_verilator.py
```



---

## 2.4 UVM-based Verification 

1. First install the UVM library
> git clone https://github.com/chipsalliance/uvm-verilator.git uvm-1800.2
> 
> export UVM_HOME=$(pwd)/uvm-1800.2/src

2. Prompt the LLM to create a systemverilog-based UVM Testbench for the design with the  specifications given below. The test bench will be simulated using Verilator 
(copy here the specifications from Demo 1.1)​

3. Save the UVM test bench as tb_uvm.sv

4. Compile the design and the testbench using Verilator

> verilator -Wno-fatal --binary -j $(sysctl -n hw.ncpu) --coverage \
  --top-module tb_top \
  +incdir+$UVM_HOME \
  +define+UVM_NO_DPI \
  $UVM_HOME/uvm_pkg.sv \
  ventilator_ctrl.v tb_uvm.sv

5. Execute
> ./obj_dir/Vtb_top +UVM_TESTNAME=ventilator_test

6. Check the output and ensure an all PASS, and for coverage

> verilator_coverage --annotate coverage_out coverage.dat

7. Inspect coverage_out/ventilator_ctrl.v to check execution counts per line (lines with C0 indicate unexecuted branches).

--- 
## 2.5 Testbench generation with chain of thought

You are an expert hardware verification engineer. Given the natural-language hardware specification below, generate a complete SystemVerilog/Verilog testbench for the DUT.

Natural-Language Specification:

Write a combinational Verilog module named signed_isqrt to compute the integer square root of 
x, where  x is an input signed 16-bit integer and the output 
y is an unsigned 8-bit integer. Specifications:

x: Signed 16-bit input representing the value for integer square root computation (operational range: -32,768 to +32,767). Negative values should be handled as special cases and output 0.
y: Unsigned 8-bit output containing the computed integer square root value (operational range: 0 to 181 for valid positive inputs, 0 for negative inputs).


Use the following structured verification process:

1. Extract Verification Requirements
Identify all inputs, outputs, interfaces, clock/reset behavior, timing requirements, functional behavior, state transitions, constraints, error conditions, and corner cases.
Convert each requirement into an explicit, testable verification requirement.
Do not invent behavior that is not supported by the specification.
2. Define Expected Behavior
Develop a functional reference model/golden model that independently represents what the DUT should produce.
Determine what outputs should be checked for each input sequence.
Define expected behavior for normal operation, boundary conditions, error cases, and corner cases.
Explicitly identify any ambiguous parts of the specification.
3. Generate Test Stimulus

Create a combination of:

Directed tests for important requirements and known scenarios.
Constrained-random tests to explore a wider input space.
Boundary-value and corner-case tests.
Reset and initialization tests.
Back-to-back and timing-sensitive transactions.
Illegal or error-condition tests when specified.
4. Generate Checkers
Create a scoreboard/reference-model mechanism that compares DUT outputs against expected results.
Generate SystemVerilog assertions for temporal, protocol, and safety requirements.
Check for incorrect outputs, missing responses, unexpected responses, protocol violations, and incorrect state transitions.
Every important specification requirement should have at least one corresponding checking mechanism.
5. Generate Functional Coverage

Create a coverage model that measures whether the important requirements have actually been exercised:

Input-value and boundary coverage.
Functional scenario coverage.
State and state-transition coverage.
Protocol and transaction coverage.
Error and corner-case coverage.
Cross coverage for important combinations of conditions.
Assertion coverage where appropriate.

Also identify coverage holes and generate additional stimulus when necessary to close them.

6. Verification Feedback Loop

Treat testbench generation as an iterative process:

Generate → Compile → Simulate → Check → Measure Coverage → Improve

After each simulation:

Analyze compilation errors and warnings.
Analyze assertion failures and scoreboard mismatches.
Identify uncovered requirements and scenarios.
Modify or add tests to address failures and coverage gaps.
Avoid generating redundant tests that do not improve verification coverage.
7. Requirement-to-Test Traceability

Produce a table mapping:

Natural-Language Requirement → Test Scenario → Stimulus → Checker/Assertion → Coverage Metric

This ensures that every important specification requirement is both tested and measured.

8. Final Output

Generate:

The complete Verilog/SystemVerilog testbench.
The functional reference model.
Assertions and checkers.
Functional coverage definitions.
Directed and constrained-random test scenarios.
A requirement-to-verification traceability table.
A list of assumptions or ambiguities in the specification.

Primary objective: Generate a testbench that verifies functional correctness and specification compliance, not merely one that produces high code coverage. The testbench should maximize meaningful bug detection and coverage while minimizing redundant simulation.



--- 

## 2.6 Improving test coverage with Agentic flows

You are hardware verification engineer expert. 
- I created the Verilog testbench problem1_tb.v with top module problem1_tb.v to test the design signed_isqrt.v
- Use verilator to calculate the coverage
- analyze the coverage report 
- modify the testbench to improve its coverage
- keep on iterating until it is not possible to increase coverage


