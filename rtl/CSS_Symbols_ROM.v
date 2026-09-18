module css_symbols_rom (
    input  wire        clk,
    input  wire [1:0]  chirp_index,
    input  wire [1:0]  subchirp_idx,
    input  wire [5:0]  sample_idx,

    output reg  signed [5:0] chirp_real, 
    output reg  signed [5:0] chirp_imag
);
    reg signed [5:0] rom_real [0:607];
    reg signed [5:0] rom_imag [0:607];

    wire [9:0] addr = (({8'd0, chirp_index} * 10'd4 + {8'd0, subchirp_idx}) * 10'd38) + {4'd0, sample_idx};

    initial begin
        $readmemb("css_real.mem", rom_real);
        $readmemb("css_imag.mem", rom_imag);
    end

    always @(posedge clk) begin
        chirp_real <= rom_real[addr];
        chirp_imag <= rom_imag[addr];
    end
endmodule