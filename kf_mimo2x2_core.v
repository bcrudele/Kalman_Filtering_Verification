`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: InnoMountain
// Author: Sri


// kf_mimo2x2_core.v - 2x2 complex = 4 channels � (re,im) = 8 scalars
module kf_mimo2x2_core #(
  parameter WX=16, WF_X=15, WP=32, WF_P=29, DIV_LAT=8, MUL_LAT=2
)(
  input  wire clk, rst_n,
  // one-cycle update strobe on all 8 measurements
  input  wire en,
  input  wire load_init,
  input  wire signed [WX-1:0] x0,
  input  wire signed [WP-1:0] P0, Q_k, R_k,

  input  wire signed [WX-1:0] z11_re,z11_im,z12_re,z12_im,z21_re,z21_im,z22_re,z22_im,
  output wire signed [WX-1:0] h11_re,h11_im,h12_re,h12_im,h21_re,h21_im,h22_re,h22_im,

  output wire valid_all,
  output reg  [15:0] last_latency
);
  // s_valid = en same cycle for all
  wire [7:0] v;
  wire [7:0] ready;
  assign valid_all = &v;

  // latency counter (en ? valid_all)
  reg measuring; reg [15:0] cnt;
  always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin measuring<=0; cnt<=0; last_latency<=0; end
    else if (load_init) begin measuring<=0; cnt<=0; last_latency<=0; end
    else begin
      if (en & !measuring) begin measuring<=1; cnt<=0; end
      else if (measuring)   cnt <= cnt + 1;
      if (measuring & valid_all) begin measuring<=0; last_latency<=cnt; end
    end
  end

  // 8 scalar filters (compact instantiation)
  kf_scalar #(.WX(WX),.WF_X(WF_X),.WP(WP),.WF_P(WF_P),.DIV_LAT(DIV_LAT),.MUL_LAT(MUL_LAT)) k11r
    (.clk(clk),.rst_n(rst_n),.s_valid(en),.s_ready(ready[0]),.z_k(z11_re),.load_init(load_init),
     .x0(x0),.P0(P0),.Q_k(Q_k),.R_k(R_k),.m_valid(v[0]),.m_ready(1'b1),.x_hat(h11_re));

  kf_scalar #(.WX(WX),.WF_X(WF_X),.WP(WP),.WF_P(WF_P),.DIV_LAT(DIV_LAT),.MUL_LAT(MUL_LAT)) k11i
    (.clk(clk),.rst_n(rst_n),.s_valid(en),.s_ready(ready[1]),.z_k(z11_im),.load_init(load_init),
     .x0(x0),.P0(P0),.Q_k(Q_k),.R_k(R_k),.m_valid(v[1]),.m_ready(1'b1),.x_hat(h11_im));

  kf_scalar #(.WX(WX),.WF_X(WF_X),.WP(WP),.WF_P(WF_P),.DIV_LAT(DIV_LAT),.MUL_LAT(MUL_LAT)) k12r
    (.clk(clk),.rst_n(rst_n),.s_valid(en),.s_ready(ready[2]),.z_k(z12_re),.load_init(load_init),
     .x0(x0),.P0(P0),.Q_k(Q_k),.R_k(R_k),.m_valid(v[2]),.m_ready(1'b1),.x_hat(h12_re));

  kf_scalar #(.WX(WX),.WF_X(WF_X),.WP(WP),.WF_P(WF_P),.DIV_LAT(DIV_LAT),.MUL_LAT(MUL_LAT)) k12i
    (.clk(clk),.rst_n(rst_n),.s_valid(en),.s_ready(ready[3]),.z_k(z12_im),.load_init(load_init),
     .x0(x0),.P0(P0),.Q_k(Q_k),.R_k(R_k),.m_valid(v[3]),.m_ready(1'b1),.x_hat(h12_im));

  kf_scalar #(.WX(WX),.WF_X(WF_X),.WP(WP),.WF_P(WF_P),.DIV_LAT(DIV_LAT),.MUL_LAT(MUL_LAT)) k21r
    (.clk(clk),.rst_n(rst_n),.s_valid(en),.s_ready(ready[4]),.z_k(z21_re),.load_init(load_init),
     .x0(x0),.P0(P0),.Q_k(Q_k),.R_k(R_k),.m_valid(v[4]),.m_ready(1'b1),.x_hat(h21_re));

  kf_scalar #(.WX(WX),.WF_X(WF_X),.WP(WP),.WF_P(WF_P),.DIV_LAT(DIV_LAT),.MUL_LAT(MUL_LAT)) k21i
    (.clk(clk),.rst_n(rst_n),.s_valid(en),.s_ready(ready[5]),.z_k(z21_im),.load_init(load_init),
     .x0(x0),.P0(P0),.Q_k(Q_k),.R_k(R_k),.m_valid(v[5]),.m_ready(1'b1),.x_hat(h21_im));

  kf_scalar #(.WX(WX),.WF_X(WF_X),.WP(WP),.WF_P(WF_P),.DIV_LAT(DIV_LAT),.MUL_LAT(MUL_LAT)) k22r
    (.clk(clk),.rst_n(rst_n),.s_valid(en),.s_ready(ready[6]),.z_k(z22_re),.load_init(load_init),
     .x0(x0),.P0(P0),.Q_k(Q_k),.R_k(R_k),.m_valid(v[6]),.m_ready(1'b1),.x_hat(h22_re));

  kf_scalar #(.WX(WX),.WF_X(WF_X),.WP(WP),.WF_P(WF_P),.DIV_LAT(DIV_LAT),.MUL_LAT(MUL_LAT)) k22i
    (.clk(clk),.rst_n(rst_n),.s_valid(en),.s_ready(ready[7]),.z_k(z22_im),.load_init(load_init),
     .x0(x0),.P0(P0),.Q_k(Q_k),.R_k(R_k),.m_valid(v[7]),.m_ready(1'b1),.x_hat(h22_im));
endmodule
