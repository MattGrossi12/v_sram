`timescale 1ns/1ps
module testbench;
    //Widths:
    parameter   DATA_WIDTH = 18,
                ADDR_WIDTH = 21,
                BANK_QUANT = 2,
                DATA_DEPTH = 1000000,

    //Trully-Widths:
                T_AW   = (ADDR_WIDTH - 1),
                T_DW   = (DATA_WIDTH - 1),
                T_DD   = (DATA_DEPTH - 1),
                T_BQ   = (BANK_QUANT - 1);

	logic           sram_clk = 0;           //Output of sram_sram_clk send of mem_ctrl
  	logic           rst;                    //Assincronous reset
    logic [T_AW:0]  sram_addr;              // Data address
    logic           sram_we_n;              // 1: read; 0: write
    logic           sram_oe_n;              // 1: disable; 0: enable
    logic           sram_adv_ld_n;          // 1: disable; 0: enable
    logic           sram_ce_i; 	            // 1: bankB, 0: bankA

    //Virtual-bus:
    logic [T_DW:0]  tb_data_out;
    logic           tb_drive_en;
    logic [T_DW:0]  data_write;
    logic [T_DW:0]  data_read;

    wire  [T_DW:0]  sram_data = tb_drive_en ? tb_data_out : 'z;

    //Constrainsts:
    int test_cases  = 10;
    int bank_mode   = 0;
    int error 	    = 0;
    int passed	    = 0;
    int bank_a_wr_count, bank_b_wr_count  = 0;
    int bank_a_rd_count, bank_b_rd_count  = 0;

    localparam  RM = 2'b00,
                BA = 2'b01,
                BB = 2'b10;


    sram_top dut (.*);

    always #5 sram_clk = ~sram_clk;
    task div; $display("+-------------------------------------------------------------------------------------------------------+");endtask
    task div_ch; $display("+=======================================================================================================+");endtask

    task rst_task;
        begin
            rst             = '0;
            sram_addr       = '0;
            sram_oe_n       = '0;
            sram_we_n       = '0;
            sram_adv_ld_n   = '1;
            sram_ce_i       = '0;
            #10;
            rst             = '1;
            #10;
        end
    endtask

    // Checker phase
    task check_result; $display("|                                  Happen %05d errors and %05d passed cases                           |", error, passed); div_ch(); endtask

    // Burst mode control:
    task on_bt;  sram_adv_ld_n = '0; endtask
    task off_bt; sram_adv_ld_n = '1; endtask

    // Bank selection:
    task random_bank;   sram_ce_i = $urandom_range(0, 1);   endtask
    task bank_a_s;      sram_ce_i = 0;                      endtask
    task bank_b_s;      sram_ce_i = 1;                      endtask

    task bank_selection(input [1:0] bank_mode);
        begin
            case(bank_mode)
                RM: random_bank();
                BA: bank_a_s();
                BB: bank_b_s();
                default: random_bank();
            endcase
        end
    endtask

    // Write-test:
    task write_task(input [T_AW:0] addr, input [T_DW:0] data, input [1:0] bank_mode);
        begin
            bank_selection(bank_mode);
            sram_addr   = addr;
            tb_data_out = data;
            tb_drive_en = 1'b1;

            // Write: OE_n = 0, WE_n = 0
            sram_oe_n   = 1'b0;
            sram_we_n   = 1'b0;

            @(posedge sram_clk);
                #1;
                tb_drive_en = 1'b0;
                // Idle
                sram_oe_n   = 1'b1;
                sram_we_n   = 1'b1;
            end
        endtask

    // Read-test:
    task read_task(input [T_AW:0] addr, output [T_DW:0] data, input [1:0] bank_mode);
        begin

            bank_selection(bank_mode);
            sram_addr = addr;
            tb_drive_en = 1'b0;
            
            // Read: OE_n = 0, WE_n = 1
            sram_oe_n = 1'b0;
            sram_we_n = 1'b1;

            @(posedge sram_clk);
                #1;
                data = sram_data;
                // Idle
                sram_oe_n = 1'b1;
                sram_we_n = 1'b1;
            end
        endtask

    task create_position(output [T_AW:0] sram_addr, output [T_DW:0] data);
        begin
            sram_addr   = $urandom_range(0, T_DD);
            data        = {$urandom, $urandom};
            sram_ce_i   = $urandom_range(0, 1);        
        end
    endtask

    task cp; create_position(sram_addr, data_write); endtask

    task wr_t;
        begin
            write_task(sram_addr, data_write, BA);
            if(!sram_ce_i)
                begin
                    div();
                    $display("|                           Writing data %05h at address %05h on the Bank A                          |", data_write, sram_addr);
                    bank_a_wr_count = bank_a_wr_count + 1;
                    #30;
                end
            else
                begin
                    div();
                    $display("|                              Writing data %05h at address %05h on the Bank B                       |", data_write, sram_addr);
                    bank_b_wr_count = bank_b_wr_count + 1;
                    #30;
                end
            end
        endtask

    task rd_t;
        begin
            read_task(sram_addr, data_read, BA);
            if(!sram_ce_i)
                begin
                    div();
                    $write("| Reading data %05h at address %05h on the Bank A |", data_read, sram_addr);          
                    bank_a_rd_count = bank_a_rd_count + 1;
                    #30;
                end
            else
                begin
                    div();
                    $write("| Reading data %05h at address %05h on the Bank B |", data_read, sram_addr);
                    bank_b_rd_count = bank_b_rd_count + 1;
                    #30;
                end
        end
    endtask

    task scoreboard;
        begin
            //rst_task();
            div_ch();
            $display("|                                Total passed: %05d | Total error: %05d                               |", 
            passed, error);
            div();
            $display("|                            Wrotes on A bank: %05d | Wrotes on B bank: %05d                          |", 
            bank_a_wr_count, bank_b_wr_count);
            div();
            $display("|                             Reads on A bank: %05d | Reads on B bank: %05d                           |", 
            bank_a_rd_count, bank_b_rd_count);
            div_ch();
        end
    endtask

    task coverage;
        begin
            if (data_read !== data_write) 
                begin
                    $display(" ERROR: expected %05h, got %h at addr %05h  |", data_write, data_read, sram_addr);
                    error = error + 1;
                end
            else 
                begin
                    $display("        OK: data matched at address %05h        |", sram_addr);
                    passed = passed + 1;
                end
            end
        endtask

    // Main test routine to execute the test cases
    task test_routine;
        begin
           // header();
            rst_task();
            repeat(test_cases) 
                begin
                    cp();
                    wr_t();
                    rd_t();
                    coverage();               
                end
            #500;
            scoreboard(); 
            check_result();
            $finish;
        end
    endtask

    // Initial block to start the test routine
    initial test_routine();
endmodule