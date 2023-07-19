
function result = play_single(tone, beat)
    
    % 初始化空数组用于存储结果
    result = [];
    loop = 1:length(tone);
    % loop = 1:2;
    % 循环迭代
    for i = loop
        % 调用 gen_tune 函数
        [local_result, overlap] = gen_tune(tone(i), beat(i));
        % 将结果的首尾相加，中间拼接
        if i == 1
            % 第一次迭代，直接将结果添加到结果数组
            result = local_result;
        else
            % 非第一次迭代，将上一次结果的末尾与当前结果的开头相加，并将结果添加到结果数组
            result = [result(1:end-overlap), (result(end-overlap+1:end) + local_result(1:overlap)), local_result(overlap+1:end)];
        end
    end
end
