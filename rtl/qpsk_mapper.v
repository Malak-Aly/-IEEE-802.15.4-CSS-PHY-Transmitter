
module qpsk_mapper #(
    parameter SYM_WIDTH = 2   
)(
    input  wire                        chip_i,  
    input  wire                        chip_q,  

    output wire signed [SYM_WIDTH-1:0] xn_i,    
    output wire signed [SYM_WIDTH-1:0] xn_q     
);

    localparam signed [SYM_WIDTH-1:0] PLUS_ONE  = {{(SYM_WIDTH-1){1'b0}}, 1'b1}; 
    localparam signed [SYM_WIDTH-1:0] MINUS_ONE = {SYM_WIDTH{1'b1}};             
    localparam signed [SYM_WIDTH-1:0] ZERO      = {SYM_WIDTH{1'b0}};            

  
    assign xn_i = (chip_i & chip_q)   ? PLUS_ONE  :
                  (~chip_i & ~chip_q) ? MINUS_ONE :
                                        ZERO;

   
    assign xn_q = (~chip_i & chip_q)  ? PLUS_ONE  :
                  (chip_i & ~chip_q)  ? MINUS_ONE :
                                        ZERO;

endmodule
