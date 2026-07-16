`timescale 1ns/1ps
module sram_burst #(
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
  	input wire rst,  //Assincronous reset
    input wire sram_adv_ld_n, // 1: disable, 0: enable
  	
    input   wire    [T_AW:0] sram_addr_i, // Data address input
    output  reg     [T_AW:0] sram_addr_o  // Data address output
);

localparam IDLE         = 2'b0;
localparam LOAD_ADDR    = 2'b1;

reg [T_AW:0] sram_addr_t; // Temporary address register
reg [1:0] next_state;

//FSM Control-path:
always @(*)
    begin
        if (!sram_adv_ld_n) // Control signal
            begin
                next_state = LOAD_ADDR;
            end 
        else
            begin
                next_state = IDLE;
            end
    end

//Address counter:
always @(posedge sram_clk or negedge rst)
    begin
        if (!rst) 
            begin
                sram_addr_t <= {ADDR_WIDTH{1'b0}};
                sram_addr_o <= {ADDR_WIDTH{1'b0}};
            end
        else 
            begin
                if (next_state == LOAD_ADDR) // Load new address
                    begin
                        sram_addr_t <= sram_addr_i + 1; // Load input address
                        sram_addr_o <= sram_addr_t; // Output current address
                    end
                else // IDLE state
                    begin
                        sram_addr_t <= sram_addr_t; // Hold current address
                        sram_addr_o <= {ADDR_WIDTH{1'bZ}}; // High impedance when not loading
                    end
            end
    end

endmodule