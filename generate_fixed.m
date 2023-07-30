% 包络修正
function [y0, y1, y2, y3] = generate_fixed(width, sample_freq)
    
    time_step = sample_freq^(-1);

    t0 = 0:time_step:width * 0.09;
    t1 = 0:time_step:width * 0.05;
    t3 = 0:time_step:width * 0.95;
    t2 = 0:time_step:(width * 0.01);
    
    [unused, y0] = exponential_envelop(t0, 0, 1, -5);
    [unused, y1] = exponential_envelop(t1, 1, 0.9, -5);    
    [unused, y2] = exponential_envelop(t2, 0.9, 0.9, 1);
    [unused, y3] = exponential_envelop(t3, 0.9, 0, -2);   
end