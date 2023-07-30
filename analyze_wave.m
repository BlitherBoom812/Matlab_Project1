function [fmt, env, peaks, valleys, Tone_specs, base_freq_list] = ...
    analyze_wave( ...
        audio_data, ...
        fs, ...
        ratio, ...
        interval, ...
        base_freq_amp_ths, ...
        base_freq_search_interval, ...
        harmonic_search_amp_ths, ...
        harmonic_search_interval ...
    )
    % [fmt, fs] = audioread(file_path);
    fmt = audio_data;
    plot_wave = @(wave) plot(plot_wave_t(wave, fs), wave);
    % sound(fmt, fs);
    raw = fmt .^ 2;
    
    [env, ~] = envelope(raw, 5,'peak');
    for i = 1:2
        [env, ~] = envelope(env, 90,'peak');
    end
    env = max(env, 0.0026);
    
    wave_find_peak = @(y, ratio, interval) my_find_peak(y, ratio, round(interval * fs), fs);
    [peaks, valleys] = wave_find_peak(env, ratio, interval);
    
    fprintf("节拍个数： %d\n", length(peaks));

    Tone_specs = {};
    base_freq_list = {};
    try
        
        h = waitbar(0, '分析音调...');
        % 用于保存音调数据
        harmonic_mapping = {};
        tone_num = 1;
        for i = 1:length(peaks)
            t = plot_wave_t(fmt, fs);
            tone = fmt(valleys(i):valleys(i + 1));
            tone = tone(1:round(length(tone) * 0.8));
            tone = tone .* gausswin(length(tone));
            for j = 1:5
                tone = [tone;tone];
            end
            % 频域变换（只取正值）
            Tone = abs(fftshift(fft(tone)));
            f = linspace(-fs/2, fs/2, length(Tone));
            Tone = Tone(f > 0);
            f = f(f > 0);

            % 求峰值
            [max_amp, max_idx] = max(Tone);
            [peak_freq_amp, peak_freq_index] = findpeaks(Tone);
            % 基频幅度阈值（相对最大幅度）
            % base_freq_amp_ths = 0.3;
            peak_filtered_index = peak_freq_index(peak_freq_amp / max_amp > base_freq_amp_ths);

            % 暴力搜索基频
            % 基频搜索区间
            % base_freq_search_interval = 0.025;
            search_base_idx = peak_filtered_index(peak_filtered_index <= max_idx);
            base_freq_idx = max_idx;
            search_valid = false;
            search_result = search_base_idx(abs(round(max_idx ./ search_base_idx) - max_idx ./ search_base_idx) < base_freq_search_interval);
            if (~isempty(search_result))
                max_int = max(round(max_idx ./ search_result));
                search_result = search_result(abs(max_int - max_idx ./ search_result) < base_freq_search_interval);
                [~, min_idx] = min(abs(round(log(f(search_result) / 220) * 12 / log(2)) - log(f(search_result) / 220) * 12 / log(2)));
                final_result = search_result(min_idx);
                base_freq_idx = min(final_result);
                search_valid = true;
            end

            base_freq = f(base_freq_idx);
            [tone_name, standard_freq] = get_tune_name(base_freq);
            info = '';
    
            if search_valid
                fprintf("节拍 \t%d 的基频为 \t%f Hz, 对应的音名为 \t%s\t（频率 \t%f Hz）\n", i, base_freq, tone_name, standard_freq);
                base_freq_list{i} = base_freq;
                info = sprintf("Freq = %f Hz(%s)", base_freq, tone_name);
                % 检测谐波强度（正负0.1附近）
                % 谐波幅度阈值（相对基频）
                % harmonic_search_amp_ths = 0.05;
                % 谐波搜索区间
                % harmonic_search_interval = 0.1;
                harmonic_idxs = [];
                harmonic_amps = [];
                harmonic_mults = [];
                save_harmonic_amps = [];
    
                for j = 2:9
                    harmonic_freq_idx = j * base_freq_idx;
                    start = round(harmonic_freq_idx * (1 - harmonic_search_interval));
                    stop = min(round(harmonic_freq_idx * (1 + harmonic_search_interval)), length(peak_freq_amp));
                    search_base_idx = Tone(start:stop);
                    [max_harmonic_amp, max_harmonic_idx] = max(search_base_idx);
                    max_harmonic_idx = start - 1 + max_harmonic_idx;
                    % 归一化
                    max_harmonic_amp = max_harmonic_amp / Tone(base_freq_idx);
                    if (max_harmonic_amp > harmonic_search_amp_ths)
                        harmonic_amps = [harmonic_amps, max_harmonic_amp];
                        harmonic_idxs = [harmonic_idxs, max_harmonic_idx];
                        harmonic_mults = [harmonic_mults, j];
                        save_harmonic_amps = [save_harmonic_amps, max_harmonic_amp];
                    else
                        save_harmonic_amps = [save_harmonic_amps, 0];
                    end
                end
    
                for j = 1:length(harmonic_mults)
                    disp(['* 含有', num2str(harmonic_mults(j)), '倍的谐波分量(', num2str(f(harmonic_idxs(j))),' Hz)，幅度（相对基频）为', num2str(harmonic_amps(j))]);
                end
                
                % harmonic_mapping记录
                exist_key = false;
                exist_idx = 0;
                for j = 1:length(harmonic_mapping)
                    if harmonic_mapping{j}{1} == tone_name
                        exist_key = true;
                        exist_idx = j;
                        break;
                    end
                end
    
                if exist_key
                    harmonic_mapping{exist_idx}{3} = harmonic_mapping{exist_idx}{3} + save_harmonic_amps;
                    harmonic_mapping{exist_idx}{4} = harmonic_mapping{exist_idx}{4} + 1;
                else
                    harmonic_mapping{tone_num} = {tone_name, base_freq, save_harmonic_amps, 1};
                    tone_num = tone_num + 1;
                end
    
            else
                base_freq_list{i} = -1;
                fprintf("节拍 \t%d 的基频未搜到！\n", i);
            end
    
            % 绘图设置
            waitbar(i/length(peaks), h, sprintf('分析音调... %d%%', round(i/length(peaks) * 100)));
            Tone_specs{i} = {f, Tone};
        end
    
        % 对harmonic_mapping中音名相同者取平均值
        for i = 1:length(harmonic_mapping)
            harmonic_mapping{i}{3} = harmonic_mapping{i}{3} / harmonic_mapping{i}{4};
        end
        save("harmonics.mat", "harmonic_mapping", '-mat');
        close(h);
    catch exception
        % Code to handle the error
        close all;
        close(h);
        disp('An error occurred.');
        rethrow(exception);
    end
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

