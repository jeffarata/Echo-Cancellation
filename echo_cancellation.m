% Jeff Arata
% 11/29/17

% This script and the used functions simulate a conference call that would
% otherwise have echoes, and instead cancels out those echoes. This
% generally follows the mathworks example on echo cancellation uses
% functions I've written myself. This script still includes the comment
% blocks from the Mathworks demo.

clear;
clc;
close all;

full = 1;           % 1 = Playback all signals in order
partial = 0;        % 1 = Playback just the output of the adaptive filter and
                    % the echo cancelled signal

%{
The Room Impulse Response

You first need to model the acoustics of the loudspeaker-to-microphone 
signal path where the speakerphone is located. Use a long finite impulse 
response filter to describe the characteristics of the room. The following
code generates a random impulse response that is not unlike what a 
conference room would exhibit. Assume a system sample rate of 16000 Hz.
%}

fs = 16000;
M = fs/2 + 1;

[B,A] = cheby2(4,20,[0.1 0.7]);

figure(1)
freqz(B,A);
title('Response of Ideal Room')

% the room impulse response - taken from mathworks's example
RIR = (log(0.01 + 0.99*rand(1,M)).*sign(rand(1,M)-0.5).*exp(-0.002*(1:M)))';
% the filtered room impulse response
RIR = filter(B,A,RIR);
% Normalize impulse response, amplitude becomes quite small so multiply by
% an arbitrary constant so that it's close to but less than 1 at most.
RIR = RIR/norm(RIR)*4; 
figure(2)
plot(0:1/fs:0.5, RIR)
axis([0 0.5 -1 1])
xlabel('Time in Seconds')
ylabel('Amplitude')
title('Room Impulse Response')

%{
PSD = abs(fft(RIR));
PSD = (1/(fs*length(PSD)))*(PSD(1:(floor(length(PSD)/2 + 1))).^2);
PSD(2:end-1) = 2*PSD(2:end-1);
PSD = 10*log10(PSD);
figure(3)
plot(PSD)
%}
%{
% sample rate initialize

% create an impulse response by way of a transfer function
% create an IIR representing a room's impulse response in frequency domain
    % use an IIR
    % highpass and lowpass the more extreme values (bandpass filter!)
    % check out filter's response


% set off an signal in this digital "room" (the IIR)
% the signal set off should have some randomness to it, and be length fs/2
% + 1
% this is the RIR in time domain


%X = noisy/random input signal of length fs/2 + 1
%RIR = filter(B,A,X);

% visualize the RIR as a finite impulse response (time domain)
%}   
%{
The Near-End Speech Signal

The teleconferencing system's user is typically located near the system's 
microphone. Here is what a male speech sounds like at the microphone.
%}

load nearspeech

framelength = 2048;

if full
    sound(v, fs)
    fprintf('Now playing Near Speech, unfiltered.\n')
end

% Plotting
v_len = length(v);
t_len = v_len / fs;
t_plot = 0:1/fs:t_len-1/fs;

