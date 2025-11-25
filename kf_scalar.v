`timescale 1ns / 1ps

module kf_scalar #(
  parameter WX=16, WF_X=15,    // state Q1.15
  parameter WP=32, WF_P=29,    // cov Q3.29
  parameter DIV_LAT=8,         
  parameter MUL_LAT=2        
)(
  input  wire                  clk,
  input  wire                  rst_n,
  input  wire                  s_valid,
  output wire                  s_ready,
  input  wire signed [WX-1:0]  z_k,      
  input  wire                  load_init,
  input  wire signed [WX-1:0]  x0,
  input  wire signed [WP-1:0]  P0,
  input  wire signed [WP-1:0]  Q_k,
  input  wire signed [WP-1:0]  R_k,
  output reg                   m_valid,
  input  wire                  m_ready,
  output reg signed [WX-1:0]   x_hat
);

  assign s_ready = 1'b1;

  reg signed [WX-1:0] x_reg;
  reg signed [WP-1:0] P_reg;

  // Predict
  wire signed [WX-1:0] x_pred = x_reg;
  wire signed [WP-1:0] P_pred = P_reg + Q_k;

  // Divider: K = P / (P + R)
  // FIX: Output K in correct WF_P format (Q29) to match one_q
  wire signed [WP-1:0] denom = P_pred + R_k;
  wire signed [WP-1:0] K_q;

  div32_pipe #(.LAT(DIV_LAT), .WF_P(WF_P)) UDIV (
    .clk(clk),
    .rst_n(rst_n),
    .num(P_pred),
    .den(denom),
    .quo(K_q)
  );

  // Innovation
  wire signed [WX-1:0] innov0 = z_k - x_pred;

  // Pipelined arrays
  reg signed [WX-1:0] innov_pipe [0:DIV_LAT-1];
  reg signed [WX-1:0] xpred_pipe  [0:DIV_LAT-1];
  reg signed [WP-1:0] Ppred_pipe  [0:DIV_LAT-1];
  integer i;

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      for (i=0;i<DIV_LAT;i=i+1) begin
        innov_pipe[i] <= 0; xpred_pipe[i] <= 0; Ppred_pipe[i] <= 0;
      end
    end else begin
      innov_pipe[0] <= innov0; 
      xpred_pipe[0] <= x_pred; 
      Ppred_pipe[0] <= P_pred;
      for (i=1;i<DIV_LAT;i=i+1) begin
        innov_pipe[i] <= innov_pipe[i-1];
        xpred_pipe[i] <= xpred_pipe[i-1];
        Ppred_pipe[i] <= Ppred_pipe[i-1];
      end
    end
  end

  // Update Logic
  reg signed [WP+WX-1:0] Kinnov [0:MUL_LAT-1];
  reg signed [2*WP-1:0]  Pupd   [0:MUL_LAT-1];

  wire signed [WP-1:0] one_q = (32'sd1 <<< WF_P);
  
  // FIX: K_q is now Q29, one_q is Q29. Direct subtraction is now valid.
  wire signed [WP-1:0] one_minus_K = one_q - K_q;

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      for (i=0;i<MUL_LAT;i=i+1) begin
        Kinnov[i] <= 0; 
        Pupd[i]   <= 0; 
      end
    end else begin
      // Kinnov calculation:
      // K_q (Q29) * Innov (Q15) = Result Q44
      Kinnov[0] <= $signed(K_q) * $signed({{(WP-WX){innov_pipe[DIV_LAT-1][WX-1]}}, innov_pipe[DIV_LAT-1]});
      Pupd[0]   <= $signed(one_minus_K) * $signed(Ppred_pipe[DIV_LAT-1]);
      for (i=1;i<MUL_LAT;i=i+1) begin
        Kinnov[i] <= Kinnov[i-1];
        Pupd[i]   <= Pupd[i-1];
      end
    end
  end

  // FIX: Extraction index matches WF_P exactly now. 
  // We want Q15 result from Q44 data. We drop the bottom 29 bits (WF_P).
  wire signed [WX-1:0] dx = Kinnov[MUL_LAT-1][WF_P +: WX]; 
  wire signed [WP-1:0] Pn = Pupd[MUL_LAT-1][WF_P +: WP];

  // Output Logic
  localparam integer L = DIV_LAT + MUL_LAT;
  reg [L-1:0] vpipe;
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) vpipe <= 0;
    else        vpipe <= {vpipe[L-2:0], (s_valid & s_ready)};
  end

  wire commit = vpipe[L-1];

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      x_reg <= 0; P_reg <= (32'sd1 <<< WF_P); m_valid <= 1'b0; x_hat <= 0;
    end else begin
      if (load_init) begin
        x_reg <= x0; P_reg <= P0; m_valid <= 1'b0; x_hat <= x0;
      end else if (commit) begin
        x_reg  <= xpred_pipe[DIV_LAT-1] + dx;
        P_reg  <= Pn;
        x_hat  <= xpred_pipe[DIV_LAT-1] + dx;
        m_valid<= 1'b1;
      end else if (m_valid & m_ready) begin
        m_valid <= 1'b0;
      end
    end
  end

endmodule

module div32_pipe #(
  parameter LAT=8,
  parameter WF_P=29  // Default to Q29 matching the system
)(
  input  wire clk, rst_n,
  input  wire signed [31:0] num, den,
  output wire signed [31:0] quo
);
  // FIX: Use 64-bit wire for the shift to prevent overflow
  // We sign-extend 'num' to 64 bits, then shift, then divide.
  wire signed [63:0] num_extended = {{32{num[31]}}, num}; 
  wire signed [63:0] num_scaled   = num_extended <<< WF_P;
  
  // The result of 64-bit / 32-bit fits in 32-bit (assuming K < 1.0)
  wire signed [31:0] q_comb = (den != 0) ? (num_scaled / den) : 32'sd0;

  reg  signed [31:0] qpipe [0:LAT-1];
  integer i;
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
      for (i=0;i<LAT;i=i+1) qpipe[i] <= 0;
    else begin
      qpipe[0] <= q_comb;
      for (i=1;i<LAT;i=i+1)
        qpipe[i] <= qpipe[i-1];
    end
  end
  assign quo = qpipe[LAT-1];
endmodule
