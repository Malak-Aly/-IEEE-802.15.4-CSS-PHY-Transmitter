module css_modulator (
    input  wire                    clk,
    input  wire                    reset,
    input  wire                    valid,

    input  wire signed [7:0]       dqpsk_real,
    input  wire signed [7:0]       dqpsk_imag,
    input                          gap_flag,

    input  wire signed [5:0]       css_real,
    input  wire signed [5:0]       css_imag,

    output reg signed [7:0]       tx_real,
    output reg signed [7:0]       tx_imag,
    output                        tx_valid
);

    reg signed [13:0] mult_rr;
    reg signed [13:0] mult_ii;
    reg signed [13:0] mult_ri;
    reg signed [13:0] mult_ir;

    reg signed [14:0] real_product;
    reg signed [14:0] imag_product;

    reg running;
    reg [5:0] ctr;
    reg gap_flag_reg;
    reg gap_flag_reg2;

    assign tx_valid = running || gap_flag_reg2;

    always @(posedge clk) begin
        
        if (reset) begin
            tx_real <= 8'sd0;
            tx_imag <= 8'sd0;
            ctr <=0;
            running <=0;
            gap_flag_reg <=0;
            gap_flag_reg2<=0;
        end else if (~running) begin
            if (valid) begin 
                running <= valid;
            end
            else running <=1'b0;
            tx_real <= 8'sd0;
            tx_imag <= 8'sd0; 
        end

        else begin

            mult_rr = dqpsk_real * css_real;
            mult_ii = dqpsk_imag * css_imag;

            mult_ri = dqpsk_real * css_imag;
            mult_ir = dqpsk_imag * css_real;

            real_product = mult_rr - mult_ii;
            imag_product = mult_ri + mult_ir;

            tx_real <= real_product >>> 6;
            tx_imag <= imag_product >>> 6;

            if (ctr != 37) begin
                ctr <= ctr +1;
            end else begin
                ctr <=0;
                running <=0;
            end

        end
        gap_flag_reg <= gap_flag;
        gap_flag_reg2 <= gap_flag_reg;

    end

endmodule