figure(3)
subplot(3, 1, 1)
plot(t_plot, v')
ylabel('Amplitude')
title('Nearspeech, No Filter')
axis([0 t_plot(end) -1.25 1.25])

if full
    pause(36)
end

%{
% playback nearspeech - perhaps visualizing the playback by showing the
% waveform in a player of some kind

    % do so by plotting and playing at the same time 
        % get samples block by block (window by window?)
        % send the block of sample to a player
        % plot that block
        % loop through this so it happens in realtime until there are no
        % more samples - the point of this is to simulate real time
        % processing

        % check out the coursera video on real time processing
        % will need an input and output buffer
        % whatever action you want to do to output, like filtering or the
        % echo cancelling, happens in between the input and output buffers
%}
%{
The Far-End Speech Signal

In a teleconferencing system, a voice travels out the loudspeaker, bounces
around in the room, and then is picked up by the system's microphone. 
Listen to what the speech sounds like if it is picked up at the microphone 
without the near-end speech present.
%}

load farspeech        
        
x = filter(RIR, 1, x);

if full
    sound(x, fs)
    fprintf('Now playing Far Speech, filtered by our room model.\n')
end

% Plotting
x_len = length(x);
t_len = x_len / fs;
t_plot = 0:1/fs:t_len-1/fs;

figure(3)
subplot(3,1,2)
plot(t_plot, x')
ylabel('Amplitude')
title('Farspeech, Room Filtered')
axis([0 t_plot(end) -1.25 1.25])

if full
    pause(36)
end

%{
% similarly playback/plot farspeech, but this time with the RIR applied to
% the farspeech
    % Extract the speech samples from the input signal
    % Add the room effect to the far-end speech signal
    % Send the speech samples to the output audio device
    % Plot the signal
    % Log the signal for further processing
    % loop through this until out of samples
%}    
%{
The Microphone Signal

The signal at the microphone contains both the near-end speech and the 
far-end speech that has been echoed throughout the room. The goal of the 
acoustic echo canceler is to cancel out the far-end speech, such that only 
the near-end speech is transmitted back to the far-end listener.
%}

mic_signal = v + x + 0.001*randn(v_len, 1);

if full
    sound(mic_signal, fs)
    fprintf('Now playing Microphone Signal, near and far speech with noise.\n')
end

% Plotting
figure(3)
subplot(3,1,3)
plot(t_plot, mic_signal')
xlabel('Time in Seconds')
ylabel('Amplitude')
title('Microphone Signal (Near and Filtered Farspeech with Noise)')
axis([0 t_plot(end) -1.25 1.25])
    
if full
    pause(36)
end

%{
% playback near and far speech with noise (picked up from the line)    
    % Microphone signal = echoed far-end + near-end + noise
    % Send the speech samples to the output audio device
    % Plot the signal
    % Log the signal
    % loop through until out of signal
%}    
%{
The Frequency-Domain Adaptive Filter (FDAF)

The algorithm in this example is the Frequency-Domain Adaptive Filter 
(FDAF). This algorithm is very useful when the impulse response of the 
system to be identified is long. The FDAF uses a fast convolution technique 
to compute the output signal and filter updates. This computation executes 
quickly in MATLAB®. It also has fast convergence performance through 
frequency-bin step size normalization. Pick some initial parameters for the
filter and see how well the far-end speech is cancelled in the error 
signal.
%}

M = 32;
lambda = 0.98;
mu = 0.025;
    
[h, e, y] = adap_FLMS(mic_signal, x,  M, lambda, mu);    

if full | partial
    sound(y, fs)
    fprintf('Now playing Adaptive Filter Output, modelling Far Speech.\n')
end
    
% Delay output by M samples, which should be very close to far speech with 
% room filter then subtract this from the mic_signal to be left with just 
% the near speech without the (otherwise would be echoed back) far speech 
% signal

delay_y = [zeros(M,1); y];
mic_signal = [mic_signal; zeros(M,1)];
echo_cancelled_signal = mic_signal - delay_y;

% Plotting
t_len = length(e) / fs;
t_plot = 0:1/fs:t_len-1/fs;

figure(4)
subplot(4, 1, 1)
plot(t_plot, e)
ylabel('Amplitude')
title('Error Signal')
axis([0 t_plot(end) -1.25 1.25])

t_len = length(y) / fs;
t_plot = 0:1/fs:t_len-1/fs;

figure(4)
subplot(4, 1, 2)
plot(t_plot, y)
ylabel('Amplitude')
title('Output Signal from Adaptive Filter')
axis([0 t_plot(end) -1.25 1.25])

if full | partial
    pause(36)
end
    
sound(echo_cancelled_signal, fs)
fprintf('Now playing Echo Cancelled Signal, the Microphone Signal - Adaptive Filter Output.\n')

t_len = length(echo_cancelled_signal) / fs;
t_plot = 0:1/fs:t_len-1/fs;

figure(4)
subplot(4, 1, 3)
plot(t_plot, echo_cancelled_signal)
ylabel('Amplitude')
title('Echo Cancelled Signal')
axis([0 t_plot(end) -1.25 1.25])




%{
% make the adaptive filter or throw signal through adaptive filter
% make it a Frequency Domain Adaptive Filter?

% there is some plotting here with mathworks's implementation
%}
%{
Echo Return Loss Enhancement (ERLE)

Since you have access to both the near-end and far-end speech signals, you 
can compute the echo return loss enhancement (ERLE), which is a smoothed 
measure of the amount (in dB) that the echo has been attenuated. From the 
plot, observe that you achieved about a 35 dB ERLE at the end of the 
convergence period.
%}

power_d = x.^2;     % power of desired signal, x, the room filtered farspeech
power_e = e.^2;     % power of error signal, put out by adaptive algorithm

B = [ones(1,512)];            % Lowpass filter coefficients
A = [1];      
power_d = filter(B,1,power_d);
power_e = filter(B,1,power_e);

erle = 10*log10(power_d./power_e);  % Echo return loss enchancement calculation

t_len = length(erle) / fs;
t_plot = 0:1/fs:t_len-1/fs;

figure(4)                           % Plotting
subplot(4,1,4)
plot(t_plot, erle)
xlabel('Time in Seconds')
ylabel('dB')
title('Echo Return Loss Enhancement')
axis([0 t_plot(end) 0 50])

%{
% do some research here as to what the echo return loss enhancement is and
% how to calculate it

% otherwise, apply the adaptive filter here using an appropriate step size,
% or mu value

% Apply FDAF
% Send the speech samples to the output audio device
% Compute ERLE
% Plot near-end, far-end, microphone, AEC output and ERLE
% loop through this until out of samples - simulates real time processing
%}
%{
Effects of Different Step Size Values
To get faster convergence, you can try using a larger step size value.
However, this increase causes another effect: the adaptive filter is 
"mis-adjusted" while the near-end speaker is talking. Listen to what 
happens when you choose a step size that is 60% larger than before.
%}
%{
% careful with step sizes here (the mu value)
% this just lets you play with the effects of a different step size

% otherwise this is the same as the above step of applying the adaptive
% filter
%}
%{
Echo Return Loss Enhancement Comparison

With a larger step size, the ERLE performance is not as good due to the 
misadjustment introduced by the near-end speech. To deal with this 
performance difficulty, acoustic echo cancellers include a detection scheme 
to tell when near-end speech is present and lower the step size value over 
these periods. Without such detection schemes, the performance of the 
system with the larger step size is not as good as the former, as can be 
seen from the ERLE plots.
%}
%{
% no code came after this, just a blurb talking about what's gone on
%}