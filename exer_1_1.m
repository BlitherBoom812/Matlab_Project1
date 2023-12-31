
global sample_freq;
global base_tone_freq;
global beat_time;
sample_freq = 8e3;
% 1 = F
base_tone_freq = 349.23;
% beat_time = 0.5, or BPM = 120
beat_time = 0.5;
% 曲谱
tone = [5, 5, 6, 2, 1, 1, -1, 2];
beat = [1, 0.5, 0.5, 2, 1, 0.5, 0.5, 2];

first_part = cell2mat(arrayfun(@(x, y) gen_tune(x, y), tone, beat, UniformOutput=false));
sound(first_part, sample_freq);

function y = gen_tune(tone, beat)
    [freq, width] = trans_freq_width(tone, beat);
    y = gen_tune_from_freq_width(freq, width);
end

function y = gen_tune_from_freq_width(freq, width)
    global sample_freq;
    global amp;
    global tone_mapping;
    amp = 1;
    % 将唱名映射至以2^(1/12)为底的指数, 1对应指数为1
    tone_mapping = [0, 2, 4, 5, 7, 9, 11];

    time_step = sample_freq^(-1);
    t = 0:time_step:width;
    y = amp * sin(2 * pi * freq * t);
end