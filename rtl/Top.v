module Top #(
//////////////////////////////////////////////////////////////////////////////
    parameter PAYLOAD_RAM_DATA_WIDTH = 8,
    parameter PAYLOAD_RAM_ADDR_WIDTH = 7,
    parameter PAYLOAD_RAM_DEPTH = 128,
//////////////////////////////////////////////////////////////////////////////
    parameter SHR_ROM_DATA_WIDTH = 8,
    parameter SHR_ROM_MEM_DEPTH = 12,
    localparam SHR_ROM_ADDR_WIDTH = $clog2(SHR_ROM_MEM_DEPTH),
//////////////////////////////////////////////////////////////////////////////
    parameter PHR_PSDU_RAM_DATA_WIDTH = 8,
    parameter PHR_PSDU_RAM_MEM_DEPTH = 344,
    localparam PHR_PSDU_RAM_ADDR_WIDTH = $clog2(PHR_PSDU_RAM_MEM_DEPTH),
    localparam  PHR_PSDU_CTR_WIDTH = $clog2(8*PHR_PSDU_RAM_MEM_DEPTH)
//////////////////////////////////////////////////////////////////////////////
    


) (
    input clk,
    input reset,
    input start_Tx,
    input [7:0] payloadLength,


    input  wire                  wclk,
    input  wire                  wen,
    input  wire [PAYLOAD_RAM_ADDR_WIDTH-1:0] waddr,
    input       [PAYLOAD_RAM_DATA_WIDTH-1:0] payload_din,


    
    output   done_Tx,
    output [7:0] Tx_real,           
    output [7:0] Tx_imag,            
    output       Tx_valid

);



// PHR
    wire [11:0] phr_bus;


// Payload RAM

    wire ram_start_sig;
    wire ram_data_sig;
    wire ram_valid_sig;



// Zero Padding

    wire pad_data_sig;
    wire pad_valid_sig;
    wire [10:0] padded_stream_bit_count;  



    // DEMUX

    wire I_serial;
    wire Q_serial;
    wire demux_valid;

// controller signals
    wire  framer_ctrl;
    wire gap_flag;
    wire  [6:0] sample_ctr;         
    wire  [1:0] chirp_ctr;          
    wire  [1:0] sub_chirp_ctr;      
    wire  seq_parity;               
    wire  symbol_valid;             

// rom related signals (rom-framer interface)
    wire  [SHR_ROM_ADDR_WIDTH-1:0]   SHR_rom_addr;
    wire         SHR_rom_enable;
    wire         SHR_rom_busy;
    wire         preamble_data;


