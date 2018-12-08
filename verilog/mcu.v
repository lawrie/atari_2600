module mcu (
    input clock,

    output usbpu,

    output led,
    output [7:0] leds,

    output lcd_D0,
    output lcd_D1,
    output lcd_D2,
    output lcd_D3,
    output lcd_D4,
    output lcd_D5,
    output lcd_D6,
    output lcd_D7,
    output lcd_nreset,
    output lcd_cmd_data,
    output lcd_write_edge,
    output lcd_backlight,

    input [7:0] BUTTONS
);

    reg [7:0] dummy_leds;

    assign led = 0;

    // Show data fetched on leds 
    assign lcd_backlight = 1;

    // Disable USB
    assign usbpu = 0;

    // Generate reset
    wire reset = !(&reset_counter);
    reg [14:0] reset_counter = 0;
    reg [15:0] last_rom_adr;

    always @(posedge clock) begin
      if (reset) reset_counter <= reset_counter + 1;

      // Some debugging diagnostics
      if (rom_stb_i) last_rom_adr <= rom_adr_i;
      if (pia_stb_i && pia_adr_i == 'h280 && !pia_we_i) leds <= pia_dat_o;
    end

    ///////////////////////////////////////////////////////////////////////////
    ///////////////////////////////////////////////////////////////////////////
    ///
    /// Arlet 6502 Core
    ///
    ///////////////////////////////////////////////////////////////////////////
    ///////////////////////////////////////////////////////////////////////////

    // 6502 cpu interface
    wire [15:0] address_bus; 
    wire [7:0] read_bus;    
    wire [7:0] write_bus;  
    wire write_enable;    
    wire irq = 1'b0;            
    wire nmi = 1'b0;           
    reg ready;        
    reg stall_cpu;

    cpu cpu_inst (
        .clk(clock),
        .reset(reset),
        .AB(address_bus),
        .DI(read_bus),
        .DO(write_bus),
        .WE(write_enable),
        .IRQ(irq),
        .NMI(nmi),
        .RDY(ready && !stall_cpu)
    );

    // 6502 wishbone interface
    wire cpu_stb_o;
    reg cpu_we_o;
    reg [15:0] cpu_adr_o;
    reg [7:0] cpu_dat_o;
    wire cpu_ack_i;
    wire [7:0] cpu_dat_i;
    
    wb_6502_bridge #(
        .CLK_DIV_BITS(4)
    ) wb_6502_bridge_inst (
        .clk_i(clock),
        .rst_i(reset),
        .stb_o(cpu_stb_o),
        .we_o(cpu_we_o),
        .adr_o(cpu_adr_o),
        .dat_o(cpu_dat_o),
        .ack_i(cpu_ack_i),
        .dat_i(cpu_dat_i),
        .address_bus(address_bus),
        .read_bus(read_bus),
        .write_bus(write_bus),
        .write_enable(write_enable),
        .ready(ready)
    );

    ///////////////////////////////////////////////////////////////////////////
    ///////////////////////////////////////////////////////////////////////////
    ///
    /// BUTTON INPUT
    ///
    ///////////////////////////////////////////////////////////////////////////
    ///////////////////////////////////////////////////////////////////////////
    wire [7:0] buttons;

    SB_IO #(
      .PIN_TYPE(6'b 0000_01),
      .PULLUP(1'b 1)
    ) buttons_input [7:0] (
      .PACKAGE_PIN(BUTTONS),
      .D_IN_0(buttons)
    );

    ///////////////////////////////////////////////////////////////////////////
    ///////////////////////////////////////////////////////////////////////////
    ///
    /// TIA
    ///
    ///////////////////////////////////////////////////////////////////////////
    ///////////////////////////////////////////////////////////////////////////
    wire tia_stb_i;
    wire tia_we_i;
    wire [15:0] tia_adr_i;
    wire [7:0] tia_dat_i;
    wire tia_ack_o;
    wire [7:0] tia_dat_o;

    wb_tia tia_ram (
        .clk_i(clock),
        .rst_i(reset),
        .stb_i(tia_stb_i),
        .we_i(tia_we_i),
        .adr_i(tia_adr_i[6:0]),
        .dat_i(tia_dat_i),
        .ack_o(tia_ack_o),
        .dat_o(tia_dat_o),
        .buttons(buttons),
        .leds(dummy_leds),
        .stall_cpu(stall_cpu),
        .nreset(lcd_nreset),
        .cmd_data(lcd_cmd_data),
        .write_edge(lcd_write_edge),
        .dout({lcd_D7, lcd_D6, lcd_D5, lcd_D4,
               lcd_D3, lcd_D2, lcd_D1, lcd_D0})
    );

    ///////////////////////////////////////////////////////////////////////////
    ///////////////////////////////////////////////////////////////////////////
    ///
    /// RAM
    ///
    ///////////////////////////////////////////////////////////////////////////
    ///////////////////////////////////////////////////////////////////////////
    wire ram_stb_i;
    wire ram_we_i;
    wire [15:0] ram_adr_i;
    wire [7:0] ram_dat_i;
    wire ram_ack_o;
    wire [7:0] ram_dat_o;

    wb_ram #(
        .WB_DATA_WIDTH(8),
        .WB_ADDR_WIDTH(7),
        .WB_ALWAYS_READ(0),
        .RAM_DEPTH(128)
    ) pia_ram (
        .clk_i(clock),
        .rst_i(reset),
        .stb_i(ram_stb_i),
        .we_i(ram_we_i),
        .adr_i(ram_adr_i[6:0]),
        .dat_i(ram_dat_i),
        .ack_o(ram_ack_o),
        .dat_o(ram_dat_o)
    );

    ///////////////////////////////////////////////////////////////////////////
    ///////////////////////////////////////////////////////////////////////////
    ///
    /// PIA
    ///
    ///////////////////////////////////////////////////////////////////////////
    ///////////////////////////////////////////////////////////////////////////
    wire pia_stb_i;
    wire pia_we_i;
    wire [15:0] pia_adr_i;
    wire [7:0] pia_dat_i;
    wire pia_ack_o;
    wire [7:0] pia_dat_o;

    wb_pia pia (
        .clk_i(clock),
        .rst_i(reset),
        .stb_i(pia_stb_i),
        .we_i(pia_we_i),
        .adr_i(pia_adr_i[6:0]),
        .dat_i(pia_dat_i),
        .ack_o(pia_ack_o),
        .dat_o(pia_dat_o),
        .buttons(buttons),
        .ready(ready)
    );

    ///////////////////////////////////////////////////////////////////////////
    ///////////////////////////////////////////////////////////////////////////
    ///
    /// ROM
    ///
    ///////////////////////////////////////////////////////////////////////////
    ///////////////////////////////////////////////////////////////////////////
    wire rom_stb_i;
    wire rom_we_i;
    wire [15:0] rom_adr_i;
    wire [7:0] rom_dat_i;
    wire rom_ack_o;
    wire [7:0] rom_dat_o;

    wb_rom #(
        .WB_DATA_WIDTH(8),
        .WB_ADDR_WIDTH(12),
        .ROM_DEPTH(4096)
    ) main_rom (
        .clk_i(clock),
        .rst_i(reset),
        .stb_i(rom_stb_i),
        .we_i(rom_we_i),
        .adr_i(rom_adr_i[11:0]),
        .dat_i(rom_dat_i),
        .ack_o(rom_ack_o),
        .dat_o(rom_dat_o)
    );

    ///////////////////////////////////////////////////////////////////////////
    ///////////////////////////////////////////////////////////////////////////
    ///
    /// Wishbone Bus
    ///
    ///////////////////////////////////////////////////////////////////////////
    ///////////////////////////////////////////////////////////////////////////
    wb_bus #(
        .WB_DATA_WIDTH(8),
        .WB_ADDR_WIDTH(16),
        .WB_NUM_SLAVES(4)
    ) bus (
        // syscon
        .clk_i(clock),
        .rst_i(reset),

        // connection to wishbone master
        .mstr_stb_i(cpu_stb_o),
        .mstr_we_i(cpu_we_o),
        .mstr_adr_i(cpu_adr_o),
        .mstr_dat_i(cpu_dat_o),
        .mstr_ack_o(cpu_ack_i),
        .mstr_dat_o(cpu_dat_i),

        // wishbone slave decode         RAM    PIA         TIA         ROM
        .bus_slv_addr_decode_value({16'h0080,   16'h0280,   16'h0000,   16'hf000}),
        .bus_slv_addr_decode_mask ({16'hFF80,   16'hFF80,   16'hFF80,   16'hf000}),

        // connection to wishbone slaves
        .slv_stb_o                ({ram_stb_i,  pia_stb_i,  tia_stb_i,  rom_stb_i}),
        .slv_we_o                 ({ram_we_i,   pia_we_i,   tia_we_i,   rom_we_i}),
        .slv_adr_o                ({ram_adr_i,  pia_adr_i,  tia_adr_i,  rom_adr_i}),
        .slv_dat_o                ({ram_dat_i,  pia_dat_i,  tia_dat_i,  rom_dat_i}),
        .slv_ack_i                ({ram_ack_o,  pia_ack_o,  tia_ack_o,  rom_ack_o}),
        .slv_dat_i                ({ram_dat_o,  pia_dat_o,  tia_dat_o,  rom_dat_o})
    );
endmodule
