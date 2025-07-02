%% PolickoskiNick_ee384_finalProject
% Stringed Instrument Tuner
clear; clear all; clc;


%% Audio Input & Real-Time Spectrum Analyzer Setup
fs = 44100;         % sampling freq
frameLength = 1024; % samples per frame
deviceReader = setupAudioReader(fs, frameLength);
specAnalyzer = setupSpectrumAnalyzer(fs);
disp('Starting real-time waterfall spectrogram. Use Ctrl+C to stop.');


%% Current Note Display Window
figure('Name', 'Detected Note', 'NumberTitle', 'off');
noteText = text(0.5, 0.5, '', 'FontSize', 72, ...
    'HorizontalAlignment', 'center', 'Color', 'white');
freqText = text(0.5, 0.2, '', 'FontSize', 17, ...
    'HorizontalAlignment', 'center', 'Color', 'white');
axis off;  
xlim([0 1]);
ylim([0 1]);
set(gcf, 'Color', 'black');


%% Real-Time Note Display Loop
% Parameters
requiredFramesStable = 5; % How many frames the note must stay the same
lastDetectedNote = '';
stableCounter = 0;

% Loop
while true
    % Audio Input & Real-Time Spectrum Analyzer Initialization
    audioFrame = deviceReader();
    specAnalyzer(audioFrame);

    % Time-Domain to Frequency-Domain Conversion
    Y = fft(audioFrame);
    Y = Y(1:floor(length(Y)/2)); % positive frequencies only
    mag = abs(Y); % plotting magnitude spectra

    % Finding Peak Value
    [~, idx] = max(mag);                
    f_peak = (idx-1)*(fs/2)/length(Y); % convert index to frequency (Hz)

    % Map Freq to Musical Note
    if f_peak > 20 && f_peak < 4000 % only considering reasonable freqs
        noteWithOctave = frequencyToNote(f_peak);

        % Comparing Current Note w/ Previous Note to Smooth Out Plot
        if strcmp(noteWithOctave, lastDetectedNote)
            stableCounter = stableCounter + 1;
        else
            stableCounter = 1; % reset counter if new note detected
            lastDetectedNote = noteWithOctave;
        end

        % Display Note + Octave in Window
        if stableCounter >= requiredFramesStable
            fprintf('Stable Note: %s (%.2f Hz)\n', noteWithOctave, f_peak);
            set(noteText, 'String', noteWithOctave);

            % Print in Either Hz or kHz Depending on Peak Freq Value
            if f_peak >= 1000
                set(freqText, 'String', f_peak*10^-3 + " kHz");
                drawnow;
            elseif f_peak < 1000
                set(freqText, 'String', f_peak + " Hz");
                drawnow;
            end
        end
    end
end


%% Function Definitions
function deviceReader = setupAudioReader(fs, frameLength)
% sets up audio input device
    deviceReader = audioDeviceReader(...
    'SampleRate', fs, ...
    'SamplesPerFrame', frameLength);
end


function specAnalyzer = setupSpectrumAnalyzer(fs)
% sets up real-time spectrum analyzer waterfall graph
    specAnalyzer = dsp.SpectrumAnalyzer(...
    'SampleRate', fs, ...
    'SpectralAverages', 3, ...
    'TimeSpanSource', 'Property', ...
    'TimeSpan', 3, ...  % 5 seconds window
    'PlotAsTwoSidedSpectrum', false, ...
    'FrequencyScale', 'Linear', ...
    'Title', 'Real-Time Microphone Spectrogram', ...
    'YLimits', [-120, 0]);  % Decibel limits
end


function noteWithOctave = frequencyToNote(frequency)
% calculates which note and octave are being played
    % Reference A4 = 440 Hz
    notes = {'C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'};
    A4 = 440; % reference note frequency
    
    % Calculating Note 
    n = round(12 * log2(frequency / A4));
    noteIndex = mod(n + 9, 12) + 1; % +9 to shift A to C
    note = notes{noteIndex};

    % Calculating Octave 
    octave = 4 + floor((n + 9) / 12);

    % Combining
    noteWithOctave = sprintf('%s%d', note, octave);
end