// I/Q ram related signals (ram-framer interface)
    localparam integer ZP_MOD_N = 24; 
    localparam scale_num = 32;
    localparam scale_den = 6;

    wire [10:0] raw_bit_count   = 11'd12 + {payloadLength, 3'b000}; 
    wire [10:0] pad_remainder   = raw_bit_count % ZP_MOD_N;
    wire [10:0] total_bit_count = (pad_remainder == 0) ? raw_bit_count
                                                        : raw_bit_count + (ZP_MOD_N - pad_remainder);

    reg  [PHR_PSDU_CTR_WIDTH-1:0]   PHR_payloadLength;

    always @(posedge clk) begin
        if (reset)
            PHR_payloadLength <= {PHR_PSDU_CTR_WIDTH{1'b0}};
        else if (start_Tx)
            PHR_payloadLength <= (total_bit_count >> 1)*scale_num/scale_den ; 
    end

    wire  [PHR_PSDU_RAM_ADDR_WIDTH-1:0]   PHR_PSDU_ram_addr;
    wire        PHR_PSDU_ram_enable;
    
// I ram specific
    wire         PHR_PSDU_I_ram_busy;
    wire         PHR_PSDU_I_ram_data;
// Q ram specific
    wire         PHR_PSDU_Q_ram_busy;
    wire         PHR_PSDU_Q_ram_data;



// framer output signals
    wire   controller_out_I;        
    wire   controller_out_Q;        




// QPSK / DQPSK signals
    wire signed [1:0] qpsk_real;
    wire signed [1:0] qpsk_imag;

    wire signed [7:0] dqpsk_real;
    wire signed [7:0] dqpsk_imag;

    wire              dqpsk_valid;



// chirp modulator signals
    wire  signed [5:0] chirp_real;  
    wire  signed [5:0] chirp_imag;


// SYMBOL MAPPER signals

    wire [31:0] I_codeword;
    wire [31:0] Q_codeword;
    
    wire        I_symbol_valid;
    wire        Q_symbol_valid;

    wire [5:0]  I_symbol;
    wire [5:0]  Q_symbol;






    phr_generator u_phr_generator (
        .clk           (clk),
        .reset         (reset),
        .payloadLength (payloadLength),
        .phr           (phr_bus)
    );


   


    payload_ram #(
        .DATA_WIDTH (PAYLOAD_RAM_DATA_WIDTH),
        .ADDR_WIDTH (PAYLOAD_RAM_ADDR_WIDTH),
        .DEPTH      (PAYLOAD_RAM_DEPTH)
    ) u_payload_ram (
        .wclk        (wclk),
        .wen         (wen),
        .waddr       (waddr),
        .din         (payload_din),  

        .rclk        (clk),
        .reset       (reset),

        .start       (ram_start_sig),
        .payload_len (payloadLength[PAYLOAD_RAM_ADDR_WIDTH-1:0]),

        .data_out    (ram_data_sig),
        .valid_out   (ram_valid_sig)
    );


    



    zero_padding u_zero_padding (
        .clk           (clk),
        .reset         (reset),

        .start         (start_Tx),     
        .data_rate     (1'b1),         
        .payloadLength (payloadLength),
        .phr           (phr_bus),

        .data_in       (ram_data_sig),
        .valid_in      (ram_valid_sig),

        .ram_start     (ram_start_sig),

        .data_out      (pad_data_sig),
        .valid_out     (pad_valid_sig),

        .stream_bit_count           (padded_stream_bit_count)
    );
   
    


    demux u_demux (
        .clk       (clk),
        .reset     (reset),

        .data_in   (pad_data_sig),
        .valid_in  (pad_valid_sig),

        .I_out     (I_serial),
        .Q_out     (Q_serial),

        .valid_out (demux_valid)
    );


  
    serial_to_parallel_250 u_serial_I (
        .clk          (clk),
        .reset        (reset),
        .data_in      (I_serial),
        .data_valid   (demux_valid),
        .symbol_out   (I_symbol),
        .symbol_valid (I_symbol_valid)
    );


    serial_to_parallel_250 u_serial_Q (
        .clk          (clk),
        .reset        (reset),
        .data_in      (Q_serial),
        .data_valid   (demux_valid),
        .symbol_out   (Q_symbol),
        .symbol_valid (Q_symbol_valid)
    );



    symbol_mapper_250 u_mapper_I (
        .symbol_in (I_symbol),
        .codeword  (I_codeword)
    );


    symbol_mapper_250 u_mapper_Q (
        .symbol_in (Q_symbol),
        .codeword  (Q_codeword)
    );


    // COLLECT TWO 32-BIT CODEWORDS

    reg [31:0] I_first_codeword;
    reg [31:0] Q_first_codeword;

    reg I_count;
    reg Q_count;


    always @(posedge clk) begin

        if (reset) begin

            I_first_codeword <= 32'd0;
            Q_first_codeword <= 32'd0;

            I_count <= 1'b0;
            Q_count <= 1'b0;

        end

        else begin

            
            // I
            

            if (I_symbol_valid) begin

                if (I_count == 1'b0) begin

                    // First 32-bit codeword
                    I_first_codeword <= I_codeword;
                    I_count <= 1'b1;

                end

                else begin

                    // Second codeword received
                    I_count <= 1'b0;

                end

            end


            
            // Q
            

            if (Q_symbol_valid) begin

                if (Q_count == 1'b0) begin

                    // First 32-bit codeword
                    Q_first_codeword <= Q_codeword;
                    Q_count <= 1'b1;

                end

                else begin

                    // Second codeword received
                    Q_count <= 1'b0;

                end

            end

        end

    end


    //  DIRECT 64-BIT INPUT TO INTERLEAVER

    wire [63:0] I_interleaver_input;
    wire [63:0] Q_interleaver_input;

    wire [63:0] I_interleaved;
    wire [63:0] Q_interleaved;

    assign I_interleaver_input =
            {I_first_codeword, I_codeword};

    assign Q_interleaver_input =
            {Q_first_codeword, Q_codeword};


    //  INTERLEAVER

    interleaver_250 u_interleaver_I (
        .codeword             (I_interleaver_input),
        .interleaved_codeword (I_interleaved)
    );


    interleaver_250 u_interleaver_Q (
        .codeword             (Q_interleaver_input),
        .interleaved_codeword (Q_interleaved)
    );


    //  BUFFER WRITE ENABLE

    reg I_buffer_wr_en;
    reg Q_buffer_wr_en;


    //  BUFFER WRITE ADDRESSES

    reg [5:0] I_wr_addr;
    reg [5:0] Q_wr_addr;
    reg start_framer;


    always @(posedge clk) begin

        if (reset) begin

            I_wr_addr <= 6'd0;
            Q_wr_addr <= 6'd0;
            I_buffer_wr_en <= 1'b0;
            Q_buffer_wr_en <= 1'b0;
            start_framer <=1'b0;

        end

        else begin

            I_buffer_wr_en <= I_symbol_valid && I_count;  
            Q_buffer_wr_en <= Q_symbol_valid && Q_count;  

            if (I_buffer_wr_en) begin

                if ( I_wr_addr == (PHR_payloadLength/64)-1 ) begin
                    I_wr_addr <= 6'd0;
                    I_buffer_wr_en <= 0;
                    start_framer <=1;
                end else begin
                    I_wr_addr <= I_wr_addr + 1'b1;
                    start_framer <=0;
                    I_buffer_wr_en <= I_symbol_valid && I_count;

                end

            end else start_framer <=0;


            if (Q_buffer_wr_en) begin

                if (Q_wr_addr == (PHR_payloadLength/64)-1) begin
                    Q_wr_addr <= 6'd0;
                    Q_buffer_wr_en <= 0;
                end
                else begin
                    Q_wr_addr <= Q_wr_addr + 1'b1;
                    Q_buffer_wr_en <= Q_symbol_valid && Q_count;
                end

            end

        end

    end
    wire framer_done;

    controller ctrl (
    .clk(clk),
    .reset(reset),
    .start_Tx(start_framer),
    .symbol_valid(symbol_valid),
    .framer_done(framer_done),
    .sample_ctr(sample_ctr),
    .chirp_ctr(chirp_ctr),
    .sub_chirp_ctr(sub_chirp_ctr),
    .seq_parity(seq_parity),
    .framer_ctrl(framer_ctrl),
    .done_tx(done_Tx),
    .gap_flag(gap_flag)
    );

    
    buffer_ram_250 u_buffer_I (

        .clk      (clk),
        .reset    (reset),

        .wr_en    (I_buffer_wr_en),
        .wr_addr  (I_wr_addr),
        .data_in  (I_interleaved),

        .rd_en(PHR_PSDU_ram_enable),
        .rd_addr  (PHR_PSDU_ram_addr),
        .data_out (PHR_PSDU_I_ram_data),
        .busy(PHR_PSDU_I_ram_busy)

    );

    buffer_ram_250 u_buffer_Q (

        .clk      (clk),
        .reset    (reset),

        .wr_en    (Q_buffer_wr_en),
        .wr_addr  (Q_wr_addr),
        .data_in  (Q_interleaved),

        .rd_en(PHR_PSDU_ram_enable),
        .rd_addr  (PHR_PSDU_ram_addr),
        .data_out (PHR_PSDU_Q_ram_data),
        .busy(PHR_PSDU_Q_ram_busy)

    );

    css_ppdu_framer  #(
    .PHR_PSDU_RAM_MEM_DEPTH(PHR_PSDU_RAM_MEM_DEPTH),
    .SHR_ROM_MEM_DEPTH(SHR_ROM_MEM_DEPTH)
    ) framer (
        .clk(clk),
        .enable(framer_ctrl),
        .reset(reset),
        .start_tx(start_framer),
        .PHR_payloadLength(PHR_payloadLength), 
        
        .SHR_rom_addr(SHR_rom_addr),
        .SHR_rom_enable(SHR_rom_enable),

        .buffer_ram_addr(PHR_PSDU_ram_addr),
        .buffer_ram_enable(PHR_PSDU_ram_enable), 

        .preamble_I_data(preamble_data),
        .preamble_Q_data(preamble_data),
        .SHR_rom_busy(SHR_rom_busy),


        .buffer_I_data(PHR_PSDU_I_ram_data), 
        .buffer_I_ram_busy(PHR_PSDU_I_ram_busy),

        .buffer_Q_data(PHR_PSDU_Q_ram_data),
        .buffer_Q_ram_busy(PHR_PSDU_Q_ram_busy),
        
        .controller_out_I(controller_out_I),
        .controller_out_Q(controller_out_Q),
        .symbol_valid(symbol_valid),

        .done_tx(framer_done)
    );


    PreambleSFD_ROM #(
    .DATA_WIDTH(SHR_ROM_DATA_WIDTH),
    .MEM_DEPTH (SHR_ROM_MEM_DEPTH)
    ) rom (
        .clk(clk),
        .reset(reset),
        .read_en(SHR_rom_enable),
        .Address(SHR_rom_addr),
        .data_out(preamble_data),
        .busy(SHR_rom_busy)
    );
        


    qpsk_mapper u_qpsk (
        .chip_i (controller_out_I),
        .chip_q (controller_out_Q),
        .xn_i   (qpsk_real),
        .xn_q   (qpsk_imag)
    );


    // DQPSK Encoder

    dqpsk_encoder #(
        .WIDTH (8),
        .FRAC  (6)
    ) u_dqpsk (
        .clk       (clk),
        .reset     (reset),
        .symbol_en (symbol_valid),

        .xi        (qpsk_real),
        .xq        (qpsk_imag),

        .si_out    (dqpsk_real),
        .sq_out    (dqpsk_imag),

        .valid     (dqpsk_valid)
    );



    css_symbols_rom css_rom (
        .clk(clk),
        .chirp_index(chirp_ctr),
        .subchirp_idx(sub_chirp_ctr),
        .sample_idx(sample_ctr[5:0]),

        .chirp_real(chirp_real),  
        .chirp_imag(chirp_imag)
    );



    css_modulator modulator (
        .clk(clk),
        .reset(reset),
        .valid(dqpsk_valid),
        .dqpsk_real(dqpsk_real),
        .dqpsk_imag(dqpsk_imag),
        .gap_flag(gap_flag),
        .css_real(chirp_real),
        .css_imag(chirp_imag),
        .tx_real(Tx_real),
        .tx_imag(Tx_imag),
        .tx_valid(Tx_valid)
    );

endmodule 
