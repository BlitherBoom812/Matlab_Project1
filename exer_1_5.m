
clear
close all;
clc
global sample_freq;
global amp;
global base_tone_freq;
global beat_time;
global tone_mapping;
global overlap_ratio;
sample_freq = 32e3;
amp = 1;
% 1 = D
base_tone_freq = 293.66;
% beat_time = 0.5, or BPM = 120
beat_time = 1;
% 将唱名映射至以2^(1/12)为底的指数, 1对应指数为1
tone_mapping = [0, 2, 4, 5, 7, 9, 11];

overlap_ratio = 0.5;

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
        [-3,    1,      -2,     0];
        [2,     2,      2,      2]
    };
    {
        [-1,    3,      0,      2];
        [2,     2,      2,      2];
    };
    {
        [-12,   -11,    -10,    -8,     -9,     -10,    -13];
        [1,     1,      1,      1,      1,      1,      2]
    }
};

music1 = play_multi(bar1);
music2 = play_multi(bar2);

music = [music1, music2];

t = 0:1/sample_freq:(length(music) - 1)/sample_freq;

tin = timeseries(music',t);
tout = resample(tin, t);
music = tout.Data;

sound(music, sample_freq);

function result = play_multi(melody)
    result = [];
    music = [];
    len = length(melody);
    for i = 1:len
        if i == 1
            music = play_single(melody{i}{1}, melody{i}{2});
        else
            music_current = play_single(melody{i}{1}, melody{i}{2}) * 1.5 / i;
            music_len = min(length(music), length(music_current));
            music = [music(:, 1:music_len);music_current(1:music_len)];
        end
    end
    [row, col] = size(music);
    result = ones(1, row) * music;
end

function result = play_single(tone, beat)
    
    % % 曲谱
    % tone = [5, 5, 6, 2, 1, 1, -1, 2];
    % beat = [1, 0.5, 0.5, 2, 1, 0.5, 0.5, 2];
    % 
    % 初始化空数组用于存储结果
    result = [];
    loop = 1:length(tone);
    % loop = 1:2;
    % 循环迭代
    for i = loop
        % 调用 gen_tune 函数
        [local_result, overlap] = gen_tune(tone(i), beat(i));
        % 将结果的首尾相加，中间拼接
        if i == 1
            % 第一次迭代，直接将结果添加到结果数组
            result = local_result;
        else
            % 非第一次迭代，将上一次结果的末尾与当前结果的开头相加，并将结果添加到结果数组
            result = [result(1:end-overlap), (result(end-overlap+1:end) + local_result(1:overlap)), local_result(overlap+1:end)];
        end
    end
    
    % sound(result);
    % plot_time = 0:1/sample_freq:(length(result) - 1)/sample_freq;
    % plot(plot_time,result);

end

function [result, overlap] = gen_tune(tone, beat)
    global overlap_ratio;
        
    [freq, width] = trans_freq_width(tone, beat);
    
    [y0, y1, y2, y3] = generate_fixed(width);
    
    wave = gen_waveform(freq, length([y0, y1, y2, y3]));

    result = wave .* [y0, y1, y2, y3];
    overlap = round(overlap_ratio * length(y3));
end

function wave = gen_waveform(freq, len)
   global amp;
   global sample_freq;
   time_step = sample_freq^(-1);
   t = 0:time_step:(len-1) * time_step;



   if (freq == -1)
       wave = 0 * square(2 * pi * freq * t);
   else
       harmonic = [1, 0.2, 0.1, 0.1, 0.1, 0.2];
       for m = 1:length(harmonic)
           if m == 1
               wave = amp * sin(2 * pi * freq * t);
           else
               wave = wave + harmonic(m) * amp * sin(2 * pi * m * freq * t);
           end
       end
       % wave = amp * sawtooth(2 * pi * freq * t, 0.5);
   end
end

function [freq, width] = trans_freq_width(tone, beat)
    global base_tone_freq;
    global beat_time;
    global tone_mapping;

    if (tone == -100) 
        freq = -1;
    else 
        remain = mod(tone - 1, 7) + 1;
        exponent = tone_mapping(remain) + (tone - remain)/7 * 12;
        freq = base_tone_freq * (2^((exponent)/12));
    end
    width = beat * beat_time;
end

function [y0, y1, y2, y3] = generate_fixed(width)
    global sample_freq;
    global beat_time;
    global overlap_ratio;
    
    time_step = sample_freq^(-1);

    t0 = 0:time_step:beat_time * 0.05;
    t1 = 0:time_step:beat_time * 0.05;
    t3 = 0:time_step:beat_time * 0.1;
    width = width - t0(end) - t1(end) - t3(end) * (1 - overlap_ratio);
    t2 = 0:time_step:(width);
    
    [unused, y0] = exponential_envelop(t0, 0, 1, -5);
    [unused, y1] = exponential_envelop(t1, 1, 0.9, -5);    
    [unused, y2] = exponential_envelop(t2, 0.9, 0.9, 1);
    [unused, y3] = exponential_envelop(t3, 0.9, 0, -2);   
end


function [output, envelop] = exponential_envelop(y, amp1, amp2, coe)
    [row, col] = size(y); % row = 1, col = n    
    coe = col^(-1) * coe;
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
