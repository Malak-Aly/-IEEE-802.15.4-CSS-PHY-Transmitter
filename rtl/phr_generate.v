module phr_generator (
    input  wire        clk,
    input  wire        reset,
    input  wire [7:0]  payloadLength,
    output reg  [11:0] phr
);

    always @(posedge clk) begin
        if (reset) begin
            phr <= 12'b0;
        end else begin
            phr[6:0]  <= payloadLength[6:0];
            phr[11:7] <= 5'b00000;
        end
    end

endmodule