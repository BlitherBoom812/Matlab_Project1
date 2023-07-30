
clear
close all;
clc

sample_freq = 16e3;
% 1 = F
base_tone_freq = 349.23;
% beat_time = 0.5, or BPM = 120
beat_time = 0.5;
amp = 1;
% 将唱名映射至以2^(1/12)为底的指数, 1对应指数为1
tone_mapping = [0, 2, 4, 5, 7, 9, 11];
overlap_ratio = 0.1/0.95;

music = get_dfh(amp, sample_freq, tone_mapping, overlap_ratio, base_tone_freq, beat_time);

sound(music, sample_freq);
plot(music);

function result = get_dfh(amp, sample_freq, tone_mapping, overlap_ratio, base_tone_freq, beat_time)
    
    % 曲谱
    tone = [5, 5, 6, 2, 1, 1, -1, 2];
    beat = [1, 0.5, 0.5, 2, 1, 0.5, 0.5, 2];
    
    % 初始化空数组用于存储结果
    result = [];
    loop = 1:length(tone);
    % 循环迭代
    overlap_last = 0;
    for i = loop
        % 调用 gen_tune 函数
        [local_result, overlap] = gen_tune(tone(i), beat(i), amp, sample_freq, tone_mapping, overlap_ratio, base_tone_freq, beat_time);
        % 将结果的首尾相加，中间拼接
        if i == 1
            % 第一次迭代，直接将结果添加到结果数组
            result = local_result;
        else
            % 非第一次迭代，将上一次结果的末尾与当前结果的开头相加，并将结果添加到结果数组
            result = [result(1:end-overlap_last), (result(end-overlap_last+1:end) + local_result(1:overlap_last)), local_result(overlap_last+1:end)];
            overlap_last = overlap;
        end
    end
end

function [result, overlap] = gen_tune(tone, beat, amp, sample_freq, tone_mapping, overlap_ratio, base_tone_freq, beat_time)

    [freq, width] = trans_freq_width(tone, beat, base_tone_freq, beat_time, tone_mapping);
    
    [y0, y1, y2, y3] = generate_fixed(width, sample_freq);
    
    wave = gen_waveform(freq, length([y0, y1, y2, y3]), amp, sample_freq);

    result = wave .* [y0, y1, y2, y3];
    overlap = round(overlap_ratio * length(y3));
end

function wave = gen_waveform(freq, len, amp, sample_freq)

   time_step = sample_freq^(-1);
   t = 0:time_step:(len-1) * time_step;

   harmonic = [1, 1.46, 0.96, 1.10, 0.05, 0.11, 0.36, 0.12, 0.14, 0.06];
   for m = 1:length(harmonic)
       if m == 1
           wave = amp * sin(2 * pi * freq * t);
       else
           wave = wave + harmonic(m) * amp * sin(2 * pi * m * freq * t);
       end
   end
end