function [peak_x, prev_valley_x] = my_find_peak(y, threshold_ratio, threshold_interval, fs)
    % 被确定为峰值的条件：该极大值必须与前一个极小值的比值大于 threshold_ratio，或者它前面没有极小值；距离该极大值点
    % threshold_interval 范围内没有比它更大的极大值。

    % config
    debug = false;

    peak_x = [];
    prev_valley_x = [];
    % 计算极大值和极小值
    maxima = islocalmax(y);
    minima = islocalmin(y);
    maxima_x = find(maxima);
    if debug
        fprintf("ratio = %f, interval = %f\n", threshold_ratio, threshold_interval);
        disp(['maxi num: ', num2str(length(maxima_x))]);
    end
    
    % 添加第一个最低点
    [~, min_idx] = min(y(1:maxima_x(1)));
    prev_valley_x = cat_element(prev_valley_x, min_idx(end));

    % 遍历极大值点
    for i = 1:length(maxima_x)
        maxima_xi = maxima_x(i);
        % 找到在当前极大值点之前且离它最近的第一个极小值
        prev_min_index = find(minima(1:maxima_xi-1), 1, 'last');
        % 区间内峰值最大值
        % 在区间内找到极大值
        [peaks, peak_locations] = findpeaks(y(max(maxima_xi - threshold_interval + 1, 1):maxima_xi + threshold_interval));
        
        % 找到极大值最大的点
        [interval_max_y, max_peak_index] = max(peaks);
        interval_max_x = peak_locations(max_peak_index) + maxima_xi - threshold_interval;
        
        % 判断比值和间隔是否满足阈值条件
        if ~isempty(prev_min_index)
            ratio = y(maxima_xi) / y(prev_min_index);
            if (ratio > threshold_ratio)
                if y(maxima_xi) >= interval_max_y
                    peak_x = cat_element(peak_x, maxima_xi);
                    prev_valley_x = cat_element(prev_valley_x, prev_min_index);
                elseif ratio > threshold_ratio
                    if debug
                        fprintf("x = %f, y = %f, prev_min_x = %f, prev_min_y = %f, ratio = %f, interval_max_x = %f,interval_max_y = %f, interval = %f\n", maxima_xi/fs, y(maxima_xi), prev_min_index/fs, y(prev_min_index), ratio, interval_max_x / fs, interval_max_y, abs(interval_max_x - maxima_xi) / fs);
                    end
                end
            else 

            end
        else
            % 没有极小值，这是第一个极大值
            if y(maxima_xi) >= interval_max_y
                peak_x = cat_element(peak_x, maxima_xi);
            else
                if debug
                    fprintf("no prev_min: x = %f, y = %f, interval_max_x = %f,interval_max_y = %f, interval = %f\n", maxima_xi/fs, y(maxima_xi), interval_max_x / fs, interval_max_y, abs(interval_max_x - maxima_xi) / fs);
                end
            end
        end
    end
    % 再加上末尾的最低点
    [~, min_idx] = min(y(maxima_x(end):end));
    min_idx = maxima_x(end) - 1 + min_idx;
    prev_valley_x = cat_element(prev_valley_x, min_idx(1));
end

function y = cat_element(list, x)
    if isempty(list)
        y = x;
    else
        y = [list, x];
    end
end