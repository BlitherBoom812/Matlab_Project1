
clear
close all;
clc

global sample_freq;
global base_tone_freq;
global beat_time;

sample_freq = 8e3;

% 1 = D
base_tone_freq = 293.66;
% beat_time = 0.5, or BPM = 120
beat_time = 1.2;

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
            music_current = play_single(melody{i}{1}, melody{i}{2});
            music_len = min(length(music), length(music_current));
            music = [music(:, 1:music_len);music_current(1:music_len)];
        end
    end
    [row, col] = size(music);
    result = ones(1, row) * music;
end

