`timescale 1ns/1ps
module sram_bank #(
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
    input wire [T_AW:0] sram_addr, // Data address
    input wire sram_we_n,   // 1: read, 0: write
    input wire sram_oe_n,   // 1: disable, 0: enable
    input wire sram_ce_i, 	// 1: bankB, 0: bankA
  	inout [T_DW:0] sram_data  // Data to write/read
);

//FSM Gray-code based states:
localparam IDLE  = 2'b00;
localparam WRITE = 2'b01;
localparam READ  = 2'b11;

//States:
reg [1:0]       next_state;
reg [T_DW:0]    temp_bank;

//Memory Banks:
reg [T_DW:0] data_bank [0:T_BQ] [0:T_DD]; 
/*Data width    Quantity of Banks       Memory array depth */

//--------------------------------------------------------------------------------------------------------------
//FSM Control-path:
always @(*)
    begin
        if (!sram_oe_n) // Control signal
            begin
                if (!sram_we_n) // Write mode
                    begin
                        next_state = WRITE;
                    end 
                else // Read mode
                    begin
                        next_state = READ;
                    end
            end 
        else 
            begin
                next_state = IDLE;
            end
    end

//--------------------------------------------------------------------------------------------------------------
//FSM Data-path:
always @(posedge sram_clk or negedge rst)
    begin
        if (!rst) 
            begin
                temp_bank <= {DATA_WIDTH{1'b0}}; // Reset memory bank
            end 
        else 
            begin
                case (next_state)
                    WRITE: 
                    begin
                        if(!sram_ce_i)  data_bank[0][sram_addr] <= sram_data; // Write data to memory bank A
                        else            data_bank[1][sram_addr] <= sram_data; // Write data to memory bank B
                    end
                    READ: 
                    begin
                        if(!sram_ce_i)  temp_bank <= data_bank[0][sram_addr]; // Read data from memory bank A
                        else            temp_bank <= data_bank[1][sram_addr]; // Read data from memory bank B
                    end
                    default: 
                    begin
                        temp_bank <= temp_bank; // Maintain current state
                    end
                endcase
            end
    end

//--------------------------------------------------------------------------------------------------------------
// Tri-state buffer for data bus
assign sram_data = (!sram_oe_n && sram_we_n) ? temp_bank : {DATA_WIDTH{1'bz}}; // Tri-state buffer for data bus

endmodule