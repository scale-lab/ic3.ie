// ventilator_ctrl.v
module ventilator_ctrl (
    input  wire       clk,
    input  wire       rst_n,
    input  wire [7:0] pressure_in, // Airway pressure in cmH2O
    output reg        valve_open   // Relief valve trigger
);
    localparam P_MAX = 8'd100;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valve_open <= 1'b0;
        end else begin
            valve_open <= (pressure_in > P_MAX);
        end
    end
endmodule
