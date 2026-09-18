module interleaver_250 (
    input  wire [63:0] codeword,
    output wire [63:0] interleaved_codeword
);

    // -- high 32 bits of the output --------------------------------------
    assign interleaved_codeword[63:60] = codeword[63:60];  
    assign interleaved_codeword[59:56] = codeword[11: 8];   
    assign interleaved_codeword[55:52] = codeword[55:52];   
    assign interleaved_codeword[51:48] = codeword[ 3: 0];   

    assign interleaved_codeword[47:44] = codeword[47:44];   
    assign interleaved_codeword[43:40] = codeword[27:24];   
    assign interleaved_codeword[39:36] = codeword[39:36];   
    assign interleaved_codeword[35:32] = codeword[19:16];   

    // -- low 32 bits of the output ---------------------------------------
    assign interleaved_codeword[31:28] = codeword[31:28];   
    assign interleaved_codeword[27:24] = codeword[43:40];   
    assign interleaved_codeword[23:20] = codeword[23:20];   
    assign interleaved_codeword[19:16] = codeword[35:32];   

    assign interleaved_codeword[15:12] = codeword[15:12];   
    assign interleaved_codeword[11: 8] = codeword[59:56];   
    assign interleaved_codeword[ 7: 4] = codeword[ 7: 4];   
    assign interleaved_codeword[ 3: 0] = codeword[51:48];   

endmodule