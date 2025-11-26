% Fixed-point MMSE Detection (Q1.15 input, Q4.11 output)
F = fimath('RoundingMethod','Nearest','OverflowAction','Saturate');

% 8x8 channel matrix (example values, replace with your own)
A = fi([ 0.50 0.25 0.10 0.05 0.30 0.12 0.08 0.02;
         0.75 0.50 0.20 0.10 0.25 0.18 0.05 0.03;
         0.30 0.40 0.60 0.20 0.15 0.22 0.10 0.07;
         0.10 0.20 0.30 0.50 0.12 0.25 0.09 0.04;
         0.05 0.10 0.08 0.04 0.60 0.35 0.20 0.15;
         0.07 0.06 0.12 0.09 0.28 0.55 0.18 0.10;
         0.02 0.04 0.06 0.03 0.15 0.12 0.45 0.22;
         0.01 0.02 0.03 0.01 0.10 0.08 0.20 0.40 ], ...
         1, 16, 15, F);

N0 = fi(0.1, 1, 16, 15, F);  % noise variance (Q1.15)

% ---------------------------------------------------------
% LU decomposition (MATLAB LU requires double precision)
% ---------------------------------------------------------
[L, U, P] = lu(double(A));
I = eye(8);
A_inv = fi(U \ (L \ (P * I)), 1, 16, 11, F);

disp('Inverse (Q4.11):');
disp(A_inv);

% ---------------------------------------------------------
% MMSE detection matrix: W = (H'*H + N0*I)^(-1) * H'
% ---------------------------------------------------------
Hd = double(A);
R = Hd' * Hd + double(N0) * eye(8);
W = fi(R \ Hd', 1, 16, 11, F);

disp('MMSE Detection Matrix (Q4.11):');
disp(W);
