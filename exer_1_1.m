
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
