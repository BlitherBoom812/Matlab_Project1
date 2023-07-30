function play_dfh()
    sample_freq = 16e3;
    % 1 = F
    base_tone_freq = 349.23;
    % beat_time = 0.5, or BPM = 120
    beat_time = 0.5;
    amp = 1;
    % 将唱名映射至以2^(1/12)为底的指数, 1对应指数为1
    tone_mapping = [0, 2, 4, 5, 7, 9, 11];
    overlap_ratio = 0.15/0.95;
    
    music = get_dfh(amp, sample_freq, tone_mapping, overlap_ratio, base_tone_freq, beat_time);
    
    sound(music, sample_freq);
    plot(music);
    xlabel("时间/s");
    ylabel('幅度');
end


function result = get_dfh(amp, sample_freq, tone_mapping, overlap_ratio, base_tone_freq, beat_time)
    
    % 曲谱
    tone = [5, 5, 6, 2, 1, 1, -1, 2];
    beat = [1, 0.5, 0.5, 2, 1, 0.5, 0.5, 2];
    
   [base_freqs, harmonic_maps] = load_harmonic_mapping();

    % 初始化空数组用于存储结果
    result = [];
    loop = 1:length(tone);
    % 循环迭代
    overlap_last = 0;
    for i = loop
        % 调用 gen_tune 函数
        [local_result, overlap] = gen_tune(tone(i), beat(i), amp, sample_freq, tone_mapping, overlap_ratio, base_tone_freq, beat_time, base_freqs, harmonic_maps);
        % 将结果的首尾相加，中间拼接
        if i == 1
            % 第一次迭代，直接将结果添加到结果数组
            result = local_result;
        else
            % 非第一次迭代，将上一次结果的末尾与当前结果的开头相加，并将结果添加到结果数组
            result = [result(1:end-overlap_last), (result(end-overlap_last+1:end) + local_result(1:overlap_last)), local_result(overlap_last+1:end)];
        end
        overlap_last = overlap;
    end
end

function [result, overlap] = gen_tune(tone, beat, amp, sample_freq, tone_mapping, overlap_ratio, base_tone_freq, beat_time, base_freqs, harmonic_maps)

    [freq, width] = trans_freq_width(tone, beat, base_tone_freq, beat_time, tone_mapping);
    
    [y0, y1, y2, y3] = generate_fixed(width, sample_freq);
    
    wave = gen_waveform(freq, length([y0, y1, y2, y3]), amp, sample_freq, base_freqs, harmonic_maps);

    result = wave .* [y0, y1, y2, y3];
    overlap = round(overlap_ratio * length(y3));
end

function harmonics = get_harmonics(base_freq, base_freqs, harmonic_amps)
    [~, min_idx] = min(abs(freq_mod12_convert(base_freqs) - freq_mod12_convert(base_freq)));
    harmonics = [1, harmonic_amps{min_idx}];
end

function [base_freqs, harmonic_amps] = load_harmonic_mapping()
   load('harmonics.mat', 'harmonic_mapping');
   base_freqs = [];
   harmonic_amps = [];
   for i = 1:length(harmonic_mapping)
       base_freqs = [base_freqs, harmonic_mapping{i}{2}];
       harmonic_amps{length(harmonic_amps) + 1} = harmonic_mapping{i}{3};
       fprintf("tone_name %s 's harmonics: ", harmonic_mapping{i}{1});
       disp(harmonic_mapping{i}{3});
   end
   clear harmonic_mapping
end

function wave = gen_waveform(freq, len, amp, sample_freq, base_freqs, harmonic_amps)

   time_step = sample_freq^(-1);
   t = 0:time_step:(len-1) * time_step;
   % 吉他泛音
   harmonic = get_harmonics(freq, base_freqs, harmonic_amps);
   disp(['play tone ', num2str(freq) , ' Hz(', get_tune_name(freq), ') with harmonics ', num2str(harmonic)])

   for m = 1:length(harmonic)
       if m == 1
           wave = amp * sin(2 * pi * freq * t);
       else
           wave = wave + harmonic(m) * amp * sin(2 * pi * m * freq * t);
       end
   end
end

function [freq, width] = trans_freq_width(tone, beat, base_tone_freq, beat_time, tone_mapping)

    remain = mod(tone, 7);
    exponent = tone_mapping(remain) + (tone - remain)/7 * 12;
    freq = base_tone_freq * (2^((exponent - 1)/12));
    width = beat * beat_time;
end


