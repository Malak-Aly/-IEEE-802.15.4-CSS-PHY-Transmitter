module zero_padding (
    input  wire        clk,
    input  wire        reset,
    input  wire        start,           
    input  wire        data_rate,       
    input  wire [7:0]  payloadLength,   
    input  wire [11:0] phr,             
    input  wire        data_in,         
    input  wire        valid_in,        
    output reg          ram_start,       
    output reg          data_out,        
    output reg          valid_out,       
    output reg [10:0]  stream_bit_count  
);

    localparam IDLE        = 3'b000;
    localparam SEND_PHR    = 3'b001;
    localparam STREAM_DATA = 3'b010;
    localparam PAD_ZEROS   = 3'b011;
    localparam DONE_STATE  = 3'b100;

    reg [2:0] state, next_state;

    reg [10:0] bit_count;         
    reg [10:0] target_bits;       
    reg [4:0]  mod_counter;       
    reg [4:0]  mod_threshold;     
    reg [3:0]  phr_idx;           

    always @(posedge clk) begin
        if (reset) begin
            state         <= IDLE;
            bit_count     <= 11'd0;
            target_bits   <= 11'd0;
            mod_counter   <= 5'd0;
            mod_threshold <= 5'd0;
            phr_idx       <= 4'd0;
            ram_start     <= 1'b0;
            data_out      <= 1'b0;
            valid_out     <= 1'b0;
            stream_bit_count <= 11'd0;
        end else begin
            state     <= next_state;
            ram_start <= 1'b0;   

            case (state)
                IDLE: begin
                    valid_out <= 1'b0;
                    if (start) begin
                        bit_count     <= 11'd0;
                        mod_counter   <= 5'd0;
                        phr_idx       <= 4'd0;
                        target_bits   <= 11'd12 + {payloadLength, 3'b000}; 
                        mod_threshold <= (data_rate == 1'b0) ? 5'd5 : 5'd23;
                    end
                end

                SEND_PHR: begin
                    data_out  <= phr[phr_idx];
                    valid_out <= 1'b1;
                    bit_count <= bit_count + 1'b1;
                    stream_bit_count <= stream_bit_count + 1'b1;

                    if (mod_counter == mod_threshold)
                        mod_counter <= 5'd0;
                    else
                        mod_counter <= mod_counter + 1'b1;

                    if (phr_idx == 4'd11) begin
                        phr_idx <= 4'd0;
                        if (payloadLength > 8'd0)
                            ram_start <= 1'b1; 
                    end else begin
                        phr_idx <= phr_idx + 1'b1;
                    end
                end
                STREAM_DATA: begin
                    if (valid_in) begin
                        data_out  <= data_in;
                        valid_out <= 1'b1;
                        bit_count <= bit_count + 1'b1;
                        stream_bit_count <= stream_bit_count + 1'b1;

                        if (mod_counter == mod_threshold)
                            mod_counter <= 5'd0;
                        else
                            mod_counter <= mod_counter + 1'b1;
                    end else begin
                        valid_out <= 1'b0;
                    end
                end

                PAD_ZEROS: begin
                    data_out  <= 1'b0;
                    valid_out <= 1'b1;
                    stream_bit_count <= stream_bit_count + 1'b1;

                    if (mod_counter == mod_threshold)
                        mod_counter <= 5'd0;
                    else
                        mod_counter <= mod_counter + 1'b1;
                end

                DONE_STATE: begin
                    valid_out <= 1'b0;
                end
            endcase
        end
    end

    always @(*) begin
        next_state = state;

        case (state)
            IDLE: begin
                if (start)
                    next_state = SEND_PHR;
            end

            SEND_PHR: begin
                if (phr_idx == 4'd11) begin
                    if (payloadLength > 8'd0)
                        next_state = STREAM_DATA;
                    else if (mod_counter == mod_threshold)
                        next_state = DONE_STATE;
                    else
                        next_state = PAD_ZEROS;
                end
            end

            STREAM_DATA: begin
                if (valid_in && (bit_count == target_bits - 1'b1)) begin
                    if (mod_counter == mod_threshold)
                        next_state = DONE_STATE;
                    else
                        next_state = PAD_ZEROS;
                end
            end

            PAD_ZEROS: begin
                if (mod_counter == mod_threshold)
                    next_state = DONE_STATE;
            end

            DONE_STATE: begin
                next_state = IDLE;
            end

            default: next_state = IDLE;
        endcase
    end

endmodule