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
    input wire sram_adv_ld_n, // 1: keep, 0: inc
  	input wire sram_we_n // 1: disable, 0: enable
    input   wire    [T_AW:0] sram_addr_i, // Data address input
    output  reg     [T_AW:0] sram_addr_o  // Data address output
);

localparam IDLE         = 2'b000;
localparam LOAD_ADDR    = 2'b001;
localparam SEND_ADDR    = 2'b011;
localparam INC    		= 2'b010;

reg [T_AW:0] sram_addr_t; // Temporary address register
reg [1:0] next_state;
//reg [1:0] state;

//FSM Control-path:
always @(*)
    begin

    //Se o burst estiver ativo e o buffer ram interno do sram estiver em zero
        if       ((sram_adv_ld_n == 1) && (sram_we_n == 1)) // Control signal
            begin
                next_state = LOAD_ADDR;
            end 
        else if  ((sram_adv_ld_n == 1) && (sram_we_n == 0)) // Control signal
            begin
                next_state = SEND_ADDR; 
            end
        else if  ((sram_adv_ld_n == 0) && (sram_we_n == 1)) // Control signal
            begin
                next_state = INC; 
            end
        else
            begin
                next_state = IDLE; 
            end
    end

//Address counter:
always @(posedge sram_clk or negedge rst)
    begin
        //state <= next_state;
        if (!rst) 
            begin
                sram_addr_t <= {ADDR_WIDTH{1'b0}};
                sram_addr_o <= {ADDR_WIDTH{1'b0}};
            end
        else 
            begin
                if      (next_state == LOAD_ADDR) // Load new address
                    begin
                        sram_addr_t <= sram_addr_i; // Load input address
                        sram_addr_o <= sram_addr_o; // Output current address
                    end
                else if (next_state == INC) // Load new address
                    begin
                        sram_addr_t <= sram_addr_t + 1; // Load input address
                        sram_addr_o <= sram_addr_o; // Output current address
                    end
                else if (next_state == SEND_ADDR) // Load new address
                    begin
                        sram_addr_t <= sram_addr_t; // Load input address
                        sram_addr_o <= sram_addr_t; // Output current address
                    end
                else // IDLE state
                    begin
                        sram_addr_t <= sram_addr_t; // Hold current address
                        sram_addr_o <= sram_addr_o; // Hold address out
                    end
            end
    end

endmodule