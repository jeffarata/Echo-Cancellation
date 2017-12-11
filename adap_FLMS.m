% Jeff Arata
% 12/10/17
%
% This function implements a Fast Least Mean Squares algorithm for echo
% cancellation. It operates in the frequency domain.

function [ h, e, y ] = adap_FLMS( x, d, M, lambda, mu )
% Inputs:
%
% x     - the input signal
% d     - the desired signal
% M     - the filter length
% lambda- the forgetting factor - <= 1 - try 0.95
% mu    - the step size - quite small, try 0.01 - 0.03
%
% Outputs:
%
% h     - the filter coefficients
% e     - the error


% Definitions:
%
% {var}_freq    - indicates frequency domain variable
% N             - integer multiple of block length M, input signal
%                 shortened to this length of N

% Initialize power of FFT coefficients
P_freq = 0.01*ones(2*M,1);
% Truncate x to a multiple of M if it is not already
N = length(x);
if (mod(N,M) == 0) | (mod(M,N) == 0)
elseif mod(N,M) < mod(M,N)
    x = x(1:end-mod(N,M));
else
    x = x(1:end-mod(M,N));
end
N = length(x);
% Ensures x and d are rows to start
x = x(:)';
d = d(:)';

e = zeros(length(x),1);      % Initialize error and output storage
y = zeros(length(x),1);

h_freq = zeros(2*M,1);       % initialize

for k = 1:N/M-1
    x_k_freq = fft(x(M*k-M+1:M*k+M)', 2*M);     % get input signal block
    
    y_k = ifft(x_k_freq.*h_freq, 2*M);  % filtered output signal block
    y_k = y_k(end-M+1:end);
    y(M*k-M+1:M*k) = y_k;               % output signal storage
    
    d_k = d(k*M+1:k*M+M)';              % desired signal block
    
    e(M*k-M+1:M*k) = d_k - y_k;         % storage of error signal
    e_k = d_k - y_k;                    % shorthand for current time error
    e_k_freq = fft( [zeros(M,1); e_k], 2*M );
    
    P_freq = lambda*P_freq + (1-lambda)*conj(x_k_freq).*x_k_freq; % update Power
    
    D_freq = 1./P_freq;
    phi_k_freq = D_freq.*conj(x_k_freq).*e_k_freq;  % gradient calculation
    phi_k = ifft(phi_k_freq, 2*M);
    phi_k = phi_k(1:M);
    
    h_freq = h_freq + mu*fft( [phi_k; zeros(M,1)], 2*M );   % update filter coefficients  
    
end

h = ifft(h_freq, 2*M);  % time domain filter coefficients
h = h(1:M);
h = real(h(:));         % real part of filter coefficients

e = real(e(:));         % real part of time domain error
y = real(y(:));         % real part of time domain output

end
