clear;
close all;
clc;

fs = 8000;
load('音乐合成所需资源\Guitar.MAT');

figure;

subplot(3, 1, 1);
W1 = fft(wave2proc);
W1 = fftshift(W1);
W1 = abs(W1);
freq = linspace(-fs/2, fs/2, length(W1));
plot(freq,W1);
title('10 periods');

subplot(3, 1, 2);
W2 = fft(repmat(wave2proc, 10, 1));
W2 = fftshift(W2);
W2 = abs(W2);
freq = linspace(-fs/2, fs/2, length(W2));
plot(freq, W2);
title('100 periods');

subplot(3, 1, 3);
W3 = fft(repmat(wave2proc, 100, 1));
W3 = fftshift(W3);
W3 = abs(W3);
freq = linspace(-fs/2, fs/2, length(W3));
plot(freq, W3);
title('1000 periods');

[W, f] = findpeaks(W3, freq);

analyze(W3, freq);

% 
% 基频：329.40Hz,音调：e1。
% 谐波分量有
% 
%           2.00, 3.00, 4.00, 5.00, 6.00, 7.00, 8.00, 9.00, 10.00
% 幅度分别为
%           1.46, 0.96, 1.10, 0.05, 0.11, 0.36, 0.12, 0.14, 0.06