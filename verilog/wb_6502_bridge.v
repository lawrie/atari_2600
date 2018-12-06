/*
 * Wishbone adapter for Arlet's 6502 core: https://github.com/Arlet/verilog-6502
 */
module wb_6502_bridge #(
    parameter WB_DATA_WIDTH = 8,
    parameter WB_ADDR_WIDTH = 16,
    parameter CLK_DIV_BITS = 4
) (
    // wishbone interface
    input                           clk_i,
    input                           rst_i,

    output                          stb_o,
    output                          we_o,
    output [WB_ADDR_WIDTH-1:0]      adr_o,
    output [WB_DATA_WIDTH-1:0]      dat_o,

    input                           ack_i,
    input [WB_DATA_WIDTH-1:0]       dat_i,

    // 6502 interface
    input [15:0]                    address_bus,
    output [7:0]                    read_bus,
    input [7:0]                     write_bus,
    input                           write_enable,
    output                          ready
);

    // Run CPU at 1Hz
    reg [CLK_DIV_BITS-1:0] clk_div;

    // outputs to wb
    assign stb_o = 1; // Always read data from address

    // outputs to 6502
    assign read_bus = dat_i;
    
    always @(posedge clk_i) begin
        if (rst_i) begin
           ready <= 1;
           adr_o <= 0;
           dat_o <= 0;
           we_o <= 0;
           clk_div <= 0;
        end else begin
          clk_div <= clk_div + 1;
          ready <= (clk_div == 0); // Once per second

          // Register the CPU outputs
          if (ready) begin
            adr_o <= address_bus;
            dat_o <= write_bus;
            we_o <= write_enable;
          end
        end
    end
endmodule

