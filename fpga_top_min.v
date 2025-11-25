//`timescale 1ns / 1ps
////////////////////////////////////////////////////////////////////////////////////
// Old Code:

//// fpga_top_min.v - minimal pins: clk, reset, LEDs
//module fpga_top_min(
//  input  wire clk_300,     // board clock (or use MMCM to make 300 MHz)
//  input  wire rst_n_btn,   // active-low pushbutton
  
//  // FOR SIM ONLY //
//  input  wire signed [15:0] z11r_in, z11i_in,
//  input  wire signed [15:0] z12r_in, z12i_in,
//  input  wire signed [15:0] z21r_in, z21i_in,
//  input  wire signed [15:0] z22r_in, z22i_in,
//  ////
//  output wire [3:0] leds,
//  // Expose results for TB observation
//  output wire signed [15:0] h11r_out, h11i_out
//);
//  wire rst = ~rst_n_btn;

//  // KF core
//  localparam WX=16, WF_X=15, WP=32, WF_P=29, DIV_LAT=8, MUL_LAT=2;
//  reg en=1'b0, load_init=1'b1;
//  reg signed [WX-1:0] x0=0;
////  reg signed [WP-1:0] P0=32'sd1073741824; // ~0.5 in Q3.29
////  reg signed [WP-1:0] Qk=32'sd536;        // ~1e-6 * 2^29
////  reg signed [WP-1:0] Rk=32'sd536870;     // ~1e-3 * 2^29
//  reg signed [WP-1:0] P0 = 32'sd1 <<< 29; // 1.0 in Q3.29
//  reg signed [WP-1:0] Qk = 32'sd0;        // 0 Process noise (assume constant channel)
//  reg signed [WP-1:0] Rk = 32'sd1 <<< 29; // 1.0 in Q3.29 (High Noise)

//  // toy measurements (replace with your real feeder later)
//  reg signed [WX-1:0] z11r,z11i,z12r,z12i,z21r,z21i,z22r,z22i;
//  wire signed [WX-1:0] h11r,h11i,h12r,h12i,h21r,h21i,h22r,h22i;
//  wire valid_all; wire [15:0] last_latency;

//  kf_mimo2x2_core #(.WX(WX),.WF_X(WF_X),.WP(WP),.WF_P(WF_P),.DIV_LAT(DIV_LAT),.MUL_LAT(MUL_LAT)) DUT (
//    .clk(clk_300), .rst_n(~rst),
//    .en(en), .load_init(load_init),
//    .x0(x0), .P0(P0), .Q_k(Qk), .R_k(Rk),
//    .z11_re(z11r), .z11_im(z11i), .z12_re(z12r), .z12_im(z12i),
//    .z21_re(z21r), .z21_im(z21i), .z22_re(z22r), .z22_im(z22i),
//    .h11_re(h11r), .h11_im(h11i), .h12_re(h12r), .h12_im(h12i),
//    .h21_re(h21r), .h21_im(h21i), .h22_re(h22r), .h22_im(h22i),
//    .valid_all(valid_all), .last_latency(last_latency)
//  );

//  // Simple stimulus: slow pulse 'en' and fixed pilots
//  reg [19:0] divcnt=0;
//  always @(posedge clk_300) begin
//    if (rst) begin
//      divcnt<=0; en<=0; load_init<=1; z11r<=0; z11i<=0; z12r<=0; z12i<=0; z21r<=0; z21i<=0; z22r<=0; z22i<=0;
//    end else begin
//      load_init<=0;
//      divcnt <= divcnt + 1;
//      en <= (divcnt==20'd0);
//      // demo constants (replace with your feeder)
//      z11r<=16'sd26214; z11i<=-16'sd3277; // ~0.8, -0.1
//      z12r<=16'sd1638;  z12i<=16'sd655;   // ~0.05, 0.02
//      z21r<=-16'sd9830; z21i<=16'sd3932;  // ~-0.3, 0.12
//      z22r<=16'sd19661; z22i<=-16'sd4915; // ~0.6, -0.15
//    end
//  end

