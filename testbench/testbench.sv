// Code your design here
module v_sram #(
    //Widths:
    parameter DATA_WIDTH = 36,
    parameter ADDR_WIDTH = 21,
    parameter DATA_DEPTH = 1000000,

    //Trully-Widths:
    parameter T_AW   = (ADDR_WIDTH - 1),
    parameter T_DW   = (DATA_WIDTH - 1),
    parameter T_DD   = (DATA_DEPTH - 1)
)(
    //sram_clk
	input wire clk,  //Output of sram_clk send of mem_ctrl
  	input wire rst,  //Assincronous reset
  	
    //sram_addr
    input wire [T_AW:0] addr_i, // Data address

    input wire enable_i,    // 1: enable, 0: disable

    input wire op_mode_i,   // 1: write, 0: read

    //sram_data
  	inout [T_DW:0] data_io  // Data to write/read
);

//FSM Gray-code based states:
localparam IDLE       = 2'b00;
localparam WRITE_MODE = 2'b01;
localparam READ_MODE  = 2'b11;

reg [T_DW:0] data_bank [0:T_DD]; // Memory bank
reg [1:0] next_state;
reg [T_DW:0] temp_bank;
  
//FSM Control-path:
always @(*)
    begin
        if (enable_i) // Control signal
            begin
                if (!op_mode_i) // Write mode
                    begin
                        next_state = WRITE_MODE;
                    end 
                else // Read mode
                    begin
                        next_state = READ_MODE;
                    end
            end 
        else 
            begin
                next_state = IDLE;
            end
    end

//FSM Data-path:
always @(posedge clk or posedge rst)
    begin
        if (rst) 
            begin
                temp_bank <= {DATA_WIDTH{1'b0}}; // Reset memory bank
            end 
        else 
            begin
                case (next_state)
                    WRITE_MODE: begin
                        data_bank[addr_i] <= data_io; // Write data to memory
                    end
                    READ_MODE: begin
                        temp_bank <= data_bank[addr_i]; // Read data from memory
                    end
                    default: begin
                        temp_bank <= temp_bank; // Maintain current state
                    end
                endcase
            end
    end

	assign data_io = (enable_i && !op_mode_i) ? temp_bank : {DATA_WIDTH{1'bz}}; // Tri-state buffer for data bus

endmodule