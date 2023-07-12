
global sample_freq;
global amp;
global base_tone_freq;
global beat_time;
global tone_mapping;
sample_freq = 8e3;
amp = 1;
% 1 = F
base_tone_freq = 349.23;
% beat_time = 0.5, or BPM = 120
beat_time = 0.5;
% 将唱名映射至以2为底的指数
tone_mapping = [1, 3, 5, 7, 8, 10, 12];
% 曲谱
tone = [5, 5, 6, 2, 1, 1, -1, 2];
beat = [1, 0.5, 0.5, 2, 1, 0.5, 0.5, 2];

first_part = cell2mat(arrayfun(@(x, y) gen_tune(x, y), tone, beat, UniformOutput=false));
sound(first_part);

function y = gen_tune(tone, beat)
    [freq, width] = trans_freq_width(tone, beat);
    y = gen_tune_from_freq_width(freq, width);
end

function y = gen_tune_from_freq_width(freq, width)
    global sample_freq;
    global amp;
    time_step = sample_freq^(-1);
    t = 0:time_step:width;
    y = amp * sin(2 * pi * freq * t);
end

function [freq, width] = trans_freq_width(tone, beat)
    global base_tone_freq;
    global beat_time;
    global tone_mapping;
    remain = mod(tone, 7);
    exponent = tone_mapping(remain) + (tone - remain)/7 * 12;
    freq = base_tone_freq * (2^((exponent - 1)/12));
    width = beat * beat_time;
end