module serial_to_parallel_250 (
    input  wire       clk,
    input  wire       reset,
    input  wire       data_in,
    input  wire       data_valid,

    output reg [5:0]  symbol_out,
    output reg        symbol_valid
);

    reg [5:0] shift_reg;
    reg [2:0] bit_count;

    always @(posedge clk) begin
        if (reset) begin
            shift_reg    <= 6'd0;
            bit_count    <= 3'd0;
            symbol_out   <= 6'd0;
            symbol_valid <= 1'b0;
        end
        else begin
            symbol_valid <= 1'b0;

            if (data_valid) begin
                shift_reg <= {shift_reg[4:0], data_in};

                if (bit_count == 3'd5) begin
                    symbol_out   <= {shift_reg[4:0], data_in};
                    symbol_valid <= 1'b1;
                    bit_count    <= 3'd0;
                end
                else begin
                    bit_count <= bit_count + 1'b1;
                end
            end
        end
    end

endmodule