function [y0, y1, y2, y3] = generate_fixed(width, sample_freq)
    
    time_step = sample_freq^(-1);

    t0 = 0:time_step:width * 0.09;
    t1 = 0:time_step:width * 0.05;
    t3 = 0:time_step:width * 0.95;
    t2 = 0:time_step:width * 0.01;
    
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

function [tone, standard_f] = get_tune_name(base_f)
    % 定义音调值与音名的对应关系
    % 大字组音名用大写字母表示，小字组用小写字母表示，组号用数字表示，例如'a'表示小字组的A（按照教材写法为A0），'B1'表示大字一组的B。
    % 一共收录132个音名。钢琴一般只有88个键，更低的音调人耳可能很难听到。
    tone_map = containers.Map({8.176, 8.662, 9.177, 9.723, 10.301, 10.913, 11.562, 12.250, 12.978, 13.750, 14.568, 15.434, ...
        16.352, 17.324, 18.354, 19.445, 20.602, 21.827, 23.125, 24.500, 25.957, 27.500, 29.135, 30.868, 32.703, ...
        34.648, 36.708, 38.891, 41.203, 43.654, 46.249, 48.999, 51.913, 55.000, 58.270, 61.735, 65.406, 69.296, ...
        73.416, 77.782, 82.407, 87.307, 92.499, 97.999, 103.826, 110.000, 116.541, 123.471, 130.813, 138.591, ...
        146.832, 155.563, 164.814, 174.614, 184.997, 195.998, 207.652, 220.000, 233.082, 246.942, 261.626, ...
        277.183, 293.665, 311.127, 329.628, 349.228, 369.994, 391.995, 415.305, 440.000, 466.164, 493.883, ...
        523.251, 554.365, 587.330, 622.254, 659.255, 698.456, 739.989, 783.991, 830.609, 880.000, 932.328, ...
        987.767, 1046.502, 1108.731, 1174.659, 1244.508, 1318.510, 1396.913, 1479.978, 1567.982, 1661.219, ...
        1760.000, 1864.655, 1975.533, 2093.005, 2217.461, 2349.318, 2489.016, 2637.020, 2793.826, 2959.955, ...
        3135.963, 3322.438, 3520.000, 3729.310, 3951.066, 4186.009, 4434.922, 4698.636, 4978.032, 5274.041, ...
        5587.652, 5919.911, 6271.927, 6644.875, 7040.000, 7458.620, 7902.133, 8372.018, 8869.844, 9397.273, ...
        9956.063, 10548.082, 11175.303, 11839.822, 12543.854, 13289.750, 14080.000, 14917.240, 15804.266}, ...
        {'C3', 'C3#', 'D3', 'D3#', 'E3', 'F3', 'F3#', 'G3', 'G3#', 'A3', 'A3#', 'B3', 'C2', 'C2#', 'D2', 'D2#', ...
        'E2', 'F2', 'F2#', 'G2', 'G2#', 'A2', 'A2#', 'B2', 'C1', 'C1#', 'D1', 'D1#', 'E1', 'F1', 'F1#', 'G1', ...
        'G1#', 'A1', 'A1#', 'B1', 'C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B', 'c', 'c#', 'd', ...
        'd#', 'e', 'f', 'f#', 'g', 'g#', 'a', 'a#', 'b', 'c1', 'c1#', 'd1', 'd1#', 'e1', 'f1', 'f1#', 'g1', 'g1#', ...
        'a1', 'a1#', 'b1', 'c2', 'c2#', 'd2', 'd2#', 'e2', 'f2', 'f2#', 'g2', 'g2#', 'a2', 'a2#', 'b2', 'c3', 'c3#', ...
        'd3', 'd3#', 'e3', 'f3', 'f3#', 'g3', 'g3#', 'a3', 'a3#', 'b3', 'c4', 'c4#', 'd4', 'd4#', 'e4', 'f4', 'f4#', ...
        'g4', 'g4#', 'a4', 'a4#', 'b4', 'c5', 'c5#', 'd5', 'd5#', 'e5', 'f5', 'f5#', 'g5', 'g5#', 'a5', 'a5#', 'b5', ...
        'c6', 'c6#', 'd6', 'd6#', 'e6', 'f6', 'f6#', 'g6', 'g6#', 'a6', 'a6#', 'b6'});
    % 判断基频值与音调值的差距，并输出对应的音名
    tone = '';
    tolerance = 0.02;
    for freq = keys(tone_map)
        if abs(base_f/freq{1} - 1) < tolerance
            tone = tone_map(freq{1});
            standard_f = freq{1};
            break;
        end
    end
end

function tone = freq_mod12_convert(freqs)
% 将频率映射到模12的空间内。
    tone = mod(log(freqs) * 12 / log(2), 12);
end
