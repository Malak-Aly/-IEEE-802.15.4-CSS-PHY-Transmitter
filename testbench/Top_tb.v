`timescale 1ns/1ps

module Top_tb;

    localparam TIMEOUT_CYCLES = 200_000;
    localparam PAYLOAD_MAX    = 128;

    reg clk = 0;
    reg reset;
    reg start_Tx;

    reg [7:0] payloadLength;

    reg wclk;
    reg wen;
    reg [6:0] waddr;
    reg [7:0] payload_din;

    wire done_Tx;
    wire [7:0] Tx_real;
    wire [7:0] Tx_imag;
    wire Tx_valid;

    reg [7:0] payload_mem [0:PAYLOAD_MAX-1];

    integer payload_count;
    integer i;

    integer rtl_tx_imag;
    integer rtl_tx_real;
    integer sample_count;

    integer symbol_valid_count;
    integer expected_symbols;

    integer cyc;
    reg timed_out;
    reg saw_done;
    reg done_glitch;

    always #5 clk = ~clk;
    always @(*) wclk = clk;

    Top dut (
        .clk           (clk),
        .reset         (reset),
        .start_Tx      (start_Tx),
        .payloadLength (payloadLength),
        .wclk          (wclk),
        .wen           (wen),
        .waddr         (waddr),
        .payload_din   (payload_din),
        .done_Tx       (done_Tx),
        .Tx_real       (Tx_real),
        .Tx_imag       (Tx_imag),
        .Tx_valid      (Tx_valid)
    );


    // ================================================================
    // Read payload.txt
    // ================================================================

    initial begin
        for (i = 0; i < PAYLOAD_MAX; i = i + 1)
            payload_mem[i] = 8'd0;

        $readmemb("payload.txt", payload_mem);

        payload_count = 28;

        $display("============================================");
        $display("Payload loaded from payload.txt");
        $display("Payload length = %0d bytes", payload_count);

        for (i = 0; i < payload_count; i = i + 1)
            $display("payload[%0d] = %02h", i, payload_mem[i]);

        $display("============================================");
    end


    // ================================================================
    // Write payload into DUT RAM
    // ================================================================

    task load_payload;
        integer k;
        begin
            for (k = 0; k < payload_count; k = k + 1) begin
                @(negedge clk);

                wen         = 1'b1;
                waddr       = k[6:0];
                payload_din = payload_mem[k];
            end

            @(negedge clk);
            wen         = 1'b0;
            waddr       = 7'd0;
            payload_din = 8'd0;
        end
    endtask


    // ================================================================
    // Count framer symbol_valid pulses
    // ================================================================

    always @(posedge clk) begin
        if (reset)
            symbol_valid_count = 0;
        else if (dut.symbol_valid)
            symbol_valid_count = symbol_valid_count + 1;
    end


    // ================================================================
    // Capture RTL Tx output
    //
    // This writes:
    //
    // sample_number   Tx_real   Tx_imag
    //
    // to rtl_tx_output.txt
    // ================================================================

    always @(posedge clk) begin

        if (reset) begin
            sample_count = 0;
        end

        else begin

            if (Tx_valid) begin

                $fwrite(rtl_tx_imag,
                        "%08b\n",
                        Tx_imag,
                        );

                $fwrite(rtl_tx_real,
                        "%08b\n",
                        Tx_real,
                        );

                sample_count = sample_count + 1;
            end

        end
    end


    // ================================================================
    // Run transmission
    // ================================================================

    initial begin

        rtl_tx_imag = $fopen("rtl_tx_imag_output.txt", "w");
        rtl_tx_real = $fopen("rtl_tx_real_output.txt", "w");

        if (rtl_tx_imag == 0 || rtl_tx_real == 0 ) begin
            $display("[ERROR] Could not open rtl_tx_output.txt");
            $finish;
        end

        reset         = 1'b1;
        start_Tx      = 1'b0;
        payloadLength = 8'd0;

        wen           = 1'b0;
        waddr         = 7'd0;
        payload_din   = 8'd0;

        sample_count  = 0;

        repeat (5) @(negedge clk);

        reset = 1'b0;

        repeat (5) @(negedge clk);


        // ------------------------------------------------------------
        // Load the exact payload from payload.txt
        // ------------------------------------------------------------

        load_payload;


        // ------------------------------------------------------------
        // Tell Top the payload length
        // ------------------------------------------------------------

        @(negedge clk);
        payloadLength = payload_count[7:0];


        // ------------------------------------------------------------
        // Start transmission
        // ------------------------------------------------------------

        @(negedge clk);
        start_Tx = 1'b1;

        @(negedge clk);
        start_Tx = 1'b0;


        // ------------------------------------------------------------
        // Wait for transmission to finish
        // ------------------------------------------------------------

        timed_out = 1'b0;
        saw_done  = 1'b0;

        for (cyc = 0;
             cyc < TIMEOUT_CYCLES && !saw_done;
             cyc = cyc + 1) begin

            @(negedge clk);

            if (done_Tx)
                saw_done = 1'b1;

        end


        if (!saw_done)
            timed_out = 1'b1;


        // ------------------------------------------------------------
        // Check done_Tx pulse
        // ------------------------------------------------------------

        done_glitch = 1'b0;

        if (saw_done) begin
            @(negedge clk);

            if (done_Tx)
                done_glitch = 1'b1;
        end


        expected_symbols = 96 + dut.PHR_payloadLength;


        $display("");
        $display("============================================");
        $display("TRANSMISSION RESULT");
        $display("============================================");

        if (!timed_out)
            $display("[PASS] done_Tx asserted");
        else
            $display("[FAIL] done_Tx timeout");

        if (!done_glitch)
            $display("[PASS] done_Tx is a single-cycle pulse");
        else
            $display("[FAIL] done_Tx stayed high");


        $display("symbol_valid_count = %0d", symbol_valid_count);
        $display("expected           = %0d", expected_symbols);

        if (symbol_valid_count == expected_symbols)
            $display("[PASS] symbol_valid count");
        else
            $display("[FAIL] symbol_valid count");


        $display("");
        $display("RTL output samples written: %0d", sample_count);
        $display("Output file: rtl_tx_output.txt");
        $display("============================================");


        repeat (20) @(negedge clk);

        $fclose(rtl_tx_real);
        $fclose(rtl_tx_imag);

        $finish;

    end


    // ================================================================
    // Global watchdog
    // ================================================================

    initial begin

        #(TIMEOUT_CYCLES * 2 * 10 * 2);

        $display("[FAIL] Global watchdog timeout");
        $finish;

    end

endmodule