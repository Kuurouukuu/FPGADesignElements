
//# Boolean Word Reducer

// Reduces multiple words into a single word, using the given Boolean
// operation. Put differently: it's a [bit-reduction](./Bit_Reducer.html) of
// each bit position across all words.  The `words_in` input contains all the
// input words concatenated one after the other.

// A common use case is to compute multiple results and their selecting
// conditions in parallel, then [annul](./Annuller.html) all but the result you
// want and OR-reduce them into a single result. Or don't annul the results,
// but NAND them to see each bit position where the results disagree, and then
// maybe bit-reduce *that* to signal if *any* of the results disagree,
// possibly signalling an error.

`default_nettype none

module Word_Reducer
#(
    parameter OPERATION  = "",
    parameter WORD_WIDTH = 0,
    parameter WORD_COUNT = 0,

    // Don't change at instantiation
    parameter TOTAL_WIDTH = WORD_WIDTH * WORD_COUNT
)
(
    input   wire    [TOTAL_WIDTH-1:0]   words_in,
    output  wire    [WORD_WIDTH-1:0]    word_out
);

    localparam BIT_ZERO  = {WORD_COUNT{1'b0}};

// Instantiate the following hardware once for each bit position in a word.
// The `bit_word` gathers the bit at a given position from all the words.
// (e.g.: all the first bits, all the second bits, etc...) Then, for each
// word, extract the given bit position into the `bit_word`.

    generate

        genvar i, j;

        for (j=0; j < WORD_WIDTH; j=j+1) begin : per_bit

            reg [WORD_COUNT-1:0] bit_word = BIT_ZERO;

            for (i=0; i < WORD_COUNT; i=i+1) begin : per_word
                always @(*) begin
                    bit_word[i] = words_in[(WORD_WIDTH*i)+j];
                end
            end

// Then reduce the `bit_word` into the output bit using the specified Boolean
// function.  (i.e.: all input words first bits, gathered into `bit_word`,
// reduce to the first output word bit).  I use the
// [Bit_Reducer](./Bit_Reducer.html) here to both express that word reduction
// is a composition of bit reduction, and to avoid having to rewrite each
// possible case along with the special linter directives to avoid width
// warnings.

// The downside is that the list of possible operations is not visible here,
// but if you need to find them out, then reading the bit reducer code is the
// best documentation. And if you need to add an operation, then the word
// reducer code remains unchanged.

            Bit_Reducer
            #(
                .OPERATION      (OPERATION),
                .INPUT_COUNT    (WORD_COUNT)
            )
            bit_position
            (
                .bits_in        (bit_word),
                .bit_out        (word_out[j])
            );
        end

    endgenerate

endmodule

//## Alternate Implementation

// There exists an alternate implementation of word reduction which is
// differently elegant, but has a couple of pitfalls and cannot re-use the bit
// reducer code. I'll outline it here because it uses looped partial
// calculations with a peeled-out first iteration, which is a common code
// pattern.

// Repeatedly using a register in an unclocked loop expresses a combinational
// logic loop, which must be avoided: without special effort the CAD tool
// cannot analyze it for timing, or sometimes even synthesize it. So we create
// an array of registers to hold each partial result, and initialize them to
// zero.

//    reg [WORD_WIDTH-1:0] partial_reduction [WORD_COUNT-1:0];
//    
//    integer i;
//    
//    initial begin
//        for(i=0; i < WORD_COUNT; i=i+1) begin
//            partial_reduction[i] = ZERO;
//        end
//    end

// First, connect the zeroth input word to the zeroth partial result.  This
// peels out the first loop iteration, where the read index would be out of
// range (negative!) otherwise.

//    always @(*) begin
//        partial_reduction[0] = in[0 +: WORD_WIDTH];

// Then OR the previous partial result with the current input word, creating
// the next partial result. Note the start index because of the peeled-out
// first iteration: `i=1`.  This is where you would implement each possible
// operation, and most of the code would be duplicated boilerplate, differing
// only by the Boolean operator. This is dull, error-prone, and drags in
// synthesis-time complications, such as linter directives and operation
// selection, into the middle of run-time code.

//        for(i=1; i < WORD_COUNT; i=i+1) begin
//            partial_reduction[i] = partial_reduction[i-1] | words_in[WORD_WIDTH*i +: WORD_WIDTH];
//        end

// The last partial result is the final result.

//        word_out = partial_reduction[WORD_COUNT-1];
//    end


