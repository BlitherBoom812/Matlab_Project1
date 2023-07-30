
function tone = freq_mod12_convert(freqs)
% 将频率映射到模12的空间内。
    tone = mod(log(freqs) * 12 / log(2), 12);
end
