module payload_ram #(
    parameter DATA_WIDTH = 8, 
    parameter ADDR_WIDTH = 7, 
    parameter DEPTH      = 128 
)(
    
    input  wire wclk,
    input  wire wen,
    input  wire [ADDR_WIDTH-1:0] waddr,
    input  wire [DATA_WIDTH-1:0] din,

    
    input  wire rclk,
    input  wire reset,
    input  wire start,                
    input  wire [ADDR_WIDTH-1:0] payload_len, 
    
    output reg  data_out,                
    output reg  valid_out                
);

    reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];

    always @(posedge wclk) begin
        if (wen) begin
            mem[waddr] <= din;
        end
    end

    localparam IDLE = 1'b0, READ = 1'b1;
    reg state;

    reg [ADDR_WIDTH-1:0] raddr;
    reg [2:0]            bit_cnt;
    reg [DATA_WIDTH-1:0] shift_reg;

    always @(posedge rclk) begin
        if (reset) begin
            state     <= IDLE;
            raddr     <= 0;
            bit_cnt   <= 3'd0;
            data_out  <= 1'b0;
            valid_out <= 1'b0;
            shift_reg <= 8'h00;
        end else begin
            case (state)
                IDLE: begin
                    valid_out <= 1'b0;
                    bit_cnt   <= 3'd0;
                    raddr     <= 0;
                    if (start && payload_len > 0) begin
                        shift_reg <= mem[0];
                        state     <= READ;
                    end
                end

                READ: begin
                    valid_out <= 1'b1;
                    data_out  <= shift_reg[bit_cnt]; // LSB First

                    if (bit_cnt == 3'd7) begin
                        bit_cnt <= 3'd0;
                        if (raddr == payload_len - 1'b1) begin
                            state <= IDLE; 
                        end else begin
                            raddr     <= raddr + 1'b1;
                            shift_reg <= mem[raddr + 1'b1];
                        end
                    end else begin
                        bit_cnt <= bit_cnt + 1'b1;
                    end
                end
            endcase
        end
    end

endmodule