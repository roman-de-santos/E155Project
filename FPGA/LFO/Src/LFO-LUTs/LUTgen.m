%% Configuration
res = 4096;               % Number of samples between the range [sin(0), sin(2*pi)) 
width = 14;             % Bit width (Must be >= 14 for amplitude 4410)
amplitude = 4410;       % Peak amplitude (maximum delay)
filename = 'sine_fixed.mem'; 

%% Generate the Sine Wave
% Sample from 0 to just before 2*pi
x = (0:res-1) / res * 2 * pi;

% Scale sin(x) by your amplitude and round to an int
y_raw = round(amplitude * sin(x));

% Clamp values to ensure they don't exceed the bit width range
% (Min: -2^(width-1), Max: 2^(width-1) - 1)
min_val = -2^(width-1);
max_val = 2^(width-1) - 1;
y_raw(y_raw < min_val) = min_val;
y_raw(y_raw > max_val) = max_val;

%% Convert to Two's Complement Hex
% The 'mod' function handles the negative wraparound.
% Example: mod(-1, 65536) = 65535 (which is FFFF in hex)
y_hex = mod(y_raw, 2^width);

%% Write to .mem file
fid = fopen(filename, 'w');

% Write Header
fprintf(fid, '// Signed Fixed-Point Sine Wave\n');
fprintf(fid, '// Amplitude: +-%d\n', amplitude);
fprintf(fid, '// Width: %d bits, Resolution: %d\n', width, res);

% Determine hex string format (e.g. 16 bits needs 4 hex digits)
hex_digits = ceil(width / 4);
fmt_str = sprintf('%%0%dX\n', hex_digits);

% Write Data
for i = 1:length(y_hex)
    fprintf(fid, fmt_str, y_hex(i));
end

fclose(fid);

fprintf('Generated %s with amplitude [%d, %d].\n', ...
    filename, min(y_raw), max(y_raw));