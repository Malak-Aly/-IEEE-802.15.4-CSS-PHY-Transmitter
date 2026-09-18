

module dqpsk_encoder #(
    parameter WIDTH = 8,   
    parameter FRAC  = 6    
)(
    input  wire                     clk,
    input  wire                     reset,      
    input  wire                     symbol_en,  
    input  wire signed [1:0]        xi,         
    input  wire signed [1:0]        xq,

    output reg  signed [WIDTH-1:0]  si_out,     
    output reg  signed [WIDTH-1:0]  sq_out,     
    output reg                      valid
);

    
    localparam signed [WIDTH-1:0] ONE_VAL = (1 << FRAC);

    
    reg signed [WIDTH-1:0] si_hist [0:3];
    reg signed [WIDTH-1:0] sq_hist [0:3];
    reg [1:0] ptr; 

    wire signed [WIDTH-1:0] si_prev = si_hist[ptr];
    wire signed [WIDTH-1:0] sq_prev = sq_hist[ptr];

    
    function signed [WIDTH-1:0] mul_pm1_0;
        input signed [1:0]       x;
        input signed [WIDTH-1:0] val;
        begin
            case (x)
                2'sd1  : mul_pm1_0 = val;
                -2'sd1 : mul_pm1_0 = -val;
                default: mul_pm1_0 = {WIDTH{1'b0}}; 
            endcase
        end
    endfunction

    wire signed [WIDTH-1:0] term_xi_si = mul_pm1_0(xi, si_prev);  
    wire signed [WIDTH-1:0] term_xq_sq = mul_pm1_0(xq, sq_prev);  
    wire signed [WIDTH-1:0] term_xi_sq = mul_pm1_0(xi, sq_prev);  
    wire signed [WIDTH-1:0] term_xq_si = mul_pm1_0(xq, si_prev);  

    wire signed [WIDTH-1:0] si_new = term_xi_si - term_xq_sq;
    wire signed [WIDTH-1:0] sq_new = term_xi_sq + term_xq_si;

    integer k;
    always @(posedge clk) begin
        if (reset) begin
            for (k = 0; k < 4; k = k + 1) begin
                si_hist[k] <= ONE_VAL;  
                sq_hist[k] <= ONE_VAL;  
            end
            ptr    <= 2'd0;
            valid  <= 1'b0;
            si_out <= ONE_VAL;
            sq_out <= ONE_VAL;
        end else if (symbol_en) begin
            si_hist[ptr] <= si_new;
            sq_hist[ptr] <= sq_new;
            si_out       <= si_new;
            sq_out       <= sq_new;
            ptr          <= ptr + 2'd1; 
            valid        <= 1'b1;
        end else begin
            valid <= 1'b0;
        end
    end

endmodule
