// Company: InnoMountain
// Last Edited: 11/24/2025
// Authors: Sri Phanindra Perali & Brandon Crudele
// Notes:
// - Tests performed:
//     - RESET: verifies filter starts at x0 and P0
//     - INVERSION_TEST: inputs z_k = 1000, 1200, 1300 with P=1, R=1 to check K ≈ 0.5 and expected x_hat
//     - DETERMINISTIC TEST: repeated z_k = 800 over multiple cycles to check filter convergence and stability
////////////////////////////////////////////////////////

`timescale 1ns/1ps

module tb_kf_scalar;

  localparam WX = 16;
  localparam WP = 32;

  reg clk;
  reg rst_n;
  reg s_valid;
  wire s_ready;
  reg load_init;
  reg signed [WX-1:0] z_k;
  reg signed [WX-1:0] x0;
  reg signed [WP-1:0] P0;
  reg signed [WP-1:0] Q_k;
  reg signed [WP-1:0] R_k;

  wire         m_valid;
  wire signed [WX-1:0] x_hat;
  reg [255:0] test_name;

  kf_scalar #(
    .WX(WX), .WF_X(15),
    .WP(WP), .WF_P(29), // Q3.29
    .DIV_LAT(8),
    .MUL_LAT(2)
  ) DUT (
    .clk(clk),
    .rst_n(rst_n),
    .s_valid(s_valid),
    .s_ready(s_ready),
    .z_k(z_k),
    .load_init(load_init),
    .x0(x0),
    .P0(P0),
    .Q_k(Q_k),
    .R_k(R_k),
    .m_valid(m_valid),
    .m_ready(1'b1),
    .x_hat(x_hat)
  );

  initial begin
    clk = 0;
    forever #5 clk = ~clk; 
  end

  initial begin
    rst_n     = 0;
    s_valid   = 0;
    load_init = 0;
    z_k       = 0;
    x0        = 0;
    P0        = 32'sd1 <<< 29;    // P0 = 1.0
    Q_k       = 0;                // Q = 0
    R_k       = 32'sd1 <<< 29;    // R = 1.0
    test_name = "RESET";

    #50;
    rst_n = 1;

    @(posedge clk);
    load_init = 1;
    x0 = 16'sd0;
    @(posedge clk);
    load_init = 0;

    repeat(5) @(posedge clk);

    // TEST: P=1, R=1, Gain K should be 0.5
    // Input 1000. Expected output ~500.
    test_name = "INVERSION_TEST: z=1000";
    send_sample(16'sd1000);

    test_name = "INVERSION_TEST: z=1200";
    send_sample(16'sd1200);

    test_name = "INVERSION_TEST: z=1300";
    send_sample(16'sd1300);

    repeat(20) @(posedge clk);
    
    test_name = "RESET";

    #50;
    rst_n = 1; // does not currently RESET, not needed for test

    @(posedge clk);
    load_init = 1;
    x0 = 16'sd0;
    @(posedge clk);
    load_init = 0;

    repeat(5) @(posedge clk);
    
    
    test_name = "DETERMINISTIC TEST (1): z=800";
    send_sample(16'sd800);
    repeat(12) @(posedge clk);
    test_name = "DETERMINISTIC TEST (2): z=800";
    send_sample(16'sd800);
    repeat(12) @(posedge clk);
    test_name = "DETERMINISTIC TEST (3): z=800";
    send_sample(16'sd800);
    repeat(12) @(posedge clk);
    test_name = "DETERMINISTIC TEST (4): z=800";
    send_sample(16'sd800);
    repeat(12) @(posedge clk);
    test_name = "DETERMINISTIC TEST (5): z=800";
    send_sample(16'sd800);
    repeat(40) @(posedge clk);
    $finish;
  end

  task send_sample(input signed [WX-1:0] meas);
    begin
      @(posedge clk);
      z_k     <= meas;
      s_valid <= 1;
      @(posedge clk);
      s_valid <= 0;
    end
  endtask

  always @(posedge clk) begin
      $display("t=%0t | test=%s | s_valid=%b | z_k=%d | m_valid=%b | x_hat=%d",$time, test_name, s_valid, z_k, m_valid, x_hat);
  end

endmodule
