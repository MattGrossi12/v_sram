`timescale 1ns/1ps
module sram_bank #(
    //Widths:
    parameter DATA_WIDTH = 36,
    parameter ADDR_WIDTH = 21,
    parameter DATA_DEPTH = 1000000,

    //Trully-Widths:
    parameter T_AW   = (ADDR_WIDTH - 1),
    parameter T_DW   = (DATA_WIDTH - 1),
    parameter T_DD   = (DATA_DEPTH - 1)
)(
	input wire sram_clk,  //Output of sram_sram_clk send of mem_ctrl
  	input wire rst,  //Assincronous reset
    input wire [T_AW:0] sram_addr, // Data address
    input wire sram_we_n,   // 1: read, 0: write
    input wire sram_oe_n,   // 1: disable, 0: enable
    input wire sram_adv_ld_n, // 1: disable, 0: enable

  	inout [T_DW:0] sram_data  // Data to write/read
);

    sram_burst      #(
                    .DATA_WIDTH     (DATA_WIDTH),
                    .ADDR_WIDTH     (ADDR_WIDTH),
                    .DATA_DEPTH     (DATA_DEPTH)
                    ) sbt (
                    .sram_clk       (sram_clk),
                    .rst            (rst),
                    .sram_adv_ld_n  (sram_adv_ld_n),
                    .sram_addr_i    (sram_addr_i),
                    .sram_addr_o    (sram_addr_o)
                    );

    sram_bank       #(
                    .DATA_WIDTH     (DATA_WIDTH),
                    .ADDR_WIDTH     (ADDR_WIDTH),
                    .DATA_DEPTH     (DATA_DEPTH)
                    ) sbk (
                    .sram_clk       (sram_clk),
                    .rst            (rst),  
                    .sram_addr      (sram_addr),
                    .sram_we_n      (sram_we_n),
                    .sram_oe_n      (sram_oe_n),
                    .sram_data      (sram_data)
                    );

endmodule