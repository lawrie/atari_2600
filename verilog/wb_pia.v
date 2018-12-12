/*
 * Simple Wishbone compliant Atari 2600 PIA module.
 */
module wb_pia (
    // wishbone interface
    input                           clk_i,
    input                           rst_i,

    input                           stb_i,
    input                           we_i,
    input [6:0]                     adr_i,
    input [7:0]                     dat_i,

    output reg                      ack_o,
    output reg [7:0]                dat_o,


    input [7:0]                     buttons,
    input                           ready
);

    // Button numbers
    localparam UP = 4, RIGHT = 7, LEFT = 6, DOWN = 5,
               A = 3, B = 1, X = 0, Y = 2;

    wire valid_cmd = !rst_i && stb_i;
    wire valid_write_cmd = valid_cmd && we_i;
    wire valid_read_cmd = valid_cmd && !we_i;

    reg [7:0] intim;
    reg [23:0] time_counter;
    reg [7:0]  reset_timer;
    reg [10:0] interval;
    reg reset_interval;

    always @(posedge clk_i) begin
        reset_timer <= 0;

        if (valid_read_cmd) begin
          case (adr_i) 
          'h00: dat_o <= buttons; // SWCHA
          'h01: ; // SWACNT
          'h02: dat_o <= 'hfc | (buttons[X] << 1) | buttons[Y] ; // SWCHB
          'h03: ; // SWBCNT
          'h04: dat_o <= intim; // INTIM
          endcase
        end

        if (valid_write_cmd) begin
          case (adr_i)
          'h14: begin interval <= 1; reset_timer <= dat_i; end // TIM1T
          'h15: begin interval <= 8; reset_timer <= dat_i; end  // TIM8T
          'h16: begin interval <= 64; reset_timer <= dat_i; end // TIM64T
          'h17: begin interval <= 1024; reset_timer <= dat_i; end // T1024T
          endcase
        end

        if (reset_interval) interval <= 1;

        ack_o <= valid_cmd;
    end

    reg [4:0] pixel_counter;

    always @(posedge clk_i) begin
      pixel_counter <= pixel_counter + 1;
      reset_interval <= 0;

      if (reset_timer > 0) begin
        time_counter <= 0;
        pixel_counter <= 0;
        intim <= reset_timer;
	end else if (pixel_counter == 23) begin
        time_counter <= time_counter + 1;
        pixel_counter <= 0;
      end

      if (time_counter == interval - 1) begin
        if (intim == 0) reset_interval <= 1;
        intim <= intim - 1;
        time_counter <= 0;
      end

    end
   
endmodule
