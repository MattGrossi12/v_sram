`timescale 1ns/1ps
module sram_top #(
    //Widths:
    parameter DATA_WIDTH = 18,
    parameter ADDR_WIDTH = 21,
    parameter BANK_QUANT = 2,
    parameter DATA_DEPTH = 1000000,

    //Trully-Widths:
    parameter T_AW   = (ADDR_WIDTH - 1),
    parameter T_DW   = (DATA_WIDTH - 1),
    parameter T_DD   = (DATA_DEPTH - 1),
    parameter T_BQ   = (BANK_QUANT - 1)
)(
	  input wire sram_clk,  //Output of sram_sram_clk send of mem_ctrl
  	input wire rst,                 //Assincronous reset
    input wire [T_AW:0] sram_addr,  // Data address
    input wire sram_we_n,           // 1: read, 0: write
    input wire sram_oe_n,           // 1: disable, 0: enable
    input wire sram_adv_ld_n,       // 1: disable, 0: enable
    input wire sram_ce_i, 	        // 1: bankB, 0: bankA
  	inout [T_DW:0] sram_data        // Data to write/read
);

wire [T_AW:0] sram_addr_iw = sram_addr;
wire [T_AW:0] sram_addr_ow;
wire [T_AW:0] sram_addr_bus = sram_adv_ld_n ? sram_addr : sram_addr_ow;

    sram_burst      #(
                    .DATA_WIDTH     (DATA_WIDTH),
                    .ADDR_WIDTH     (ADDR_WIDTH),
                    .DATA_DEPTH     (DATA_DEPTH),
                    .BANK_QUANT     (BANK_QUANT)
                    ) sbt (
                    .sram_clk       (sram_clk),
                    .rst            (rst),
                    .sram_adv_ld_n  (sram_adv_ld_n),
                    .sram_addr_i    (sram_addr_iw),
                    .sram_addr_o    (sram_addr_ow)
                    );

    sram_bank       #(
                    .DATA_WIDTH     (DATA_WIDTH),
                    .ADDR_WIDTH     (ADDR_WIDTH),
                    .DATA_DEPTH     (DATA_DEPTH),
                    .BANK_QUANT     (BANK_QUANT)
                    ) sbk (
                    .sram_clk       (sram_clk),
                    .rst            (rst),  
                    .sram_ce_i      (sram_ce_i),
                    .sram_addr      (sram_addr_bus),
                    .sram_we_n      (sram_we_n),
                    .sram_oe_n      (sram_oe_n),
                    .sram_data      (sram_data)
                    );

endmodule