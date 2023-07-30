
clear
close all;
clc
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

% 初始化空数组用于存储结果
result = [];
loop = 1:length(tone);
overlap_last = 0;
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
        result = [result(1:end-overlap_last), (result(end-overlap_last+1:end) + local_result(1:overlap_last)), local_result(overlap_last+1:end)];
    end
    overlap_last = overlap;
end

sound(result, sample_freq);
plot_time = 0:1/sample_freq:(length(result) - 1)/sample_freq;
plot(plot_time,result);

function [result, overlap] = gen_tune(tone, beat)
    global amp;
    global sample_freq;
    global tone_mapping;
    global overlap_ratio;
    amp = 1;
    % 将唱名映射至以2^(1/12)为底的指数, 1对应指数为1
    tone_mapping = [0, 2, 4, 5, 7, 9, 11];
    overlap_ratio = 0.1;

    time_step = sample_freq^(-1);
    
    [freq, width] = trans_freq_width(tone, beat);
    
    [y0, y1, y2, y3] = generate_fixed(width);
    
    t = 0:time_step:(length([y0, y1, y2, y3])-1) * time_step;

    result = amp * sin(2 * pi * freq * t) .* [y0, y1, y2, y3];
    overlap = round(overlap_ratio * length(y3));
end

% 包络修正
function [y0, y1, y2, y3] = generate_fixed(width)
    global sample_freq;
    global beat_time;
    global overlap_ratio;
    
    time_step = sample_freq^(-1);

    t0 = 0:time_step:width * 0.09;
    t1 = 0:time_step:width * 0.05;
    t3 = 0:time_step:width * 0.95;
    t2 = 0:time_step:(width * 0.01);
    
    [unused, y0] = exponential_envelop(t0, 0, 1, -5);
    [unused, y1] = exponential_envelop(t1, 1, 0.9, -5);    
    [unused, y2] = exponential_envelop(t2, 0.9, 0.9, 1);
    [unused, y3] = exponential_envelop(t3, 0.9, 0, -2);   
end