module css_ppdu_framer #(

    parameter PREAMBLE_DONE = 80 ,
    parameter SFD_DONE = 16,
    localparam SHR_DONE = PREAMBLE_DONE + SFD_DONE,
    parameter PHR_PSDU_RAM_MEM_DEPTH = 344,       
    localparam PHR_PSDU_RAM_ADDR_WIDTH = $clog2(PHR_PSDU_RAM_MEM_DEPTH),

    localparam max_ppdu_length = SHR_DONE + 8*PHR_PSDU_RAM_MEM_DEPTH,   
    localparam CTR_WIDTH  = $clog2(max_ppdu_length),
    localparam PHR_PSDU_CTR_WIDTH = $clog2(8*PHR_PSDU_RAM_MEM_DEPTH),
    
    parameter SHR_ROM_MEM_DEPTH = 16,
    localparam SHR_ROM_ADDR_WIDTH = $clog2(SHR_ROM_MEM_DEPTH),

    parameter IDLE = 0,
    parameter SHR = 1,
    parameter PHR_PSDU = 2,
    parameter DONE = 3

) (
    input               clk,
    input               enable,
    input               reset,
    input               start_tx,
    input       [PHR_PSDU_CTR_WIDTH-1:0]   PHR_payloadLength, 
    
    output reg  [SHR_ROM_ADDR_WIDTH-1:0]    SHR_rom_addr,
    output reg          SHR_rom_enable,

    output reg  [PHR_PSDU_RAM_ADDR_WIDTH-1:0]   buffer_ram_addr,
    output reg          buffer_ram_enable, 

    input         preamble_I_data,
    input         preamble_Q_data,
    input         SHR_rom_busy,


    input         buffer_I_data, 
    input         buffer_I_ram_busy,

    input         buffer_Q_data,
    input         buffer_Q_ram_busy,   
    
    output reg          controller_out_I,
    output reg          controller_out_Q,
    output reg          symbol_valid,

    output reg          done_tx
);
    

    reg [2:0] cs,ns,ps;
    reg [CTR_WIDTH-1:0] idx_ctr;
    reg shr_data_valid;
    reg phr_psdu_data_valid;
    reg shr_pulse_sent;
    reg psdu_pulse_sent;


    always @(posedge clk) begin
        if (reset) begin
            cs  <= IDLE;
            ps <= IDLE;
        end else begin
            ps <= cs;
            cs <= ns;
        end
    end

// next state logic
    always @(*) begin
        case (cs)
            IDLE:           ns = (start_tx)?  SHR  : IDLE;
            SHR:            ns =  ((idx_ctr == SHR_DONE-1) && shr_data_valid )? PHR_PSDU  : SHR;
            PHR_PSDU:       ns = ((idx_ctr == PHR_payloadLength-1)&& phr_psdu_data_valid )? DONE : (PHR_payloadLength == 0 )? DONE : PHR_PSDU;
            DONE:           ns = IDLE;
            default:        ns = IDLE;
        endcase
    end

// output block
    always @(posedge clk) begin
        if (reset) begin
            SHR_rom_enable <= 1'b0;
            SHR_rom_addr <= {SHR_ROM_ADDR_WIDTH{1'b0}};
            buffer_ram_enable <=1'b0;
            buffer_ram_addr   <={PHR_PSDU_RAM_ADDR_WIDTH{1'b0}};
            controller_out_I  <= 1'b0;
            controller_out_Q  <= 1'b0;
            done_tx           <= 1'b0;
            symbol_valid      <= 1'b0;
            idx_ctr           <= {CTR_WIDTH{1'b0}};
            shr_data_valid    <=0;
            shr_pulse_sent <= 1'b0;
            phr_psdu_data_valid <=1'b0;
            psdu_pulse_sent <=1'b0;
        end else if (enable) begin
            done_tx <= 1'b0;
            case (cs)
                IDLE: begin
                    idx_ctr           <= {CTR_WIDTH{1'b0}};
                    SHR_rom_enable <= 1'b0;
                    SHR_rom_addr <= {SHR_ROM_ADDR_WIDTH{1'b0}};
                    buffer_ram_enable <=1'b0;
                    buffer_ram_addr   <={PHR_PSDU_RAM_ADDR_WIDTH{1'b0}};
                    controller_out_I  <= 1'b0;
                    controller_out_Q  <= 1'b0;
                    done_tx           <= 1'b0;
                    symbol_valid      <=1'b0;
                end
                SHR: begin
                    
                    if (!shr_pulse_sent ) begin
                        SHR_rom_enable <= 1'b1;
                        shr_pulse_sent <= 1'b1;      
                    end else begin
                        SHR_rom_enable <= 1'b0;
                    end
                    
                    shr_data_valid <=SHR_rom_enable;
                    SHR_rom_addr <= (~SHR_rom_busy && SHR_rom_enable)? SHR_rom_addr +1 : SHR_rom_addr;
                    buffer_ram_enable <=1'b0;
                    buffer_ram_addr   <={PHR_PSDU_RAM_ADDR_WIDTH{1'b0}};
                    if (shr_data_valid) begin
                        controller_out_I <= preamble_I_data;
                        controller_out_Q <= preamble_Q_data;
                        idx_ctr <= (idx_ctr == SHR_DONE-1)? {CTR_WIDTH{1'b0}} : idx_ctr + 1'b1;
                        symbol_valid <= 1'b1; 
                    end else
                        symbol_valid <= 1'b0;
                        done_tx           <= 1'b0;
                end
                PHR_PSDU: begin
                    if (!psdu_pulse_sent && (ps == PHR_PSDU)) begin
                        buffer_ram_enable <= 1'b1;
                        psdu_pulse_sent   <= 1'b1;  
                    end else begin
                        buffer_ram_enable <= 1'b0;
                    end

                    phr_psdu_data_valid <= buffer_ram_enable;
                    buffer_ram_addr <= (~(buffer_I_ram_busy||buffer_Q_ram_busy) && buffer_ram_enable)? buffer_ram_addr +1 : buffer_ram_addr;
                    SHR_rom_enable  <= 1'b0;
                    SHR_rom_addr    <= 8'b0;


                    if (phr_psdu_data_valid) begin
                        controller_out_I <= buffer_I_data;
                        controller_out_Q <= buffer_Q_data;
                        idx_ctr <= (idx_ctr == PHR_payloadLength-1)? {CTR_WIDTH{1'b0}} : idx_ctr + 1'b1;
                        symbol_valid <= 1'b1;
                    end else
                        symbol_valid <= 1'b0;
                        done_tx <= 1'b0;
                end
                DONE: begin
                    done_tx           <= 1'b1;
                    idx_ctr           <= {CTR_WIDTH{1'b0}};
                    SHR_rom_enable <= 1'b0;
                    SHR_rom_addr <= {SHR_ROM_ADDR_WIDTH{1'b0}};
                    buffer_ram_enable <=1'b0;
                    symbol_valid      <=1'b0;
                    buffer_ram_addr   <={PHR_PSDU_RAM_ADDR_WIDTH{1'b0}};
                end
                default: ;
            endcase
        end
        else begin
            buffer_ram_enable <=1'b0;
            shr_pulse_sent <= 1'b0;         
            psdu_pulse_sent <=1'b0;
            SHR_rom_enable <= 1'b0;
            symbol_valid <=1'b0;
            shr_data_valid <=1'b0;
        end
    end
endmodule 
