
clear
close all;
clc

sample_freq = 16e3;
% 1 = D
base_tone_freq = 293.66;
beat_time = 1.25;
amp = 1;
% 将唱名映射至以2^(1/12)为底的指数, 1对应指数为1
tone_mapping = [0, 2, 4, 5, 7, 9, 11];
overlap_ratio = 0.1/0.95;

% 曲谱

bar1 = {
    {
        [-5,    5,      6,      -2,     1,      2,      -4,     3,      5,      -2];
        [1,     0.5,    0.5,    1.5,    0.25,   0.25,   1.5,    0.25,   0.25,   2]
    };
    {
        [-3,    -100,   1,      -100,   -2,     -100,   0];
        [1,     1,      1.5,    0.5,    1.5,    0.5,    2]
    };
    {
        [-1,    -100,   3,      -100,   0,      -100,   2];
        [1,     1,      1.5,    0.5,    1.5,    0.5,    2]
    };
    {
        [-12,   -11,    -10,    -8,     -9,     -10,    -13];
        [1,     1,      1,      1,      1,      1,      2]
    }
};

bar2 = {
    {
        [-5,    8,      6,      5,      -2,     1,      2,      -4,     5,      3,     -2];
        [0.5,   0.5,    0.5,    0.5,    1.5,    0.25,   0.25,   1.5,    0.25,   0.25,  2]
    };
    {
        [-3,    -100,       1,      -100      -2,   -100,   0];
        [0.5,   1.5,        1.5,    0.5,      1.5,  0.5,    2]
    };
    {
        [-1,    -100,       3,      -100,     0,    -100,   2];
        [0.5,   1.5,        1.5,    0.5,      1.5,  0.5,    2]
    };
    {
        [-12,   -11,    -10,    -8,     -9,     -10,    -13];
        [1,     1,      1,      1,      1,      1,      2]
    }
};

% 句柄定义
my_play_multi = @(bar) play_multi(bar, amp, sample_freq, tone_mapping, overlap_ratio, base_tone_freq, beat_time);

music1 = my_play_multi(bar1);
music2 = my_play_multi(bar2);

music = [music1, music2];

t = 0:1/sample_freq:(length(music) - 1)/sample_freq;

tin = timeseries(music',t);
tout = resample(tin, t);
music = tout.Data;

sound(music, sample_freq);
plot(music);


function result = play_multi(melody, amp, sample_freq, tone_mapping, overlap_ratio, base_tone_freq, beat_time)
    my_play_single = @(tone, beat) play_single(tone, beat, amp, sample_freq, tone_mapping, overlap_ratio, base_tone_freq, beat_time);

    result = [];
    music = [];
    len = length(melody);
    for i = 1:len
        if i == 1
            music = my_play_single(melody{i}{1}, melody{i}{2});
        else
            music_current = my_play_single(melody{i}{1}, melody{i}{2});
            music_len = min(length(music), length(music_current));
            music = [music(:, 1:music_len);music_current(1:music_len)];
        end
    end
    [row, ~] = size(music);
    result = [0.25, 0.25, 0.25, 0.25] * music;
end


function result = play_single(tone, beat, amp, sample_freq, tone_mapping, overlap_ratio, base_tone_freq, beat_time)
    
    % 初始化空数组用于存储结果
    result = [];
    loop = 1:length(tone);
    overlap_last = 0;
    % 循环迭代
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
        end
        overlap_last = overlap;
    end
end

function [result, overlap] = gen_tune(tone, beat, amp, sample_freq, tone_mapping, overlap_ratio, base_tone_freq, beat_time)

    [freq, width] = trans_freq_width(tone, beat, base_tone_freq, beat_time, tone_mapping);
    
    [y0, y1, y2, y3] = generate_fixed(width, sample_freq, beat_time, overlap_ratio);
    
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

function [freq, width] = trans_freq_width(tone, beat, base_tone_freq, beat_time, tone_mapping)
    remain = mod(tone - 1, 7) + 1;
    exponent = tone_mapping(remain) + (tone - remain)/7 * 12;
    freq = base_tone_freq * (2^(exponent/12));
    width = beat * beat_time;
end


function [y0, y1, y2, y3] = generate_fixed(width, sample_freq, beat_time, overlap_ratio)
    
    time_step = sample_freq^(-1);

    t0 = 0:time_step:width * 0.09;
    t1 = 0:time_step:width * 0.05;
    t3 = 0:time_step:width * 0.95;
    % width = width - t0(end) - t1(end) - t3(end) * (1 - overlap_ratio);
    t2 = 0:time_step:(width * 0.01);
    
    [unused, y0] = exponential_envelop(t0, 0, 1, -5);
    [unused, y1] = exponential_envelop(t1, 1, 0.9, -5);    
    [unused, y2] = exponential_envelop(t2, 0.9, 0.9, 1);
    [unused, y3] = exponential_envelop(t3, 0.9, 0, -2);   
end


function [output, envelop] = exponential_envelop(y, amp1, amp2, coe)
    [row, col] = size(y); % row = 1, col = n    
    
    coe = col^(-0.95) * coe;
    func = @(x) exp(coe * x);
    [output, envelop] = func_envelop(y, amp1, amp2, func);
end

function [output, envelop] = func_envelop(y, amp1, amp2, func)
    [row, col] = size(y); % row = 1, col = n
    [a, b] = func_fit(1, amp1, col, amp2, func);
    x = 1:1:col;
    envelop = a * func(x) + b;
    output = y .* envelop;
end
function [a, b] = func_fit(x1, y1, x2, y2, func)
    % 计算指数函数参数
    a = (y2 - y1) / (func(x2) - func(x1));
    b = y1 - a * func(x1);
end