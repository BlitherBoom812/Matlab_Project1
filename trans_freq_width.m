function [freq, width] = trans_freq_width(tone, beat, base_tone_freq, beat_time, tone_mapping)
    if nargin < 3 || isempty(base_tone_freq)
        base_tone_freq = 349.23;
    end

    if nargin < 4 || isempty(beat_time)
        beat_time = 0.5;
    end

    if nargin < 5 || isempty(tone_mapping)
        tone_mapping = [0, 2, 4, 5, 7, 9, 11];
    end
    
    remain = mod(tone - 1, 7) + 1;
    exponent = tone_mapping(remain) + (tone - remain)/7 * 12;
    freq = base_tone_freq * (2^(exponent/12));
    width = beat * beat_time;
end
