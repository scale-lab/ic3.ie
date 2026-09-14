`include "uvm_macros.svh"
import uvm_pkg::*;

// ============================================================================
// 1. INTERFACE
// ============================================================================
interface ventilator_if(input logic clk);
  logic       rst_n;
  logic [7:0] pressure_in;
  logic       valve_open;
endinterface

// ============================================================================
// 2. TRANSACTION ITEM
// ============================================================================
class pressure_item extends uvm_sequence_item;
  rand bit [7:0] pressure_val;
  bit            valve_open;

  `uvm_object_utils_begin(pressure_item)
    `uvm_field_int(pressure_val, UVM_ALL_ON)
    `uvm_field_int(valve_open,   UVM_ALL_ON)
  `uvm_object_utils_end

  function new(string name = "pressure_item");
    super.new(name);
  endfunction
endclass

// ============================================================================
// 3. SEQUENCE
// ============================================================================
class ventilator_sequence extends uvm_sequence #(pressure_item);
  `uvm_object_utils(ventilator_sequence)

  function new(string name = "ventilator_sequence");
    super.new(name);
  endfunction

  task body();
    pressure_item item;

    // Test 1: Normal Pressure (50 cmH2O) -> Valve should stay CLOSED
    item = pressure_item::type_id::create("item");
    start_item(item);
    item.pressure_val = 8'd50;
    finish_item(item);

    // Test 2: Overpressure (120 cmH2O) -> Valve should OPEN
    item = pressure_item::type_id::create("item");
    start_item(item);
    item.pressure_val = 8'd120;
    finish_item(item);

    // Test 3: Boundary Pressure (100 cmH2O) -> Valve should stay CLOSED
    item = pressure_item::type_id::create("item");
    start_item(item);
    item.pressure_val = 8'd100;
    finish_item(item);
  endtask
endclass

// ============================================================================
// 4. DRIVER
// ============================================================================
class ventilator_driver extends uvm_driver #(pressure_item);
  `uvm_component_utils(ventilator_driver)
  virtual ventilator_if vif;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual ventilator_if)::get(this, "", "vif", vif))
      `uvm_fatal("DRV", "Could not get virtual interface handle from config_db!")
  endfunction

  task run_phase(uvm_phase phase);
    vif.rst_n <= 0;
    vif.pressure_in <= 0;
    repeat (2) @(posedge vif.clk);
    vif.rst_n <= 1;

    forever begin
      seq_item_port.get_next_item(req);
      vif.pressure_in <= req.pressure_val;
      @(posedge vif.clk);
      seq_item_port.item_done();
    end
  endtask
endclass

// ============================================================================
// 5. MONITOR
// ============================================================================
class ventilator_monitor extends uvm_monitor;
  `uvm_component_utils(ventilator_monitor)
  virtual ventilator_if vif;
  uvm_analysis_port #(pressure_item) ap;

  function new(string name, uvm_component parent);
    super.new(name, parent);
    ap = new("ap", this);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual ventilator_if)::get(this, "", "vif", vif))
      `uvm_fatal("MON", "Could not get virtual interface handle from config_db!")
  endfunction

  task run_phase(uvm_phase phase);
    forever begin
      @(posedge vif.clk);
      if (vif.rst_n) begin
        pressure_item item = pressure_item::type_id::create("item");
        item.pressure_val = vif.pressure_in;
        
        @(posedge vif.clk); // 1-cycle latency alignment for registered output
        item.valve_open   = vif.valve_open;
        
        ap.write(item);
      end
    end
  endtask
endclass

// ============================================================================
// 6. SCOREBOARD
// ============================================================================
class ventilator_scoreboard extends uvm_scoreboard;
  `uvm_component_utils(ventilator_scoreboard)
  uvm_analysis_imp #(pressure_item, ventilator_scoreboard) item_imp;

  function new(string name, uvm_component parent);
    super.new(name, parent);
    item_imp = new("item_imp", this);
  endfunction

  function void write(pressure_item item);
    bit expected_valve = (item.pressure_val > 8'd100);
    if (item.valve_open == expected_valve) begin
      `uvm_info("SCOREBOARD", $sformatf("PASS: Pressure=%0d cmH2O | Valve Open=%0b (Expected=%0b)", 
                item.pressure_val, item.valve_open, expected_valve), UVM_LOW)
    end else begin
      `uvm_error("SCOREBOARD", $sformatf("FAIL: Pressure=%0d cmH2O | Valve Open=%0b (Expected=%0b)", 
                 item.pressure_val, item.valve_open, expected_valve))
    end
  endfunction
endclass

// ============================================================================
// 7. AGENT
// ============================================================================
class ventilator_agent extends uvm_agent;
  `uvm_component_utils(ventilator_agent)
  ventilator_driver              driver;
  uvm_sequencer #(pressure_item) sequencer;
  ventilator_monitor             monitor;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    driver    = ventilator_driver::type_id::create("driver", this);
    sequencer = uvm_sequencer#(pressure_item)::type_id::create("sequencer", this);
    monitor   = ventilator_monitor::type_id::create("monitor", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    driver.seq_item_port.connect(sequencer.seq_item_export);
  endfunction
endclass

// ============================================================================
// 8. ENVIRONMENT
// ============================================================================
class ventilator_env extends uvm_env;
  `uvm_component_utils(ventilator_env)
  ventilator_agent      agent;
  ventilator_scoreboard scoreboard;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    agent      = ventilator_agent::type_id::create("agent", this);
    scoreboard = ventilator_scoreboard::type_id::create("scoreboard", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    agent.monitor.ap.connect(scoreboard.item_imp);
  endfunction
endclass

// ============================================================================
// 9. TEST
// ============================================================================
class ventilator_test extends uvm_test;
  `uvm_component_utils(ventilator_test)
  ventilator_env env;

  function new(string name = "ventilator_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    env = ventilator_env::type_id::create("env", this);
  endfunction

  task run_phase(uvm_phase phase);
    ventilator_sequence seq;
    phase.raise_objection(this);

    `uvm_info("TEST", "Starting Ventilator Test Sequence...", UVM_LOW)
    seq = ventilator_sequence::type_id::create("seq");
    seq.start(env.agent.sequencer);
    #40;

    phase.drop_objection(this);
  endtask
endclass

// ============================================================================
// 10. TESTBENCH TOP
// ============================================================================
module tb_top;
  bit clk = 0;
  always #5 clk = ~clk;

  ventilator_if vif(clk);

  ventilator_ctrl dut (
    .clk(clk),
    .rst_n(vif.rst_n),
    .pressure_in(vif.pressure_in),
    .valve_open(vif.valve_open)
  );

  initial begin
    uvm_config_db#(virtual ventilator_if)::set(null, "*", "vif", vif);
    run_test("ventilator_test");
  end
endmodule