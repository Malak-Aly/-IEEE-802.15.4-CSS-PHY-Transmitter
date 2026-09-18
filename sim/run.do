noview *
vlib work 
vlog ../rtl/*.v ../testbench/Top_tb.v

vsim -voptargs=+acc work.Top_tb

# =========================================================
# PAD / RAM
# =========================================================
view wave -new -title PAD
add wave -radix binary clk reset start_Tx \
    dut.pad_valid_sig dut.pad_data_sig \
    dut.ram_start_sig dut.ram_valid_sig dut.ram_data_sig

config wave -signalnamewidth 1



# =========================================================
# DEMUX
# =========================================================
view wave -new -title DEMUX
add wave -radix binary clk reset \
    dut.pad_valid_sig dut.pad_data_sig \
    dut.demux_valid dut.I_serial dut.Q_serial

config wave -signalnamewidth 1



# =========================================================
# SYMBOL / INTERLEAVER
# =========================================================
view wave -new -title INTERLEAVER
add wave -radix binary clk reset dut.I_symbol_valid \
    -radix hex dut.I_symbol dut.I_codeword \
    dut.I_interleaver_input dut.I_interleaved

config wave -signalnamewidth 1



# =========================================================
# BUFFER
# =========================================================
view wave -new -title BUFFER
add wave -radix binary clk reset dut.I_buffer_wr_en \
    -radix hex dut.I_interleaved \
    -radix unsigned dut.I_wr_addr \
    -radix binary dut.start_framer

config wave -signalnamewidth 1



# =========================================================
# FRAMER
# =========================================================
view wave -new -title FRAMER
add wave -radix binary clk reset dut.start_framer dut.framer_ctrl \
    dut.framer.SHR_rom_enable dut.preamble_data \
    dut.framer.buffer_ram_enable dut.PHR_PSDU_I_ram_data \
    -radix unsigned dut.framer.cs \
    -radix binary dut.controller_out_I dut.controller_out_Q \
    dut.framer_done

config wave -signalnamewidth 1



# =========================================================
# CONTROLLER
# =========================================================
view wave -new -title CONTROLLER
add wave -radix binary clk reset \
    dut.framer_done dut.framer_ctrl \
    dut.symbol_valid dut.gap_flag \
    -radix unsigned dut.sample_ctr dut.sub_chirp_ctr

config wave -signalnamewidth 1



# =========================================================
# MODULATOR / OUTPUT
# =========================================================
view wave -new -title MODULATOR
add wave -radix binary clk reset \
    -radix hex dut.dqpsk_real \
    -radix binary dut.dqpsk_valid \
    -radix unsigned dut.ctrl.sub_chirp_ctr dut.modulator.ctr \
    -radix binary dut.modulator.gap_flag_reg2 dut.modulator.running \
    -radix hex     Tx_real      \
    -radix binary  Tx_valid done_Tx

config wave -signalnamewidth 1



run -all

wave zoom range -window PAD 0ps 2900000ps
wave zoom range -window DEMUX 0ps 2900000ps
wave zoom range -window INTERLEAVER 0ps 2900000ps
wave zoom range -window BUFFER 520000ps 2900000ps
wave zoom range -window FRAMER 0ns 80000000ps
wave zoom range -window CONTROLLER 375000000ps 378300000ps
wave zoom range -window MODULATOR 375000000ps 378300000ps