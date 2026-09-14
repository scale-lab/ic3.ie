`timescale 1ns / 1ps

module signed_isqrt_tb;

    // Inputs
    reg signed [15:0] in_0;

    // Outputs
    wire unsigned [7:0] out;

    // Expected output for verification
    reg unsigned [7:0] expected_out;
    
    // Loop variable
    integer i;

    // Instantiate the Unit Under Test (UUT)
    signed_isqrt uut (
        .x(in_0), 
        .y(out)
    );

initial begin
    // Specifies the name of the file where waveform data will be saved
    $dumpfile("simulation_results.vcd");
    
    // 0 means dump all variables in this module and any sub-modules instantiated below it
    $dumpvars(0, signed_isqrt_tb);
end


    // Verification Task
    task check_output;
        begin
            #1; // Wait for combinational settling
            // Behavioral golden reference model
            if (in_0 < 0) begin
                expected_out = 8'sd0;
            end else begin
                // $sqrt returns a real, $rtoi converts to integer (truncates)
                expected_out = $rtoi($sqrt(in_0));
            end

            // Compare UUT output with expected output
            if (out !== expected_out) begin
                $display("ERROR at time %0t: In = %d | Out = %d (Expected = %d)", 
                          $time, in_0, out, expected_out);
            end else begin
                $display("SUCCESS: In = %d | Out = %d", in_0, out);
            end
        end
    endtask

    initial begin
        $display("Starting Integer Square Root Testbench...");
        $display("-------------------------------------------");

        // --- TEST CASE 2: Zero & Low Values ---
        $display("\nTesting Zero and Low Values:");
        in_0 = 0;      check_output();
        in_0 = 1;      check_output();
        in_0 = 2;      check_output();
        in_0 = 3;      check_output();
        in_0 = 4;      check_output();

        // --- TEST CASE 3: Perfect Squares ---
        $display("\nTesting Perfect Squares:");
        in_0 = 16;     check_output();
        in_0 = 64;     check_output();
        in_0 = 10000;  // 100^2
        check_output();
        in_0 = 32400;  // 180^2
        check_output();

        // --- TEST CASE 4: Truncation / Non-Perfect Squares ---
        $display("\nTesting Non-Perfect Squares (Truncation Check):");
        in_0 = 15;     // Should truncate down to 3
        check_output();
        in_0 = 24;     // Should truncate down to 4
        check_output();
        in_0 = 32760;  // Should truncate down to 180
        check_output();

        // --- TEST CASE 5: Positive Boundaries ---
        $display("\nTesting Max Positive Range:");
        in_0 = 32767;  // Max signed 16-bit positive boundary
        check_output();

        // --- TEST CASE 6: Exhaustive/Random Sweep ---
        $display("\nTesting Dynamic Sweep:");
        for (i = 0; i <= 200; i = i + 1) begin
            in_0 = i;
            check_output();
        end

        $display("-------------------------------------------");
        $display("Simulation Completed.");
        $finish;
    end
      
endmodule
