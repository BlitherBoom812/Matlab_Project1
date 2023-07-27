function peak_x = my_find_peak(y, threshold_ratio, threshold_interval, fs)
    % 被确定为峰值的条件：该极大值必须与前一个极小值的比值大于 threshold_ratio，或者它前面没有极小值；距离该极大值点
    % threshold_interval 范围内没有比它更大的极大值。

    % config
    debug = false;

    peak_x = [];

    % 计算极大值和极小值
    maxima = islocalmax(y);
    minima = islocalmin(y);
    maxima_x = find(maxima);
    if debug
        fprintf("ratio = %f, interval = %f\n", threshold_ratio, threshold_interval);
        disp(['maxi num: ', num2str(length(maxima_x))]);
    end
    
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
end

function y = cat_element(list, x)
    if isempty(list)
        y = x;
    else
        y = [list, x];
    end
end