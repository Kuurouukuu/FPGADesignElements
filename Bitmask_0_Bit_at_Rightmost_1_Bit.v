
//# Bitmask: 0 Bit at Rightmost 1 Bit

// Credit: [Hacker's Delight](./reading.html#Warren2013), Section 2-1: Manipulating Rightmost Bits

// Use the following formula to create a word with a single 0-bit at the
// position of the rightmost 1-bit in the input, producing all 1’s if none
// (e.g., 10101000 -> 11110111)

`default_nettype none

module Bitmask_0_Bit_at_Rightmost_1_Bit
#(
    parameter WORD_WIDTH = 0
)
(
    input   wire    [WORD_WIDTH-1:0]    word_in,
    output  reg     [WORD_WIDTH-1:0]    word_out
);

    initial begin
        word_out = {WORD_WIDTH{1'b0}};
    end

    localparam ONE = {{WORD_WIDTH-1{1'b0}},1'b1};

    always @(*) begin
        word_out = ~word_in | (word_in - ONE);
    end

endmodule

