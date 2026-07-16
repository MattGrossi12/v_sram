    `timescale 1ns/1ps

    module testbench;

        // Parameters for the SRAM burst module
        localparam DATA_WIDTH = 36;
        localparam ADDR_WIDTH = 21;
        localparam DATA_DEPTH = 1000000;

        // Local parameters for address and data widths
        localparam T_AW = ADDR_WIDTH - 1;
        localparam T_DW = DATA_WIDTH - 1;
        localparam T_DD = DATA_DEPTH - 1;

        // Testbench signals
        logic sram_clk = 0;             //Output of sram_sram_clk send of mem_ctrl
        logic rst;                      //Assincronous reset
        logic sram_adv_ld_n;            // 1: disable, 0: enable
        logic [T_AW:0] sram_addr_i;     // Data address input
  		logic sram_we_n ;				// 1: disable, 0: enable
        logic [T_AW:0] sram_addr_o;     // Data address output
            
        // Variables for address generation:
        logic [T_AW:0] addr;
        logic [T_AW:0] expected_addr = 21'bZ;

        // Variables for testbench:
        logic temp_state;
        int test_cases = 30;
        int error   = 0;
        int passed  = 0;    
        int cases   = 0;
        int nw_ad   = 0;
        int inc_cases  = (test_cases/2);
        int idle_cases = (test_cases/2);

        // Instantiate the SRAM burst module
        sram_burst dut (.*);

        // Clock generation:
        always #5 sram_clk = ~sram_clk;

        // Task definitions for testbench operations:
        task rst_task; rst = 1'b0; #10; rst = 1'b1; #10; endtask
        task div; $display("+--------------------------------------------------------------------------------------+");endtask
        //task header; div(); $display("| Address Written | adv_ld_n |  Address Expected  | Address Read |  T_S  | Situation | Cases |"); div(); endtask
        task header; div(); $display("| clk | Address Written | adv_ld_n |  Address Expected  | Address Read |  T_S  | Cases |"); div(); endtask 
        task check_result; div(); $display("          Happen %d errors and %d passed cases                ", error, passed); div(); endtask

        task LOAD_ADDR;
            begin
                sram_adv_ld_n   = 1;
                sram_we_n       = 1;
            end
        endtask

        task SEND_ADDR;
            begin
                sram_adv_ld_n   = 1;
                sram_we_n       = 0;
            end
        endtask

        task INC;
            begin
                sram_adv_ld_n   = 0;
                sram_we_n       = 1;
            end
        endtask

        task IDLE;
            begin
                sram_adv_ld_n   = 0;
                sram_we_n       = 0;
            end
        endtask

        // Task to display the address and check the output
        task disp;
            begin
                $monitor("|  %1d  |      %6h     |    %1b     |       %6h       |     %6h   |   %b   | %05d |", sram_clk, sram_addr_i, sram_adv_ld_n, expected_addr, sram_addr_o, temp_state, cases);
            end
        endtask

        // Task to write an address and check the output
        task nw_addr_wr; 
            begin
                addr = $urandom_range(0, T_AW);
                sram_addr_i = addr;
            end    
        endtask

        task load_tb; 
            begin
                nw_addr_wr(); 
                expected_addr = addr;
                LOAD_ADDR(); 
                #10;
            end
        endtask

    task inc_tb;
        begin
            @(negedge sram_clk);
            sram_addr_i = 'z;
            INC();

            @(posedge sram_clk);
            #1;
            expected_addr = expected_addr + 1'b1;
            cases = cases + 1;

            @(negedge sram_clk);
            SEND_ADDR();

            @(posedge sram_clk);
            #1;
        end
    endtask

        task mult_inc;
            begin
                load_tb();
                repeat (inc_cases)
                    begin
                        inc_tb();
                    end
            end
        endtask

        task idle_tb;
            begin
                IDLE();
                #10;
            end
        endtask

        task mult_idle;
            begin
                repeat (idle_cases)
                    begin
                        idle_tb();
                    end
            end
        endtask

        // Main test routine to execute the test cases
        task test_routine;
            begin
                header();
                disp();
                rst_task();
                mult_inc();
                mult_idle();
                #500;
                check_result();
                $finish;
            end
        endtask

        // Initial block to start the test routine
        initial test_routine();

    endmodule