clear;
close all;
clc;

[fmt, fs] = audioread('音乐合成所需资源\fmt.wav');
plot_wave = @(wave) plot(plot_wave_t(wave, fs), wave);
% sound(fmt, fs);
raw = fmt .^ 2;

[env, ~] = envelope(raw, 5,'peak');
for i = 1:2
    [env, ~] = envelope(env, 90,'peak');
end
env = max(env, 0.0026);
figure(1);
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
[peaks, valleys] = wave_find_peak(env, 2.4, 0.12);
t = plot_wave_t(env, fs);
plot(t(peaks), env(peaks), 'o', 'MarkerSize', 5, 'MarkerFaceColor', 'none', 'Color', 'red');
plot(t(valleys), env(valleys), 'x', 'MarkerSize', 5, 'MarkerFaceColor', 'none', 'Color', 'blue');
title('envelope');
 
fprintf("节拍个数： %d\n", length(peaks));


figure("Position", [20, 20, 1200, 800]);

h = waitbar(0, '分析音调...');

for i = 1:length(peaks)
    t = plot_wave_t(fmt, fs);
    tone = fmt(valleys(i):valleys(i + 1));
    tone = tone(1:round(length(tone) * 0.8));
    tone = tone .* gausswin(length(tone));
    tone = resample(tone, 10, 1);
    tone = resample(tone, 1, 10);
    for j = 1:10
        tone = [tone;tone];
    end
    % figure(2);
    % plot(tone);
    % tone = resample(tone, 1, 1);

    Tone = abs(fftshift(fft(tone)));
    f = linspace(-fs/2, fs/2, length(Tone));
    Tone = Tone(f > 0);
    f = f(f > 0);

    [max_amp, max_idx] = max(Tone);
    [freq_amp, freq_index] = findpeaks(Tone);
    
    ths = 0.3;
    filtered_amp = freq_amp(freq_amp / max_amp > ths);
    filtered_index = freq_index(freq_amp / max_amp > ths);

    % 暴力搜索
    search_index = filtered_index(filtered_index <= max_idx);
    base_freq_idx = max_idx;
    search_valid = false;
    ths2 = 0.025;
    search_result = search_index(abs(round(max_idx ./ search_index) - max_idx ./ search_index) < ths2);
    if (~isempty(search_result))
        max_int = max(round(max_idx ./ search_result));
        search_result = search_result(abs(max_int - max_idx ./ search_result) < ths2);
        [~, min_idx] = min(abs(round(log(f(search_result) / 220) * 12 / log(2)) - log(f(search_result) / 220) * 12 / log(2)));
        final_result = search_result(min_idx);
        base_freq_idx = min(final_result);
        search_valid = true;
    end
    
    base_freq = f(base_freq_idx);
    if search_valid
        fprintf("节拍 \t%d 的基频为 \t%f, 最大幅度频率为 \t%f\n", i, base_freq, f(max_idx));
    else
        fprintf("节拍 \t%d 的基频未搜到！\n", i);
    end



    waitbar(i/length(peaks), h, sprintf('分析音调... %d%%', round(i/length(peaks) * 100)));
    subplot(5, 6, i);
    plot(f, Tone);
    set(gca, 'FontSize', 5); % 设置当前坐标轴的字体大小为12
    title(['Beat ', num2str(i), ', Freq = ', num2str(base_freq)]);
    xlabel('freq/Hz', 'FontSize', 5);
    ylabel('Amp', 'FontSize', 5);
end

close(h);

function [tone, standard_f] = get_tune_name(base_f)
    % 定义音调值与音名的对应关系
    tone_map = containers.Map([220, 246.94, 293.66, 329.63, 196, 174.61, 130.81, 349.23, 261.63, 146.83, 207.65], ...
        {'A0', 'B0', 'D1', 'E1', 'G0', 'F0', 'C0', 'F1', 'C1', 'D0', 'bA0'});
    
    % 判断基频值与音调值的差距，并输出对应的音名
    tone = '';
    tolerance = 0.02;
    for freq = keys(tone_map)
        if abs(base_f/freq - 1) < tolerance
            tone = tone_map(freq);
            standard_f = freq;
            break;
        end
    end
end

function t = plot_wave_t(wave, fs)
    t = (0:1/fs:((length(wave) - 1) / fs))';
end