

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

## 1. Design Verification & Coverage

Testbenches rarely test every possible edge case on the first try. We will use Verilator's coverage tools to see what lines of code the testbench missed.

1. Run Verilator with coverage flags enabled:
```bash
verilator -Wno-LATCH -Wno-WIDTH --binary -j 0 --coverage --coverage-line --coverage-toggle --top-module signed_isqrt_tb problem1_tb.v signed_isqrt.v

./obj_dir/Vsigned_isqrt_tb

verilator_coverage --annotate report coverage.dat

```


2. Check the generated `report/` directory to see which lines of Verilog were not triggered.
**LLM Prompt (manual Agentic flow for coverage improvement):**
3. Ask the LLM to write additional Verilog test cases targeting the uncovered lines, append them to `problem1_tb.v`, and re-test to achieve 100% coverage.

---

## 2. Advanced Verification: Python & Cocotb

Writing testbenches in pure Verilog can be tedious. Cocotb allows us to write hardware testbenches using Python, taking advantage of Python's math libraries for reference models.

Ask the LLM to generate the Python environment:

> **Prompt for LLM:**
> Write a Python testbench using cocotb for a combinational Verilog module named `signed_isqrt` to compute the integer square root of $x$, where $x$ is an input signed 16-bit integer and the output $y$ is an unsigned 8-bit integer. Include directed edge cases and randomized testing. Also, create the standard cocotb Makefile for the Icarus Verilog simulator.

**Execution:**

1. Save the Python code to `test_signed_isqrt.py`.
2. Save the Makefile code to `Makefile`. *(Ensure the `MODULE` and `TOPLEVEL` variables in the Makefile correctly match your filenames).*
3. Run the simulation using Icarus Verilog:
```bash
make SIM=icarus

```


4. If there are any `0.00ns ERROR gpi` failures, copy the traceback to the LLM and ask it to fix any port naming mismatches!

---

