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
        logic [T_AW:0] sram_addr_o;     // Data address output
            
        // Variables for address generation:
        logic [T_AW:0] addr;
        logic [T_AW:0] expected_addr = 21'bZ;

        // Variables for testbench:
        logic temp_state;
        int test_cases = 1000;
        int error   = 0;
        int passed  = 0;    
        int cases   = 0;

        // Instantiate the SRAM burst module
        sram_burst dut 
                        (
                            .sram_clk(sram_clk),
                            .rst(rst),
                            .sram_adv_ld_n(sram_adv_ld_n),
                            .sram_addr_i(sram_addr_i),
                            .sram_addr_o(sram_addr_o)
                        );

        // Clock generation:
        always #5 sram_clk = ~sram_clk;

        // Task definitions for testbench operations:
        task rst_task; rst = 1'b0; #10; rst = 1'b1; #10; endtask
        task div; $display("+--------------------------------------------------------------------------------------------+");endtask
        task header; div(); $display("| Address Written | adv_ld_n |  Address Expected  | Address Read |  T_S  | Situation | Cases |"); div(); endtask
        task check_result; div(); $display("          Happen %d errors and %d passed cases                ", error, passed); div(); endtask

        // Task to check the output address against the expected address:
        task check; 
            begin
                //if ((sram_addr_o !== expected_addr) && (sram_adv_ld_n === 1'b0)) 
                if ((sram_addr_o !== expected_addr))    temp_state = 0;
                else                                    temp_state = 1;
            end    
        endtask

        // Task to display the address and check the output
        task addr_disp;
            begin
                cases = cases + 1;
                if(temp_state == 0)
                    begin
                        error = error + 1;
                        $display("|      %6h     |    %1b     |       %6h       |     %6h   |   %b   |   ERROR   | %05d |", addr, sram_adv_ld_n, expected_addr, sram_addr_o, temp_state, cases);
                    end
                else
                    begin
                        passed = passed + 1;
                        $display("|      %6h     |    %1b     |       %6h       |     %6h   |   %b   |    PASS   | %05d |", addr, sram_adv_ld_n, expected_addr, sram_addr_o, temp_state, cases);
                    end
            end
        endtask

        // Task to write an address and check the output
        task addr_wr;
            begin
                addr_disp();
                check();
                addr = $urandom_range(0, T_AW);
                sram_addr_i = addr;
                @(posedge sram_clk)
                    begin
                        sram_adv_ld_n = 1'b1;
                        #3;
                        sram_adv_ld_n = 1'b0;
                        expected_addr = addr + 1;
                        #3;
                    end
            end
        endtask

        // Main test routine to execute the test cases
        task test_routine;
            begin
                header();
                rst_task();
                repeat(test_cases) #100 addr_wr();
                #500;
                check_result();
                $finish;
            end
        endtask

        // Initial block to start the test routine
        initial test_routine();

    endmodule