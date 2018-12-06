/*
 * Simple Wishbone compliant ROM module.
 */
module wb_rom #(
    parameter WB_DATA_WIDTH = 8,
    parameter WB_ADDR_WIDTH = 12,
    parameter ROM_DEPTH = 4096,
    parameter MEM_INIT_FILE = "rom.mem"
) (
    // wishbone interface
    input                           clk_i,
    input                           rst_i,

    input                           stb_i,
    input                           we_i,
    input [WB_ADDR_WIDTH-1:0]       adr_i,
    input [WB_DATA_WIDTH-1:0]       dat_i,

    output reg                      ack_o,
    output reg [WB_DATA_WIDTH-1:0]  dat_o
);
    reg [WB_DATA_WIDTH-1:0] rom [ROM_DEPTH-1:0];

    wire valid_cmd = !rst_i && stb_i;
    wire valid_read_cmd = valid_cmd && !we_i;

    initial begin
        // Read in the rom
        $readmemh(MEM_INIT_FILE, rom);

        // Set vectors
        rom[12'hffc] <= 8'h00; // Reset vector: F000
        rom[12'hffd] <= 8'hf0;
    end

    always @(posedge clk_i) begin
        if (valid_read_cmd) begin
            dat_o <= rom[adr_i];
        end

        ack_o <= valid_cmd;
    end
endmodule
