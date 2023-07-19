
clear
close all;
clc
global sample_freq;
global amp;
global base_tone_freq;
global beat_time;
global tone_mapping;
global overlap_ratio;
sample_freq = 8e3;
amp = 1;
% 1 = F
base_tone_freq = 349.23;
% beat_time = 0.5, or BPM = 120
beat_time = 0.5;
% 将唱名映射至以2为底的指数
tone_mapping = [1, 3, 5, 6, 8, 10, 12];

overlap_ratio = 0.5;
% 曲谱
tone = [5, 5, 6, 2, 1, 1, -1, 2];
beat = [1, 0.5, 0.5, 2, 1, 0.5, 0.5, 2];

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

sound(result, sample_freq);
plot_time = 0:1/sample_freq:(length(result) - 1)/sample_freq;
plot(plot_time,result);

function [result, overlap] = gen_tune(tone, beat)
    global amp;
    global sample_freq;
    global overlap_ratio;
    
    time_step = sample_freq^(-1);
    
    [freq, width] = trans_freq_width(tone, beat);
    
    [y0, y1, y2, y3] = generate_fixed(width);
    
    t = 0:time_step:(length([y0, y1, y2, y3])-1) * time_step;

    result = amp * sin(2 * pi * freq * t) .* [y0, y1, y2, y3];
    overlap = round(overlap_ratio * length(y3));
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

% 0.4x 的冲击（0~1.5 * beat_time），0.2x
% 的衰减（1.5~1），1x的持续（width），0.8x的消失（1~0），上一个音的0.4x和这个音相接
function [y0, y1, y2, y3] = generate_fixed(width)
    global sample_freq;
    global beat_time;
    global overlap_ratio;
    
    time_step = sample_freq^(-1);

    t0 = 0:time_step:beat_time * 0.1;
    t1 = 0:time_step:beat_time * 0.1;
    t3 = 0:time_step:beat_time * 0.2;
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
