/*
 * Simple Wishbone compliant Atari 2600 TIA module.
 */
module wb_tia #(
    parameter WB_DATA_WIDTH = 8,
    parameter WB_ADDR_WIDTH = 7,
    parameter RAM_DEPTH = 128
) (
    // wishbone interface
    input                           clk_i,
    input                           rst_i,

    input                           stb_i,
    input                           we_i,
    input [WB_ADDR_WIDTH-1:0]       adr_i,
    input [WB_DATA_WIDTH-1:0]       dat_i,

    output reg                      ack_o,
    output reg [WB_DATA_WIDTH-1:0]  dat_o,

    // lcd interface
    output                          nreset,
    output                          cmd_data,
    output                          write_edge,
    output [7:0]                    dout,

    // buttons
    input [7:0]                     buttons,

    // cpu control
    output                          stall_cpu
);

    assign stall_cpu = wsync;

    // Button numbers
    localparam UP = 0, RIGHT = 1, LEFT = 2, DOWN = 3,
               A = 4, B = 5, X = 6, y = 7;

    reg [15:0] colors [0:128];
    reg [6:0] colubk, colup0, colup1, colupf;
    reg vsync, vblank, wsync, enam0, enam1, enabl, vdelbl, vdelp0, vdelp1;
    reg refp0, refp1;
    reg [7:0] nusiz0, nusiz1;
    reg [7:0] grp0, grp1;
    reg [7:0] x_p0, x_p1, x_m0, x_m1, x_bl;
    reg [19:0] pf;
    reg [7:0] ctrlpf;
    reg [3:0] hmp0, hmp1, hmm0, hmm1, hmbl;
    reg [15:0] cx;
    reg [3:0] audc0, audc1, audv0, audv1;
    reg [4:0] audf0, audf1;
    reg inpt0 = 0, inpt1 = 0, inpt2 = 0, inpt3 = 0, inpt4 = 0, inpt5 = 0;

    initial $readmemh("colors.mem", colors);

    wire valid_cmd = !rst_i && stb_i;
    wire valid_write_cmd = valid_cmd && we_i;
    wire valid_read_cmd = valid_cmd && !we_i;

    reg free_cpu, do_sync, done_sync;

    integer i;

    always @(posedge clk_i) begin
        if (done_sync) do_sync <= 0;

        if (valid_read_cmd) begin
          dat_o <= 0;
          case (adr_i)
          'h00: ;                         // CXM0P
          'h01: ;                         // CXM1P
          'h02: ;                         // CXP0FB
          'h03: ;                         // CXP1FB
          'h04: ;                         // CXM0FB
          'h05: ;                         // CXM1FB
          'h06: ;                         // CXBLPF
          'h07: ;                         // CXPPMM
          'h08: dat_o <= inpt0 << 7;      // INPT0
          'h09: dat_o <= inpt1 << 7;      // INPT1
          'h0a: dat_o <= inpt2 << 7;      // INPT2
          'h0b: dat_o <= inpt3 << 7;      // INPT3
          'h0c: dat_o <= buttons[A] << 7; // INPT4
          'h0d: dat_o <= inpt5 << 7;      // INPT5
          endcase
        end

        if (free_cpu) wsync <= 0;

        if (valid_write_cmd) begin
          case (adr_i) 
          'h00: begin; vsync <= dat_i[1]; if (dat_i[1]) do_sync <= 1; end  // VSYNC
          'h01: vblank <= dat_i[1];       // VBLANK 
          'h02: wsync <= 1;               // WSYNC
          'h03: ;                         // RSYNC
          'h04: nusiz0 <= dat_i;          // NUSIZ0
          'h05: nusiz1 <= dat_i;          // NUSIZ1
          'h06: colup0 <= dat_i[7:1];     // COLUP0
          'h07: colup1 <= dat_i[7:1];     // COLUP1
          'h08: colupf <= dat_i[7:1];     // COLUPPF
          'h09: colubk <= dat_i[7:1];     // COLUPBK
          'h0a: ctrlpf <= dat_i;          // CTRLPF
          'h0b: refp0 <= dat_i[3];        // REFP0
          'h0c: refp1 <= dat_i[3];        // REFP1
          'h0d: for(i = 0; i<4; i = i + 1) pf[i] <= dat_i[4+i];   // PF0
          'h0e: for(i = 0; i<8; i = i + 1) pf[4+i] <= dat_i[7-i]; // PF1
          'h0f: for(i = 0; i<8; i = i + 1) pf[12+i] = dat_i[i];   // PF2
          'h10: x_p0 <= xpos >> 1;        // RESP0
          'h11: x_p1 <= xpos >> 1;        // RESP1
          'h12: x_m0 <= xpos >> 1;        // RESM0
          'h13: x_m1 <= xpos >> 1;        // RESM1
          'h14: x_bl <= xpos >> 1;        // RESBL
          'h15: audc0 <= dat_i[3:0];      // AUDC0
          'h16: audc1 <= dat_i[3:0];      // AUDC1
          'h17: audf0 <= dat_i[4:0];      // AUDF0
          'h18: audf1 <= dat_i[4:0];      // AUDF1
          'h19: audv0 <= dat_i[3:0];      // AUDV0
          'h1a: audv1 <= dat_i[3:0];      // AUDV1
          'h1b: grp0 <= dat_i;            // GRP0
          'h1c: grp1 <= dat_i;            // GRP1
          'h1d: enam0 <= dat_i[1];        // ENAM0
          'h1d: enam1 <= dat_i[1];        // ENAM1
          'h1f: enabl <= dat_i[1];        // ENABL
          'h20: hmp0 <= dat_i[3:0];       // HMP0
          'h21: hmp1 <= dat_i[3:0];       // HMP1
          'h22: hmm0 <= dat_i[3:0];       // HMM0
          'h23: hmm1 <= dat_i[3:0];       // HMM1
          'h24: hmbl <= dat_i[3:0];       // HMBL
          'h25: vdelp0 <= dat_i[0];       // VDELP0
          'h26: vdelp1 <= dat_i[0];       // VDELP1
          'h27: vdelbl <= dat_i[0];       // VDELBL
          'h28: ;                         // RESMP0
          'h29: ;                         // RESMP1
          'h2a: begin                     // HMOVE
                  x_p0 <= x_p0 + $signed(hmp0);
                  x_p1 <= x_p1 + $signed(hmp1);
                  x_m0 <= x_m0 + $signed(hmm0);
                  x_m1 <= x_m1 + $signed(hmm1);
                  x_bl <= x_bl + $signed(hmbl);
                end
          'h2b: begin hmp0 <= 0;          // HMCLR
                  hmp1 <= 0;  
                  hmm0 <= 0;  
                  hmm1 <= 0;  
                  hmbl <= 0; 
                end
          'h2c: cx <= 0;                  // CXCLR
          endcase
        end

        ack_o <= valid_cmd;
    end

   reg[10:0] xpos;
   reg[9:0] ypos;

   reg        pix_clk = 0;
   reg        reset_cursor = 0;
   wire       busy;
   reg [15:0] pix_data;
   wire       blank_busy = !(&busy_counter);
   reg [7:0]  busy_counter = 0;

   ili9341 lcd (
                .resetn(!rst_i),
                .clk_16MHz (clk_i),
                .nreset (nreset),
                .cmd_data (cmd_data),
                .write_edge (write_edge),
                .dout (dout),
                .reset_cursor (reset_cursor),
                .pix_data (pix_data),
                .pix_clk (pix_clk),
                .busy (busy)
                );

   wire pf_bit = pf[xpos < 160 ? (xpos >> 3) : ((319 - xpos) >> 3)];
   wire xp = (xpos >> 1);

   always @(posedge clk_i) begin
      free_cpu <= 0;
      done_sync = 0;
      pix_clk <= 0;
      reset_cursor <= 0;

      if (do_sync) begin
        reset_cursor <= 1;
        xpos <= 0;
        ypos <= 0;
        done_sync <= 1;
        free_cpu <= 1;
      end else if (!rst_i && !busy && !blank_busy && pix_clk == 0) begin
         if (ypos < 261) begin // 262 clock counts depth
            if (xpos < 455)  begin // 228 x 2 = 456 clock counts width
               xpos <= xpos + 1;
               if (xpos == 319) free_cpu <= 1; // Restart cpu in horizontal blank
            end else begin
               xpos <= 0;
               ypos <= ypos + 1;
            end
            
            if (ypos < 240 && xpos < 320) begin // Don't draw in blank or overscan areas
              if (ypos >= 24 && ypos < 226) // Leave gap of 24 pixels at top and bottom
                pix_data <= colors[enabl && x_bl == xp ? colupf :
                                   enam0 && x_m0 == xp ? colup0 :
                                   enam1 && x_m1 == xp ? colup1 :
                                   xp >= x_p0 && xp < x_p0 + 8 && grp0[xp - x_p0] ? colup0 :
                                   xp >= x_p1 && xp < x_p1 + 8 && grp1[xp - x_p1] ? colup1 :
                                   pf_bit ? colupf : colubk];
              else pix_data <= 0;
             
              pix_clk <= 1;
           end busy_counter <= 0; // Wait 8 clock cycles as if pixel were being written
              
         end else begin
            ypos <= 0;
         end
      end

      if (blank_busy) busy_counter <= busy_counter + 1;
   end
endmodule