//  // LEDs: heartbeat + valid + latency bits
//  reg [23:0] hb; always @(posedge clk_300) hb <= hb+1;
//  assign leds[0] = hb[23];
//  assign leds[1] = valid_all;
//  assign leds[2] = last_latency[0];
//  assign leds[3] = last_latency[1];
//endmodule


`timescale 1ns / 1ps


module fpga_top_min(
  input  wire clk_300,     // board clock 
  input  wire rst_n_btn,   // active-low pushbutton
  
  // for tb:
  input  wire signed [15:0] z11r_in, z11i_in,
  input  wire signed [15:0] z12r_in, z12i_in,
  input  wire signed [15:0] z21r_in, z21i_in,
  input  wire signed [15:0] z22r_in, z22i_in,
  
  output wire [3:0] leds,
  
  // for tb:
  output wire signed [15:0] h11r_out, h11i_out
);
  wire rst = ~rst_n_btn;

  // KF core Parameters
  localparam WX=16, WF_X=15, WP=32, WF_P=29, DIV_LAT=8, MUL_LAT=2;

  // ---------------------------------------------------------
  // PARAMETER TUNING
  // ---------------------------------------------------------
  // P0 = 1.0 (Initial Uncertainty)
  // Rk = 1.0 (Measurement Noise - lots of noise!)
  // Expected Initial K = 1 / (1+1) = 0.5
  // This will make x_hat = 0.5 * z -ish
  // ---------------------------------------------------------
  
  reg signed [WP-1:0] P0 = 32'sd1 <<< 29; // 1.0 in Q3.29
  reg signed [WP-1:0] Qk = 32'sd0;        // 0 Process noise (assume constant channel)
  reg signed [WP-1:0] Rk = 32'sd1 <<< 29; // 1.0 in Q3.29 (High Noise)

  reg en;
  reg load_init;
  reg signed [WX-1:0] x0 = 0;

  // Interconnects
  wire valid_all; 
  wire [15:0] last_latency;

  // DUT Instance
  // Note: Wire inputs directly to the module ports
  kf_mimo2x2_core #(
    .WX(WX),.WF_X(WF_X),.WP(WP),.WF_P(WF_P),.DIV_LAT(DIV_LAT),.MUL_LAT(MUL_LAT)
  ) DUT (
    .clk(clk_300), .rst_n(~rst),
    .en(en), .load_init(load_init),
    .x0(x0), .P0(P0), .Q_k(Qk), .R_k(Rk),
    
    // Inputs from Top-Level Ports (driven by TB)
    .z11_re(z11r_in), .z11_im(z11i_in), 
    .z12_re(z12r_in), .z12_im(z12i_in),
    .z21_re(z21r_in), .z21_im(z21i_in), 
    .z22_re(z22r_in), .z22_im(z22i_in),
    
    // Outputs
    .h11_re(h11r_out), .h11_im(h11i_out), 
    // ... wire other outputs if needed for LEDs/Debug
    .h12_re(), .h12_im(),
    .h21_re(), .h21_im(), 
    .h22_re(), .h22_im(),
    
    .valid_all(valid_all), .last_latency(last_latency)
  );

  // State Machine for Control
  reg [3:0] state;
  localparam S_RESET = 0, S_LOAD = 1, S_IDLE = 2, S_MEASURE = 3;

  always @(posedge clk_300) begin
    if (rst) begin
      state <= S_RESET;
      en <= 0;
      load_init <= 0;
    end else begin
      case(state)
        S_RESET: begin
           load_init <= 1;
           state <= S_LOAD;
        end
        S_LOAD: begin
           load_init <= 0;
           state <= S_IDLE;
        end
        S_IDLE: begin
           // Simple heartbeat
           en <= 1; 
           state <= S_MEASURE;
        end
        S_MEASURE: begin
           en <= 0; // Pulse enable once
           if (valid_all) state <= S_IDLE; // Wait for done
        end
      endcase
    end
  end

  // LEDs
  assign leds[0] = valid_all;
  assign leds[3:1] = last_latency[2:0];

endmodule