% Fixed-point MMSE Detection (Q1.15 input, Q4.11 output)
F = fimath('RoundingMethod','Nearest','OverflowAction','Saturate');
A = fi([0.5 0.25; 0.75 0.5], 1, 16, 15, F);
N0 = fi(0.1, 1, 16, 15, F); % noise variance

% LU decomposition (MATLAB LU requires double)
[L,U,P] = lu(double(A));
I = eye(2);
A_inv = fi(U \ (L \ (P*I)), 1, 16, 11, F);
disp('Inverse (Q4.11):')
disp(A_inv)

% MMSE detection matrix:
Hd = double(A);
R = Hd' * Hd + double(N0) * eye(2);
W = fi(R \ Hd', 1, 16, 11, F);

disp('MMSE Detection Matrix (Q4.11):')
disp(W)
