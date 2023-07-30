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
    result = result / max(result) * 2;
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

