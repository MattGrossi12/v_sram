    `timescale 1ns/1ps

    module testbench;

        parameter DATA_WIDTH = 36;
        parameter ADDR_WIDTH = 21;
        parameter DATA_DEPTH = 1000000;

        parameter T_AW = ADDR_WIDTH - 1;
        parameter T_DW = DATA_WIDTH - 1;
        parameter T_DD = DATA_DEPTH - 1;

        logic sram_clk = 0;
        logic rst;

        logic [T_AW:0] sram_addr;

        logic sram_oe_n;
        logic sram_we_n;

        wire [T_DW:0] sram_data;

        logic [T_DW:0] tb_data_out;
        logic          tb_drive_en;
        logic [T_DW:0] data_write;
        logic [T_DW:0] data_read;
        
        int error = 0;
        int passed = 0;

        assign sram_data = tb_drive_en ? tb_data_out : 'z;

        sram_bank dut 
        (
            .sram_clk(sram_clk),
            .rst(rst),
            .sram_addr(sram_addr),
            .sram_oe_n(sram_oe_n),
            .sram_we_n(sram_we_n),
            .sram_data(sram_data)
        );

        always #5 sram_clk = ~sram_clk;

        task rst_task;
            begin
                rst = 1'b1;

                sram_addr = '0;
                sram_oe_n = 1'b0;
                sram_we_n = 1'b0;
                tb_data_out = '0;
                tb_drive_en = 1'b0;

                #10;

                rst = 1'b0;

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
                sram_addr = $urandom_range(0, T_DD);
                data = {$urandom, $urandom};
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
                $display("Writing data %h at address %h", data_write, sram_addr);
                #30;
            end
        endtask

        task rd_t;
            begin
                read_task(sram_addr, data_read);
                $display("Reading data %h at address %h", data_read, sram_addr);
                #30;
            end
        endtask

        task check;
            begin
                if (data_read !== data_write) 
                    begin
                        $display("ERROR: expected %h, got %h at address %h",
                                data_write, data_read, sram_addr);
                        error = error + 1;
                    end
                else 
                    begin
                        $display("OK: data matched at address %h", sram_addr);
                        passed = passed + 1;
                    end
            end
        endtask

        initial begin
            rst_task();

            repeat(1000) 
                begin
                    cp();
                    wr_t();
                    rd_t();
                    check();                
                end

            $display("Total passed: %d", passed);
            $display("Total error: %d", error);
        
            $finish;
        end

    endmodule