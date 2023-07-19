
clear
close all;
clc

global sample_freq;
global base_tone_freq;
global beat_time;

sample_freq = 32e3;

% 1 = D
base_tone_freq = 293.66;
% beat_time = 0.5, or BPM = 120
beat_time = 1;





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
            music_current = play_single(melody{i}{1}, melody{i}{2}) / i;
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

