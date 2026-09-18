module demux (
    input wire clk,
    input wire reset,
    input wire data_in,
    input wire valid_in,

    output reg I_out,
    output reg Q_out,
    output reg valid_out
);

    reg bit_select;

    always @(posedge clk) begin

        if (reset) begin

            I_out      <= 1'b0;
            Q_out      <= 1'b0;
            valid_out  <= 1'b0;
            bit_select <= 1'b0;

        end

        else begin

            valid_out <= 1'b0;

            if (valid_in) begin

                if (bit_select == 1'b0) begin

                    // I bit
                    I_out      <= data_in;
                    bit_select <= 1'b1;

                end

                else begin

                    // Q bit
                    Q_out      <= data_in;
                    valid_out  <= 1'b1;
                    bit_select <= 1'b0;

                end

            end

        end

    end

endmodule