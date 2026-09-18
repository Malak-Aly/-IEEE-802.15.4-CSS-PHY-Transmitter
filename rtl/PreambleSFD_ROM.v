module PreambleSFD_ROM #(
    parameter   DATA_WIDTH  = 8,
    parameter   MEM_DEPTH   = 256,
    localparam  ADDR_WIDTH  = $clog2(MEM_DEPTH),
    localparam  COUNT_WIDTH = $clog2(DATA_WIDTH)
)(
    input                        clk,
    input                        reset,
    input                        read_en,
    input   [ADDR_WIDTH-1:0]     Address,
    output  reg                  data_out,
    output  reg                     busy
);

    reg [DATA_WIDTH-1:0]    rom [0:MEM_DEPTH-1];
    reg [DATA_WIDTH-1:0]    shift_reg;

    reg [COUNT_WIDTH-1:0]   count;
    

    initial begin
        $readmemb("PreambleSFD.mem", rom);
    end

    always @(posedge clk) begin

        if (reset) begin
            shift_reg <= 0;
            count     <= 0;
            busy      <= 0;
            data_out  <= 0;
        end

        else if (read_en && !busy ) begin

           
            shift_reg <= rom[Address];

           
            data_out <= rom[Address][DATA_WIDTH-1];

            count <= 1;
            busy  <= 1;

        end

        else if (read_en && busy ) begin

           
            shift_reg <= {shift_reg[DATA_WIDTH-2:0], 1'b0};

           
            data_out <= shift_reg[DATA_WIDTH-2];

            if (count == DATA_WIDTH-1) begin
                count <= 0;
                busy  <= 0;
            end
            else begin
                count <= count + 1'b1;
            end
        end

        else begin
            data_out <= 0;
        end

    end

endmodule
