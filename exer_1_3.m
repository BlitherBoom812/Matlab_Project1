
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

music = get_dfh();
% sound(music, sample_freq)

% % 升八度
% sound(music, sample_freq * 2)
% % 降八度
% sound(music, sample_freq / 2)
% 升半音
tsin = timeseries(music', 1:length(music));
tsout = resample(tsin, 1:(2^(1/12)):length(music));

rs_music = tsout.Data;

sound(rs_music);

function result = get_dfh()
    
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
    
    % sound(result);
    % plot_time = 0:1/sample_freq:(length(result) - 1)/sample_freq;
    % plot(plot_time,result);

end

