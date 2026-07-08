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


    logic           sram_clk = 0;
    logic           rst;
    logic [T_AW:0]  sram_addr;
    logic           sram_oe_n;
    logic           sram_we_n;
    logic [T_DW:0]  tb_data_out;
    logic           tb_drive_en;
    logic [T_DW:0]  data_write;
    logic [T_DW:0]  data_read;
    logic           sram_ce_i;
      
    wire  [T_DW:0]  sram_data;

    int error 	= 0;
    int passed	= 0;
    int bank_a_wr_count, bank_b_wr_count  = 0;
    int bank_a_rd_count, bank_b_rd_count  = 0;
    int test_cases = 10;

    assign sram_data = tb_drive_en ? tb_data_out : 'z;

    sram_bank dut (.*);

    always #5 sram_clk = ~sram_clk;

    task div; $display("+--------------------------------------------------------------------------------------------+");endtask
        
        task rst_task;
            begin
                rst = 1'b0;

                sram_addr   = '0;
                sram_oe_n   = '0;
                sram_we_n   = '0;
                tb_data_out = '0;
                tb_drive_en = '0;

                #10;

                rst = 1'b1;

                #10;
            end
        endtask

        task write_task(input [T_AW:0] addr, input [T_DW:0] data);
            begin
                sram_addr = addr;

                tb_data_out = data;
                tb_drive_en = 1'b1;

                // Write: OE_n = 0, WE_n = 0
                sram_oe_n = 1'b0;
                sram_we_n = 1'b0;

                @(posedge sram_clk);
                #1;

                tb_drive_en = 1'b0;

                // Idle
                sram_oe_n = 1'b1;
                sram_we_n = 1'b1;
            end
        endtask

        task read_task(input [T_AW:0] addr, output [T_DW:0] data);
            begin
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

        task cp;
            begin
                create_position(sram_addr, data_write);
            end
        endtask

        task wr_t;
            begin
                write_task(sram_addr, data_write);
                if(!sram_ce_i)
                    begin
                        div();
                        $display("|                   Writing data %05h at address %05h on the Bank A                       |", data_write, sram_addr);
                        bank_a_wr_count = bank_a_wr_count + 1;
                        #30;
                    end
                else
                    begin
                        div();
                        $display("|                  Writing data %05h at address %05h on the Bank B                        |", data_write, sram_addr);
                        bank_b_wr_count = bank_b_wr_count + 1;
                        #30;
                    end
            end
        endtask

        task rd_t;
            begin
                read_task(sram_addr, data_read);
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

        task check;
            begin
                if (data_read !== data_write) 
                    begin
                        $display(" ERROR: expected %05h, got %h at addr %05h |", data_write, data_read, sram_addr);
                        error = error + 1;
                    end
                else 
                    begin
                        $display("   OK: data matched at address %05h  |", sram_addr);
                        passed = passed + 1;
                    end
            end
        endtask

        initial begin
            rst_task();

            repeat(test_cases) 
                begin
                    cp();
                    wr_t();
                    rd_t();
                    check();                
                end

            div();
            $display("|                             Total passed: %05d | Total error: %05d                       |", 
            passed, error);
            div();
            $display("|                        Wrotes on A bank: %05d | Wrotes on B bank: %05d                   |", 
            bank_a_wr_count, bank_b_wr_count);
            div();
            $display("|                           Reads on A bank: %05d | Reads on B bank: %05d                  |", 
            bank_a_rd_count, bank_b_rd_count);
            div();
            $finish;
        end

    endmodule