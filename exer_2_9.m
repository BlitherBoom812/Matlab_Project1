clear;
close all;
clc;

[fmt, fs] = audioread('音乐合成所需资源\fmt.wav');
plot_wave = @(wave) plot(plot_wave_t(wave, fs), wave);
sound(fmt, fs);
raw = fmt .^ 2;

[env, ~] = envelope(raw, 5,'peak');
for i = 1:2
    [env, ~] = envelope(env, 90,'peak');
end
env = max(env, 0.0026);
figure(2);
subplot(3, 1, 1);
plot_wave(fmt);
title('fmt');
subplot(3, 1, 2);
plot_wave(raw);
title("square");
subplot(3, 1, 3);
plot_wave(env);
hold on;
wave_find_peak = @(y, ratio, interval) my_find_peak(y, ratio, round(interval * fs), fs);
peaks = wave_find_peak(env, 2.4, 0.12);
t = plot_wave_t(env, fs);
plot(t(peaks), env(peaks), 'o', 'MarkerSize', 5, 'MarkerFaceColor', 'none');
title('envelope');
 
fprintf("节拍个数： %d\n", length(peaks));

function t = plot_wave_t(wave, fs)
    t = (0:1/fs:((length(wave) - 1) / fs))';
end