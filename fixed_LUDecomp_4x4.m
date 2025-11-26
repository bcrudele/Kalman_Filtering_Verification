% Fixed-point MMSE Detection (Q1.15 input, Q4.11 output)
F = fimath('RoundingMethod','Nearest','OverflowAction','Saturate');

% 4x4 channel matrix (example values – replace with your real matrix)
A = fi([ 0.50  0.25  0.10  0.05;
         0.75  0.50  0.20  0.10;
         0.30  0.40  0.60  0.20;
         0.10  0.20  0.30  0.50 ], ...
         1, 16, 15, F);

N0 = fi(0.1, 1, 16, 15, F);  % noise variance

%% -------- LU Decomposition (Must be in double) ----------
[L, U, P] = lu(double(A));

I = eye(4);
A_inv_double = U \ (L \ (P * I));   % explicit inversion
A_inv = fi(A_inv_double, 1, 16, 11, F);

disp('Inverse (Q4.11):')
disp(A_inv)

%% -------- MMSE Detection Matrix W = (H^H H + N0 I)^(-1) H^H ----------
Hd = double(A);
R = Hd' * Hd + double(N0) * eye(4);   % 4x4 regularized Gram matrix

W_double = R \ Hd';                   % 4x4 × 4x4 → 4x4 MMSE filter
W = fi(W_double, 1, 16, 11, F);

disp('MMSE Detection Matrix (Q4.11):')
disp(W)
