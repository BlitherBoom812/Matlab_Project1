
global sample_freq;
global amp;
global base_tone_freq;
global beat_time;
global tone_mapping;
sample_freq = 8e3;
amp = 1;
% 1 = F
base_tone_freq = 349.23;
% beat_time = 0.5, or BPM = 120
beat_time = 0.5;
% 将唱名映射至以2为底的指数
tone_mapping = [1, 3, 5, 7, 8, 10, 12];
% 曲谱
tone = [5, 5, 6, 2, 1, 1, -1, 2];
beat = [1, 0.5, 0.5, 2, 1, 0.5, 0.5, 2];

% 初始化空数组用于存储结果
result = [];
% 循环迭代
for i = 1:length(tone)
    % 调用 gen_tune 函数
    [y0, y1, y2, y3, y4] = gen_tune(tone(i), beat(i));
    
    % 将结果的首尾相加，中间拼接
    if i == 1
        % 第一次迭代，直接将结果添加到结果数组
        result = [y0, y1, y2, y3, y4];
    else
        % 非第一次迭代，将上一次结果的末尾与当前结果的开头相加，并将结果添加到结果数组
        result = [result(1:end-length(y0)), result(end-length(y0)+1:end) + y0, y1, y2, y3, y4];
    end
end

sound(result)
plot(result)

function [y0, y1, y2, y3, y4] = gen_tune(tone, beat)
    [freq, width] = trans_freq_width(tone, beat);
    [y0, y1, y2, y3, y4] = gen_tune_from_freq_width(freq, width);
end

% 0.4x 的冲击（0~1.5 * beat_time），0.2x
% 的衰减（1.5~1），1x的持续（width），0.8x的消失（1~0），上一个音的0.4x和这个音相接
function [y0, y1, y2, y3, y4] = gen_tune_from_freq_width(freq, width)
    global beat_time;
    y0 = generate_fixed(freq, 0.1 * beat_time, 0, 1.5);
    y1 = generate_fixed(freq, 0.1 * beat_time, 1.5, 1);
    y2 = generate_fixed(freq, width, 1, 1);
    y3 = generate_fixed(freq, 0.2 * beat_time, 1, 0);
    y4 = y3(ceil(length(y3)/2):end);
    y3 = y3(1:ceil(length(y3)/2) - 1);
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

function y = generate_fixed(freq, width, amp1, amp2)
    global sample_freq;
    global amp;
    time_step = sample_freq^(-1);
    t0 = 0:time_step:width;
    y0 = amp * sin(2 * pi * freq * t0);
    [y, unused] = exponential_envelop(y0, amp1, amp2);
end

function [output, envelop] = exponential_envelop(y, amp1, amp2)
    shift_zero = @(x) abs(x) + 1e-6;
    amp1 = shift_zero(amp1);
    amp2 = shift_zero(amp2);
    [row, col] = size(y); % row = 1, col = n
    [a, b] = expo_func_fit(1, amp1, col, amp2);
    x = 1:1:col;
    % 计算包络
    envelop = b * exp(a * x);
    % 计算调制后的结果
    output = y .* envelop;
end

function [a, b] = expo_func_fit(x1, y1, x2, y2)
    % 计算参数 y = b * exp(a * x)
    a = (log(y2) - log(y1)) / (x2 - x1);
    b = y1 / exp(a * x1);
end