//`timescale 1ns/1ps

//module tb_kf_scalar;

//  // Parameters (match DUT)
//  localparam WX = 16;
//  localparam WP = 32;

//  reg clk;
//  reg rst_n;
//  reg s_valid;
//  wire s_ready;
//  reg load_init;
//  reg signed [WX-1:0] z_k;
//  reg signed [WX-1:0] x0;
//  reg signed [WP-1:0] P0;
//  reg signed [WP-1:0] Q_k;
//  reg signed [WP-1:0] R_k;

//  wire        m_valid;
//  wire signed [WX-1:0] x_hat;

//  // Test description string for waveform
//  reg [255:0] test_name;

//  // Instantiate DUT
//  kf_scalar #(
//    .WX(WX), .WF_X(15),
//    .WP(WP), .WF_P(29),
//    .DIV_LAT(8),
//    .MUL_LAT(2)
//  ) DUT (
//    .clk(clk),
//    .rst_n(rst_n),
//    .s_valid(s_valid),
//    .s_ready(s_ready),
//    .z_k(z_k),
//    .load_init(load_init),
//    .x0(x0),
//    .P0(P0),
//    .Q_k(Q_k),
//    .R_k(R_k),
//    .m_valid(m_valid),
//    .m_ready(1'b1),
//    .x_hat(x_hat)
//  );

//  // Clock generation
//  initial begin
//    clk = 0;
//    forever #5 clk = ~clk;   // 100 MHz
//  end

//  // Stimulus
//  initial begin
//    // Initialize signals
//    rst_n     = 0;
//    s_valid   = 0;
//    load_init = 0;
//    z_k       = 0;
//    x0        = 0;
//    P0        = 32'sd200000000;  // example ~Q3.29
//    Q_k       = 32'sd1000;       // process noise
//    R_k       = 32'sd5000;       // measurement noise
//    test_name = "RESET";

//    // Hold reset for some cycles
//    #50;
//    rst_n = 1;
//    test_name = "RESET RELEASED";

//    // Load initial state
//    @(posedge clk);
//    load_init = 1;
//    x0 = 16'sd100;   // initial guess
//    test_name = "LOAD INITIAL STATE";
//    @(posedge clk);
//    load_init = 0;

//    // Wait a bit
//    repeat (5) @(posedge clk);

//    // Start feeding measurements
//    s_valid = 1;

//    test_name = "MEASUREMENT 120";
//    z_k = 16'sd120;
//    @(posedge clk);

//    test_name = "MEASUREMENT 140";
//    z_k = 16'sd140;
//    @(posedge clk);

//    test_name = "MEASUREMENT 160";
//    z_k = 16'sd160;
//    @(posedge clk);

//    test_name = "MEASUREMENT 150";
//    z_k = 16'sd150;
//    @(posedge clk);

//    // Stop sending
//    s_valid = 0;
//    test_name = "IDLE";

//    // Run long enough to see results
//    repeat (40) @(posedge clk);
//    //---------------------------
//    // TEST 1: Static measurement
//    //---------------------------
//    test_name = "Static measurement";
//    z_k = 16'sd300; s_valid = 1;
//    repeat(5) @(posedge clk);
//    s_valid = 0;
//    repeat(5) @(posedge clk);

//    //---------------------------
//    // TEST 2: Step input
//    //---------------------------
//    test_name = "Step input";
//    z_k = 16'sd50; s_valid = 1;
//    @(posedge clk);
//    z_k = 16'sd200;
//    repeat(5) @(posedge clk);
//    s_valid = 0;
//    repeat(5) @(posedge clk);

//    //---------------------------
//    // TEST 3: Random noise
//    //---------------------------
//    test_name = "Random noise";
//    repeat(5) begin
//        z_k = $urandom_range(90,110);
//        s_valid = 1;
//        @(posedge clk);
//    end
//    s_valid = 0;
//    repeat(5) @(posedge clk);

//    //---------------------------
//    // TEST 4: High process noise (Q large)
//    //---------------------------
//    test_name = "High Q";
//    Q_k = 32'sd5000;
//    z_k = 16'sd120; s_valid = 1;
//    repeat(5) @(posedge clk);
//    s_valid = 0;
//    Q_k = 32'sd1000; // restore normal Q
//    repeat(5) @(posedge clk);

//    //---------------------------
//    // TEST 5: High measurement noise (R large)
//    //---------------------------
//    test_name = "High R";
//    R_k = 32'sd5000;
//    z_k = 16'sd130; s_valid = 1;
//    repeat(5) @(posedge clk);
//    s_valid = 0;
//    R_k = 32'sd500; // restore normal R
//    repeat(5) @(posedge clk);

//    //---------------------------
//    // TEST 6: Zero process noise
//    //---------------------------
//    test_name = "Zero Q";
//    Q_k = 32'sd0;
//    z_k = 16'sd140; s_valid = 1;
//    repeat(5) @(posedge clk);
//    s_valid = 0;
//    Q_k = 32'sd1000;
//    repeat(5) @(posedge clk);

//    //---------------------------
//    // TEST 7: Zero measurement noise
//    //---------------------------
//    test_name = "Zero R";
//    R_k = 32'sd0;
//    z_k = 16'sd150; s_valid = 1;
//    repeat(5) @(posedge clk);
//    s_valid = 0;
//    R_k = 32'sd500;
//    repeat(5) @(posedge clk);

