module buffer_ram_250 (
    input wire        clk,
    input wire        reset,


    input wire        wr_en,
    input wire [5:0]  wr_addr,
    input wire [63:0] data_in,

    input wire        rd_en,
    input wire [8:0]  rd_addr,

    output reg        data_out,
    output reg        busy
);

    reg [63:0] ram [0:63];
    reg [63:0] shift_reg;
    reg [5:0]  bit_count;

    integer i;

    always @(posedge clk) begin

        if (reset) begin

            data_out  <= 1'b0;
            busy      <= 1'b0;

            shift_reg <= 64'd0;
            bit_count <= 6'd0;

            for (i = 0; i < 64; i = i + 1)
                ram[i] <= 64'd0;

        end

        else begin

            if (wr_en)
                ram[wr_addr] <= data_in;

            if (rd_en && !busy) begin

                shift_reg <= ram[rd_addr];
                data_out  <= ram[rd_addr][63];

                bit_count <= 6'd1;
                busy      <= 1'b1;

            end

            else if (rd_en && busy) begin

                shift_reg <= {shift_reg[62:0], 1'b0};
                data_out  <= shift_reg[62];

                if (bit_count == 6'd63) begin
                    bit_count <= 6'd0;
                    busy      <= 1'b0;
                end
                else begin
                    bit_count <= bit_count + 1'b1;
                end

            end 
            else begin
                data_out <= 0;
            end

        end 
    end

endmodule