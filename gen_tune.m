function [result, overlap] = gen_tune(tone, beat, amp, sample_freq, tone_mapping, overlap_ratio, base_tone_freq, beat_time)

    [freq, width] = trans_freq_width(tone, beat, base_tone_freq, beat_time, tone_mapping);
    
    [y0, y1, y2, y3] = generate_fixed(width, sample_freq, beat_time, overlap_ratio);
    
    wave = gen_waveform(freq, length([y0, y1, y2, y3]), amp, sample_freq);

    result = wave .* [y0, y1, y2, y3];
    overlap = round(overlap_ratio * length(y3));
end

function wave = gen_waveform(freq, len, amp, sample_freq)

   time_step = sample_freq^(-1);
   t = 0:time_step:(len-1) * time_step;

   harmonic = [1, 1.46, 0.96, 1.10, 0.05, 0.11, 0.36, 0.12, 0.14, 0.06];
   for m = 1:length(harmonic)
       if m == 1
           wave = amp * sin(2 * pi * freq * t);
       else
           wave = wave + harmonic(m) * amp * sin(2 * pi * m * freq * t);
       end
   end
end

function [freq, width] = trans_freq_width(tone, beat, base_tone_freq, beat_time, tone_mapping)
    remain = mod(tone - 1, 7) + 1;
    exponent = tone_mapping(remain) + (tone - remain)/7 * 12;
    freq = base_tone_freq * (2^(exponent/12));
    width = beat * beat_time;
end


function [y0, y1, y2, y3] = generate_fixed(width, sample_freq, beat_time, overlap_ratio)
    
    time_step = sample_freq^(-1);

    t0 = 0:time_step:width * 0.09;
    t1 = 0:time_step:width * 0.05;
    t3 = 0:time_step:width * 0.95;
    % width = width - t0(end) - t1(end) - t3(end) * (1 - overlap_ratio);
    t2 = 0:time_step:(width * 0.01);
    
    [unused, y0] = exponential_envelop(t0, 0, 1, -5);
    [unused, y1] = exponential_envelop(t1, 1, 0.9, -5);    
    [unused, y2] = exponential_envelop(t2, 0.9, 0.9, 1);
    [unused, y3] = exponential_envelop(t3, 0.9, 0, -2);   
end


function [output, envelop] = exponential_envelop(y, amp1, amp2, coe)
    [row, col] = size(y); % row = 1, col = n    
    
    coe = col^(-0.95) * coe;
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