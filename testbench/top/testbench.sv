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

    localparam  BA = 2'b00,
                BB = 2'b01,
                RM = 2'b10;

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

    // Variables for address generation:
    logic [T_AW:0] addr;
    logic [T_AW:0] exp_addr_burst = 21'bZ;

    //Constrainsts:
    int test_cases  = 20;
    int nor_cases  = (test_cases/2);
    int bur_cases  = (test_cases/2);
    //int bur_cases  = 0;
    int error 	    = 0;
    int passed	    = 0;
    int bank_a_wr_count, bank_b_wr_count  = 0;
    int bank_a_rd_count, bank_b_rd_count  = 0;
    int bank_mode = RM;
    int bank_used   = 0;
    int burst_test  = 0;
    int bur_cases_count = 0;
    int nor_cases_count = 0;

    sram_top dut (.*);

    always #5 sram_clk = ~sram_clk;
    task div;       $display("+-------------------------------------------------------------------------------------------------------+");endtask
    task div_ch;    $display("+=======================================================================================================+");endtask
    task nor_disp;  div_ch(); $display("|------------------------------| %04d cases in Normal operation mode: |---------------------------------|", nor_cases); div_ch(); endtask
    task bur_disp;  div_ch(); $display("|------------------------------| %04d cases in Burst operation mode: |----------------------------------|", bur_cases); div_ch(); endtask
    task nor_count_disp;  $display("|---------------------------------| Case nº %04d in Normal mode: |--------------------------------------|", nor_cases_count); endtask
    task bur_count_disp;  $display("|---------------------------------|  Case nº %04d in Burst mode: |--------------------------------------|", bur_cases_count); endtask

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
    task check_result; $display("|                                It happens %05d errors and %05d passed cases                         |", error, passed); div_ch(); endtask

    // Burst mode control:
    task on_bt;  sram_adv_ld_n = '0; endtask
    task off_bt; sram_adv_ld_n = '1; endtask

    // Bank selection:
    task random_bank; bank_used = $urandom_range(0, 1); endtask
    task bank_a_s; bank_used = BA; endtask
    task bank_b_s; bank_used = BB; endtask

    task bank_selection(input [1:0] bank_mode);
        begin
            case(bank_mode)
                RM:         random_bank();
                BA:         bank_a_s();
                BB:         bank_b_s();
                default:    random_bank();
            endcase
            sram_ce_i = bank_used;
        end
    endtask

    // Write-test:
    task write_task
        (
            input [T_AW:0] addr,
            input [T_DW:0] data,
            input          bank
        );
        begin
            off_bt();

            sram_ce_i   = bank;
            sram_addr   = addr;
            tb_data_out = data;
            tb_drive_en = 1'b1;

            // Write: OE_n = 0, WE_n = 0
            sram_oe_n = 1'b0;
            sram_we_n = 1'b0;

            @(posedge sram_clk);
            #1;

            tb_drive_en = 1'b0;
            sram_oe_n   = 1'b1;
            sram_we_n   = 1'b1;

            wr_print();
        end
    endtask

    task wr_print;
        begin
            if(!sram_ce_i)
                begin
                    $display("|                           Writing data %05h at address %05h on the Bank A                          |", data_write, sram_addr);
                    bank_a_wr_count = bank_a_wr_count + 1;
                    #30;
                end
            else
                begin
                    $display("|                              Writing data %05h at address %05h on the Bank B                       |", data_write, sram_addr);
                    bank_b_wr_count = bank_b_wr_count + 1;
                    #30;
                end
        end
    endtask

    task rd_print(
        input [T_DW:0] data,
        input [T_AW:0] addr,
        input          bank
    );
        begin
            if (!bank) begin
                $display("|                 After 50ns, we're trying read data %05h at address %05h on the Bank A              |",
                        data, addr);
                bank_a_rd_count = bank_a_rd_count + 1;
                #30;
                //coverage();
            end
            else begin
                $display("|                 After 50ns, we're trying read data %05h at address %05h on the Bank B              |",
                        data, addr);
                bank_b_rd_count = bank_b_rd_count + 1;
                #30;
                //coverage();
            end
        end
    endtask

    task wr_burst;
        begin
            on_bt();
            addr = $urandom_range(0, T_AW);
            sram_addr = addr;
            @(posedge sram_clk)
                begin
                    sram_adv_ld_n = 1'b1;
                    #3;
                    sram_adv_ld_n = 1'b0;
                    exp_addr_burst = addr + 1;
                    #3;
                end

            wr_print();

        end
    endtask

    // Read-test:
    task read_task
        (
            input  [T_AW:0] addr,
            input           bank,
            output [T_DW:0] data
        );
        begin
            off_bt();

            sram_ce_i   = bank;
            sram_addr   = addr;
            tb_drive_en = 1'b0;

            // Read: OE_n = 0, WE_n = 1
            sram_oe_n = 1'b0;
            sram_we_n = 1'b1;

            @(posedge sram_clk);
            #1;

            data = sram_data;

            sram_oe_n = 1'b1;
            sram_we_n = 1'b1;

            rd_print(data, addr, bank);
        end
    endtask

    task create_position(output [T_AW:0] sram_addr, output [T_DW:0] data);
        begin
            sram_addr   = $urandom_range(0, T_DD);
            data        = {$urandom, $urandom};
            bank_selection(bank_mode);
        end
    endtask

    task create_burst(output [T_AW:0] sram_addr, output [T_DW:0] data);
        begin
            bank_selection(bank_mode);
        end
    endtask

    task cp;
        begin
            create_position(sram_addr, data_write);
            write_task(sram_addr, data_write, bank_used);
            #50;
            read_task(sram_addr, bank_used, data_read);
            coverage();
        end
    endtask

    task cp_burst;
        begin
            create_burst(sram_addr, data_write);
            wr_burst();
            #50;
            read_task(sram_addr, bank_used, data_read);
            coverage();
        end
    endtask

    task header_mode;
        begin
            if(burst_test)  bur_disp;
            else            nor_disp;
        end
    endtask

    task scoreboard;
        begin
            //rst_task();
            div_ch();
            $display("|                                Total passed: %05d | Total error: %05d                               |",
            passed, error);
            $display("|                            Wrotes on A bank: %05d | Wrotes on B bank: %05d                          |",
            bank_a_wr_count, bank_b_wr_count);
            $display("|                             Reads on A bank: %05d | Reads on B bank: %05d                           |",
            bank_a_rd_count, bank_b_rd_count);
            div_ch();
        end
    endtask

    task coverage;
            if (data_read == data_write)
                begin
                    $display("|                               OK: expected %05h, got %h at addr %05h                            |", data_write, data_read, sram_addr);
                    passed = passed + 1;
                end
            else
                begin
                    $display("|                             ERROR: expected %05h, got %h at addr %05h                           |", data_write, data_read, sram_addr);
                    error = error + 1;
                end
        endtask

    //task normal_op; repeat(test_cases) cp();        endtask
    //task burst_op;  repeat(test_cases) cp_burst();  endtask

    // Main test routine to execute the test cases
    task test_routine;
        begin
        // header();
            rst_task();

            header_mode();
            repeat(nor_cases)
                begin
                    nor_count_disp();
                    cp();
                    nor_cases_count = nor_cases_count + 1;
                end

            burst_test = 1;
            header_mode();
            repeat(bur_cases)
                begin
                    bur_count_disp();
                    cp_burst();
                    bur_cases_count = bur_cases_count + 1;
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