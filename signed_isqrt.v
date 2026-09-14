module signed_isqrt (
    input  signed [15:0] x,
    output        [7:0]  y
);

    wire [14:0] xp = x[15] ? 15'd0 : x[14:0];

    // Bit 7: q=0, delta = 16384
    wire        b7  = (xp >= 15'd16384);
    wire [14:0] r7  = b7 ? xp - 15'd16384 : xp;

    // Bit 6: delta = {b7, 0, 1, 12'b0}
    wire [14:0] dd6 = {b7, 1'b0, 1'b1, 12'b0};
    wire        b6  = (r7 >= dd6);
    wire [14:0] r6  = b6 ? r7 - dd6 : r7;

    // Bit 5: delta = {0, b7, b6, 0, 1, 10'b0}
    wire [14:0] dd5 = {1'b0, b7, b6, 1'b0, 1'b1, 10'b0};
    wire        b5  = (r6 >= dd5);
    wire [14:0] r5  = b5 ? r6 - dd5 : r6;

    // Bit 4: delta = {00, b7, b6, b5, 0, 1, 8'b0}
    wire [14:0] dd4 = {2'b0, b7, b6, b5, 1'b0, 1'b1, 8'b0};
    wire        b4  = (r5 >= dd4);
    wire [14:0] r4  = b4 ? r5 - dd4 : r5;

    // Bit 3: delta = {000, b7, b6, b5, b4, 0, 1, 6'b0}
    wire [14:0] dd3 = {3'b0, b7, b6, b5, b4, 1'b0, 1'b1, 6'b0};
    wire        b3  = (r4 >= dd3);
    wire [14:0] r3  = b3 ? r4 - dd3 : r4;

    // Bit 2: delta = {0000, b7..b3, 0, 1, 4'b0}
    wire [14:0] dd2 = {4'b0, b7, b6, b5, b4, b3, 1'b0, 1'b1, 4'b0};
    wire        b2  = (r3 >= dd2);
    wire [14:0] r2  = b2 ? r3 - dd2 : r3;

    // Bit 1: delta = {00000, b7..b2, 0, 1, 2'b0}
    wire [14:0] dd1 = {5'b0, b7, b6, b5, b4, b3, b2, 1'b0, 1'b1, 2'b0};
    wire        b1  = (r2 >= dd1);
    wire [14:0] r1  = b1 ? r2 - dd1 : r2;

    // Bit 0: delta = {000000, b7..b1, 0, 1}
    wire [14:0] dd0 = {6'b0, b7, b6, b5, b4, b3, b2, b1, 1'b0, 1'b1};
    wire        b0  = (r1 >= dd0);

    assign y = {b7, b6, b5, b4, b3, b2, b1, b0};

endmodule
