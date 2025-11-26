# Project README

## TLDR;
MATLAB scripts and Verilog RTL files for fixed-point LU decomposition and Kalman filtering.

## File Summary

### MATLAB Scripts
- **fixed_LUDecomp_2x2.m** – Fixed-point LU decomposition for 2x2 matrices.  
- **fixed_LUDecomp_4x4.m** – Fixed-point LU decomposition for 4x4 matrices.  
- **fixed_LUDecomp_8x8.m** – Fixed-point LU decomposition for 8x8 matrices.  
- **kalmans.m** – Test script for Kalman filter simulations.  

### Verilog RTL
- **fpga_top_min.v** – Top-level FPGA module for 2x2 implementation.  
- **kf_mimo2x2_core.v** – 2x2 MIMO Kalman filter core module.  
- **kf_scalar.v** – Scalar Kalman filter module (1x1 pipe). 

### Testbenches
- **tb_fpga_top_min.v** – Testbench for `fpga_top_min.v`.  
- **tb_fpga_top_min_behav.wcfg** – Waveforms for `fpga_top_min.v`.  
- **tb_kf_scalar.v** – Testbench for `kf_scalar.v`.  
- **tb_kf_scalar_behav.wcfg** – Waveforms for `kf_scalar.v`.  

## Notes
- MATLAB scripts may use doubles, *in progress*
- No timing reports / stress testing has been done for my RTL implementation
