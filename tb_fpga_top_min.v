// Company: InnoMountain
// Last Edited: 11/24/2025
// Authors: Sri Phanindra Perali & Brandon Crudele
// Notes:
// - Top level TB for testing 2x2 matrices. 
// - Can currently test each pipe's values
// - z values are pulled through to top_min (remove later)

`timescale 1ns/1ps

module tb_fpga_top_min;

  reg clk_300;
  reg rst_n_btn;

  // DUT Inputs (added for TB purposes)
  reg signed [15:0] z11r, z11i, z12r, z12i, z21r, z21i, z22r, z22i;

  // DUT Outputs
  wire [3:0] leds;
  wire signed [15:0] h11r_out, h11i_out;

  // Instantiate DUT
  fpga_top_min DUT (
    .clk_300(clk_300),
    .rst_n_btn(rst_n_btn),
    // Connect Stimulus
    .z11r_in(z11r), .z11i_in(z11i),
    .z12r_in(z12r), .z12i_in(z12i),
    .z21r_in(z21r), .z21i_in(z21i),
    .z22r_in(z22r), .z22i_in(z22i),
    // Connect Outputs
    .leds(leds),
    .h11r_out(h11r_out), .h11i_out(h11i_out)
  );

  // Clock (300 MHz)
  initial clk_300 = 0;
  always #1.6667 clk_300 = ~clk_300;

  initial begin
    $display("--- Starting Simulation ---");
    
    // Init.
    rst_n_btn = 0;
    z11r=0; z11i=0; z12r=0; z12i=0;
    z21r=0; z21i=0; z22r=0; z22i=0;

    // Reset
    repeat(20) @(posedge clk_300);
    rst_n_btn = 1;
    $display("Reset Released");

    // Set Inputs
    z11r = 16'sd26214; 
    z11i = -16'sd3277;

    // WAIT FOR PULSE
    // We wait for the LED (valid_all) to go high, then check
    wait(leds[0] == 1'b1); 
    @(posedge clk_300); // sync to clock

    $display("--- Check 1: Iteration 1 ---");
    $display("Input z11r: %d", z11r);
    $display("Output h11r: %d (Expected ~13107)", h11r_out);
    
    // Wait for the pulse to finish before starting next test
    wait(leds[0] == 1'b0);

    // New Input
    z11r = 16'sd0; 
    
    // Wait for next valid pulse
    wait(leds[0] == 1'b1);
    @(posedge clk_300);

    $display("--- Check 2: Iteration 2 ---");
    $display("Input z11r: %d", z11r);
    $display("Output h11r: %d (Should decay)", h11r_out);

    $finish;
  end

endmodule