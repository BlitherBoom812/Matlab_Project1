clear;
close all;
clc;
fs = 8000;
part_div = 10;
load('音乐合成所需资源\Guitar.MAT');
l = length(realwave);
% resample
rsmp = resample(realwave, part_div, 1);
% 10 parts
part_len = round(length(rsmp) / part_div);
% sum all
for i = 1:part_div
    if (i == 1) 
        res = rsmp(1:part_len);
    else 
        res = res + rsmp((i - 1) * part_len + 1: i * part_len);
    end
end
% take average
res = res / part_div;
% repeat & resample
avg_rsmp = repmat(res, part_div, 1);
rsmp_final = resample(avg_rsmp, 1, part_div);
% plot
figure;
t = (0:1/fs:(l-1)/fs)';
subplot(3, 1, 1);
plot(t, rsmp_final);
subtitle("my\_wave2proc");
subplot(3, 1, 2);
plot(t, wave2proc);
subtitle("wave2proc");
subplot(3, 1, 3);
plot(t, realwave);
subtitle("realwave");