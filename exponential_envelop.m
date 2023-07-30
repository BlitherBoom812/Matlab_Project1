
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
