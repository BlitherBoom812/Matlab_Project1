
function result = play_single(tone, beat, amp, sample_freq, tone_mapping, overlap_ratio, base_tone_freq, beat_time)
    
    % 初始化空数组用于存储结果
    result = [];
    loop = 1:length(tone);
    % 循环迭代
    for i = loop
        overlap_last = 0;
        % 调用 gen_tune 函数
        [local_result, overlap] = gen_tune(tone(i), beat(i), amp, sample_freq, tone_mapping, overlap_ratio, base_tone_freq, beat_time);
        % 将结果的首尾相加，中间拼接
        if i == 1
            % 第一次迭代，直接将结果添加到结果数组
            result = local_result;
        else
            % 非第一次迭代，将上一次结果的末尾与当前结果的开头相加，并将结果添加到结果数组
            result = [result(1:end-overlap_last), (result(end-overlap_last+1:end) + local_result(1:overlap_last)), local_result(overlap_last+1:end)];
            overlap_last = overlap;
        end
    end
end

