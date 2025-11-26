% -------------------------------------------------------------
% Multi-sample Kalman Filter
% -------------------------------------------------------------

clear; clc;

% Parameters
x = 0;          % x0
P = 1;          % P0
Q = 0;          % process noise
R = 1;          % measurement noise

measurements = [1000, 1000];   % <-- modify

N = length(measurements);

x_hat = zeros(1, N);
K_vec = zeros(1, N);

for k = 1:N

    z = measurements(k);

    % Prediction
    x_pred = x;          
    P_pred = P + Q;      

    % Kalman gain
    K = P_pred / (P_pred + R);

    % Update
    x = x_pred + K * (z - x_pred);
    P = (1 - K) * P_pred;

    % Save results
    x_hat(k) = x;
    K_vec(k) = K;
end

% Output results
disp('Final estimate:');
disp(x);

disp('All estimates for each sample:');
disp(x_hat);

% Optional plot
figure; 
plot(x_hat, 'b-o', 'LineWidth', 1.5);
xlabel('Sample index');
ylabel('Estimate');
title('Kalman Filter Estimates');
grid on;
