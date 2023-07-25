clear;
close all;
clc;
fs = 8000;
% load 命令载入附件光盘中的数据文件“guitar.mat”
load('音乐合成所需资源\Guitar.Mat')
l = length(realwave);
t = (0:1/fs:((l-1)/fs))';
figure;
subplot(1, 2, 1);
plot(t, realwave);
title("realwave");

subplot(1, 2, 2);
plot(t, wave2proc);
title('wave2proc');


% 先用 wavread 函数载入光盘中的 fmt.wav 文件
[fmt, fs] = audioread('音乐合成所需资源\fmt.wav');
sound(fmt, fs);