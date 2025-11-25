`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/21/2025 01:31:59 PM
// Design Name: 
// Module Name: kf_scalar
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


// kf_scalar.v  - Q1.15 values, Q3.29 covariances, fully-pipelined
module kf_scalar #(
  parameter WX=16, WF_X=15,    // state/measurement width
  parameter WP=32, WF_P=29,    // covariance width
  parameter DIV_LAT=8,         // match divider IP latency
  parameter MUL_LAT=2          // DSP pipeline depth
)(
  input  wire                   clk,
  input  wire                   rst_n,
  // streaming interface
  input  wire                   s_valid,
  output wire                   s_ready,
  input  wire  signed [WX-1:0]  z_k,      // measurement
  input  wire                   load_init,
  input  wire  signed [WX-1:0]  x0,
  input  wire  signed [WP-1:0]  P0,
  input  wire  signed [WP-1:0]  Q_k,
  input  wire  signed [WP-1:0]  R_k,
  // result stream
  output reg                    m_valid,
  input  wire                   m_ready,
  output reg   signed [WX-1:0]  x_hat
);
  // Ready=1 (throughput=1 sample/clk once pipeline is primed)
  assign s_ready = 1'b1;

  // State (held between updates)
  reg  signed [WX-1:0] x_reg;
  reg  signed [WP-1:0] P_reg;

  // Predict
  wire signed [WX-1:0] x_pred = x_reg;
  wire signed [WP-1:0] P_pred = P_reg + Q_k;

  // Divider: K = P_pred / (P_pred + R_k)
  wire signed [WP-1:0] denom = P_pred + R_k;
  wire signed [WP-1:0] K_q;
  // >>> Replace this with the Xilinx Divider IP wrapper <<<
  div32_pipe #(.LAT(DIV_LAT)) UDIV (
    .clk(clk), .rst_n(rst_n),
    .num(P_pred), .den(denom), .quo(K_q)
  );

  // Align innovation with K
  reg  signed [WX-1:0] innov_pipe [0:DIV_LAT-1];
  reg  signed [WX-1:0] xpred_pipe  [0:DIV_LAT-1];
  reg  signed [WP-1:0] Ppred_pipe  [0:DIV_LAT-1];
  integer i;

  wire signed [WX-1:0] innov0 = z_k - x_pred;

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      for (i=0;i<DIV_LAT;i=i+1) begin
        innov_pipe[i] <= 0; xpred_pipe[i] <= 0; Ppred_pipe[i] <= 0;
      end
    end else begin
      innov_pipe[0] <= innov0; xpred_pipe[0] <= x_pred; Ppred_pipe[0] <= P_pred;
      for (i=1;i<DIV_LAT;i=i+1) begin
        innov_pipe[i] <= innov_pipe[i-1];
        xpred_pipe[i] <= xpred_pipe[i-1];
        Ppred_pipe[i] <= Ppred_pipe[i-1];
      end
    end
  end

  // Multiply pipelines
  reg  signed [WP+WX-1:0] Kinnov [0:MUL_LAT-1];
  reg  signed [2*WP-1:0]  Pupd   [0:MUL_LAT-1];
  wire signed [WP-1:0] one_q = (32'sd1 <<< WF_P);
  wire signed [WP-1:0] one_minus_K = one_q - K_q;

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      for (i=0;i<MUL_LAT;i=i+1) begin Kinnov[i]<=0; Pupd[i]<=0; end
    end else begin
      Kinnov[0] <= $signed(K_q) * $signed({{(WP-WX){innov_pipe[DIV_LAT-1][WX-1]}}, innov_pipe[DIV_LAT-1]});
      Pupd[0]   <= $signed(one_minus_K) * $signed(Ppred_pipe[DIV_LAT-1]);
      for (i=1;i<MUL_LAT;i=i+1) begin
        Kinnov[i] <= Kinnov[i-1];
        Pupd[i]   <= Pupd[i-1];
      end
    end
  end

  wire signed [WX-1:0] dx = Kinnov[MUL_LAT-1][WF_P +: WX];   // >> WF_P
  wire signed [WP-1:0] Pn = Pupd[MUL_LAT-1][WF_P +: WP];

  // Total pipeline latency
  localparam integer L = DIV_LAT + MUL_LAT;

  // Valid pipeline
  reg  [L-1:0] vpipe;
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) vpipe <= 0;
    else        vpipe <= {vpipe[L-2:0], (s_valid & s_ready)};
  end

  // Commit / output
  wire commit = vpipe[L-1];

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      x_reg <= 0; P_reg <= 32'sd1; m_valid <= 1'b0; x_hat <= 0;
    end else begin
      if (load_init) begin
        x_reg <= x0; P_reg <= P0; m_valid <= 1'b0; x_hat <= x0;
      end else if (commit) begin
        x_reg  <= xpred_pipe[DIV_LAT-1] + dx;
        P_reg  <= Pn;
        x_hat  <= xpred_pipe[DIV_LAT-1] + dx;
        m_valid<= 1'b1;
      end else if (m_valid & m_ready) begin
        m_valid<= 1'b0;
      end
    end
  end
endmodule

// Simple pipelined / model; replace with Divider IP in synthesis
module div32_pipe #(
  parameter LAT=8
)(
  input  wire clk, rst_n,
  input  wire signed [31:0] num, den,
  output wire signed [31:0] quo
);
  wire signed [31:0] q_comb = (den!=0) ? (num/den) : 32'sd0;
  reg  signed [31:0] qpipe [0:LAT-1];
  integer i;
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) for (i=0;i<LAT;i=i+1) qpipe[i] <= 0;
    else begin
      qpipe[0] <= q_comb;
      for (i=1;i<LAT;i=i+1) qpipe[i] <= qpipe[i-1];
    end
  end
  assign quo = qpipe[LAT-1];
endmodule

