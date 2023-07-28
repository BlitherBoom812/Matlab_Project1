
clear
close all;
clc

sample_freq = 16e3;
% 1 = D
base_tone_freq = 293.66;
% beat_time = 0.5, or BPM = 120
beat_time = 1.2;
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