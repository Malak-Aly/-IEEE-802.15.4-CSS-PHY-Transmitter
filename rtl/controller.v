module controller (
    input               clk,
    input               reset,
    input               start_Tx,
    input               symbol_valid,
    input               framer_done,


    output reg  [6:0] sample_ctr,
    output reg  [1:0] chirp_ctr,
    output reg  [1:0] sub_chirp_ctr,
    output reg  seq_parity,
    output reg  framer_ctrl,
    output reg  done_tx,

    output reg gap_flag
);


    wire [6:0]   T_gap;
    reg         running;
    reg start_Tx_reg;
    reg start_Tx_reg2;
    reg start_Tx_reg3;
    reg waiting_ack;
  
    
    assign T_gap = (seq_parity)? 70 : 10;
   
    always @(posedge clk) begin
        if (reset) begin
            sample_ctr <= 0;
            chirp_ctr <= 0;
            sub_chirp_ctr <= 0;
            seq_parity <= 0;
            gap_flag <= 0;
            framer_ctrl <=0;
            running <=0;
            start_Tx_reg <=0; 
            start_Tx_reg2 <=0;
            start_Tx_reg3 <=0;
            done_tx <= 1'b0;
           
           
        
        end else if (!running) begin
            sample_ctr <= 0;
            chirp_ctr <= 0;
            sub_chirp_ctr <= 0;
            seq_parity <= 0;
            gap_flag <= 0;
            framer_ctrl <= 1;
            waiting_ack <= 1'b1;
            start_Tx_reg <=start_Tx; 
            start_Tx_reg2 <=start_Tx_reg;
            start_Tx_reg3 <= start_Tx_reg2;
            running <= start_Tx_reg3;   
            done_tx <= 1'b0;
        end else if (gap_flag && sample_ctr == T_gap-1) begin
            gap_flag <= 1'b0;
            chirp_ctr <=   0;
            seq_parity <=  ~seq_parity ;
            framer_ctrl <= 1'b1;        
            sample_ctr <= 0;             
            waiting_ack <= 1'b1;
            if (framer_done) begin 
                done_tx <=1;
                running<=0;
            end
           
        end else if (gap_flag) begin
            sample_ctr <= sample_ctr+1;
            framer_ctrl <= 1'b0; 
            done_tx <= 1'b0;
            
        end else if (waiting_ack) begin
            if (symbol_valid) begin
                sample_ctr <= sample_ctr +1;
                framer_ctrl <= 1'b0;
                waiting_ack <= 1'b0;
                done_tx <= 1'b0;
               
            end
        end else if ( ~gap_flag && sample_ctr == 37) begin
            sample_ctr <= 0;
            sub_chirp_ctr <= sub_chirp_ctr +1;
            gap_flag <= (sub_chirp_ctr == 3)? 1'b1 : 1'b0;
            framer_ctrl <= (sub_chirp_ctr == 3)? 1'b0 : 1'b1;
            waiting_ack <= 1'b1;
            done_tx <= 1'b0;
           
        end 
        else begin
            sample_ctr <= sample_ctr+1;
            framer_ctrl <= 1'b0;                    
            done_tx <= 1'b0;
           
        end
    end

endmodule 