//    //---------------------------
//    // TEST 8: Large sudden jump
//    //---------------------------
//    test_name = "Large jump";
//    z_k = 16'sd100; s_valid = 1;
//    @(posedge clk);
//    z_k = 16'sd500;
//    repeat(5) @(posedge clk);
//    s_valid = 0;
//    repeat(5) @(posedge clk);

//    //---------------------------
//    // TEST 9: Negative values
//    //---------------------------
//    test_name = "Negative values";
//    z_k = -16'sd50; s_valid = 1;
//    repeat(5) @(posedge clk);
//    s_valid = 0;
//    repeat(5) @(posedge clk);

//    //---------------------------
//    // TEST 10: Max/min values
//    //---------------------------
//    test_name = "Max/Min values";
//    z_k = 16'sd32767; s_valid = 1; // max Q1.15
//    @(posedge clk);
//    z_k = -16'sd32768;             // min Q1.15
//    repeat(5) @(posedge clk);
//    s_valid = 0;
//    repeat(5) @(posedge clk);

//    //---------------------------
//    // Finish simulation
//    //---------------------------
//    test_name = "All tests completed";
//    $display("All tests completed");
//    $finish;
//  end

//  // Watch output every cycle
//  always @(posedge clk) begin
//    $display("t=%0t | test=%s | s_valid=%b | z_k=%d | m_valid=%b | x_hat=%d",
//             $time, test_name, s_valid, z_k, m_valid, x_hat);
//  end

//endmodule

// WOW
//\
//

//
//
////
//`timescale 1ns/1ps

//module tb_kf_scalar;

//  // Parameters (match DUT)
//  localparam WX = 16;
//  localparam WP = 32;

//  reg clk;
//  reg rst_n;
//  reg s_valid;
//  wire s_ready;
//  reg load_init;
//  reg signed [WX-1:0] z_k;
//  reg signed [WX-1:0] x0;
//  reg signed [WP-1:0] P0;
//  reg signed [WP-1:0] Q_k;
//  reg signed [WP-1:0] R_k;

//  wire        m_valid;
//  wire signed [WX-1:0] x_hat;

//  // Test description for wave
//  reg [255:0] test_name;

//  // Instantiate DUT
//  kf_scalar #(
//    .WX(WX), .WF_X(15),
//    .WP(WP), .WF_P(29),
//    .DIV_LAT(8),
//    .MUL_LAT(2)
//  ) DUT (
//    .clk(clk),
//    .rst_n(rst_n),
//    .s_valid(s_valid),
//    .s_ready(s_ready),
//    .z_k(z_k),
//    .load_init(load_init),
//    .x0(x0),
//    .P0(P0),
//    .Q_k(Q_k),
//    .R_k(R_k),
//    .m_valid(m_valid),
//    .m_ready(1'b1),
//    .x_hat(x_hat)
//  );

//  // Clock generation
//  initial begin
//    clk = 0;
//    forever #5 clk = ~clk;   // 100 MHz
//  end

//  // ========================
//  // MAIN STIMULUS
//  // ========================
//  initial begin
//    // Initialize
//    rst_n     = 0;
//    s_valid   = 0;
//    load_init = 0;
//    z_k       = 0;
//    x0        = 0;
//    P0        = (32'sd1000);      // P0 = 1.0 in Q3.29
//    Q_k       = (32'sd0);             // Q = 0 for clean inversion test
//    R_k       = (32'sd1000);      // R = 1.0
//    test_name = "RESET";

//    #50;
//    rst_n = 1;
//    test_name = "RESET RELEASED";

//    // Load initial values
//    @(posedge clk);
//    load_init = 1;
//    x0 = 16'sd0;
//    @(posedge clk);
//    load_init = 0;

//    repeat(5) @(posedge clk);

//    // ================================================
//    // SIMPLE MATRIX-INVERSION / SCALAR GAIN TEST
//    // Expected: K = P_pred / (P_pred + R)
//    // With P0=1, Q=0, R=1 → K = 1/(1+1) = 0.5
//    // Should converge x_hat toward measurement
//    // ================================================
//    test_name = "INVERSION_TEST: z=1000";
//    send_sample(16'sd1000);

//    test_name = "INVERSION_TEST: z=1200";
//    send_sample(16'sd1200);

//    test_name = "INVERSION_TEST: z=1300";
//    send_sample(16'sd1300);

//    test_name = "INVERSION_TEST: z=900";
//    send_sample(16'sd900);

//    repeat(40) @(posedge clk);

//    // ================================================
//    //
//    // ================================================


//    test_name = "All tests completed";
//    $display("All tests completed");
//    $finish;
//  end

//  // One-cycle stimulus helper
//  task send_sample(input signed [WX-1:0] meas);
//    begin
//      @(posedge clk);
//      z_k     <= meas;
//      s_valid <= 1;
//      @(posedge clk);
//      s_valid <= 0;
//    end
//  endtask

//  // Debug print
//  always @(posedge clk) begin
//    $display("t=%0t | test=%s | s_valid=%b | z_k=%d | m_valid=%b | x_hat=%d",
//             $time, test_name, s_valid, z_k, m_valid, x_hat);
//  end

//endmodule


// NUTIME
////
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
    
    // FIX: Use shifts to set fixed-point values correctly
    // Q3.29 format: 1.0 represents 1 * 2^29
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
    rst_n = 1;

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
    //if (m_valid) 
      //$display("t=%0t | Output Valid: z_k=%d | x_hat=%d", $time, z_k, x_hat);
      $display("t=%0t | test=%s | s_valid=%b | z_k=%d | m_valid=%b | x_hat=%d",$time, test_name, s_valid, z_k, m_valid, x_hat);
  end

endmodule
