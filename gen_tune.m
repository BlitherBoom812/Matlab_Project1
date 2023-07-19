
function [result, overlap] = gen_tune(tone, beat)
    % 根据唱名和节拍生成音乐波形
    global amp;
    global overlap_ratio;
    global tone_mapping;
    amp = 1;
    % 将唱名映射至以2^(1/12)为底的指数, 1对应指数为1
    tone_mapping = [0, 2, 4, 5, 7, 9, 11];
    overlap_ratio = 0.5;
        
    [freq, width] = trans_freq_width(tone, beat);
    
    [y0, y1, y2, y3] = generate_fixed(width);
    
    wave = gen_waveform(freq, length([y0, y1, y2, y3]));

    result = wave .* [y0, y1, y2, y3];
    overlap = round(overlap_ratio * length(y3));
end

function wave = gen_waveform(freq, len)
   global amp;
   global sample_freq;
   time_step = sample_freq^(-1);
   t = 0:time_step:(len-1) * time_step;



   if (freq == -1)
       wave = 0 * square(2 * pi * freq * t);
   else
       harmonic = [1, 0.1, 0.1, 0.1, 0.1, 0.3];
       for m = 1:length(harmonic)
           if m == 1
               wave = amp * sin(2 * pi * freq * t);
           else
               wave = wave + harmonic(m) * amp * sin(2 * pi * m * freq * t);
           end
       end
       % wave = amp * sawtooth(2 * pi * freq * t, 0.5);
   end
end

function [freq, width] = trans_freq_width(tone, beat)
    global base_tone_freq;
    global beat_time;
    global tone_mapping;

    if (tone == -100) 
        freq = -1;
    else 
        remain = mod(tone - 1, 7) + 1;
        exponent = tone_mapping(remain) + (tone - remain)/7 * 12;
        freq = base_tone_freq * (2^(exponent/12));
    end
    width = beat * beat_time;
end

function [y0, y1, y2, y3] = generate_fixed(width)
    global sample_freq;
    global beat_time;
    global overlap_ratio;
    
    time_step = sample_freq^(-1);

    t0 = 0:time_step:beat_time * 0.05;
    t1 = 0:time_step:beat_time * 0.05;
    t3 = 0:time_step:beat_time * 0.1;
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