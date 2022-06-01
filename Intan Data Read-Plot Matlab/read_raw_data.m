function [raw,cropped] = read_raw_data(export_mat, raw_only, plot_flag, folder)
%% Intan files (.rhd & .dat) to Matlab datatype (.mat)
% Data Format : "One File Per Channel"
% Output `cropped` - overlapped EAG responses as a matrix
% `raw` - raw time and voltage data
cropped = struct; raw = struct;

if ~exist('export_mat','var'); export_mat=0; end
if ~exist('raw_only','var'); raw_only=0; end
if ~exist('folder','var'); folder=[]; end
if ~exist('plot_flag','var'); plot_flag=[1,1]; end % [1,1] - Plot raw & crop
% plot_flag  = [ RAW-EXP-DATA-PLOT, EAG-RESPONSES ]

%% Raw traces
% All possible data locations
data = get_header(folder);
data.file.folder = data.info.path;
data.file.header = fullfile(data.info.path, data.info.filename);
data.file.time = fullfile(data.file.folder,'time.dat');
data.file.amp1 = fullfile(data.file.folder,'amp-A-014.dat');
data.file.EnSig = fullfile(data.file.folder,'board-DIN-09.dat');
data.file.LSig = fullfile(data.file.folder,'board-DIN-10.dat');
data.file.RSig = fullfile(data.file.folder,'board-DIN-11.dat');

% read available files
data.time = get_time(data);
data.amp1_uV = get_amp(data.file.amp1);
if isfile(data.file.EnSig);data.EnSig = get_din(data.file.EnSig); end
if isfile(data.file.LSig); data.LSig = get_din(data.file.LSig); end
if isfile(data.file.RSig); data.RSig = get_din(data.file.RSig); end

raw.time_sec = data.time;
raw.amp_mV = data.amp1_uV/1000;

% Export raw data
% if strcmp(export_mat,'raw')
if export_mat ~= 0
    path = uigetdir('C:\Users\User\Documents\DATA_INTAN','Select Folder to Export .MAT');
    filename = strsplit(data.file.folder,'\');
    filename = [path '\EXPORT_' filename{end} '.' export_mat]; % TODO - FUllFile
    writematrix([raw.time_sec; raw.amp_mV],filename);
end

% Plot raw data
if plot_flag(1); plot_raw_data(data); end

%% Overlap stimulus-responses (zero-cropped at stim-onset)
if raw_only; return; end    

if ~isfield(data,'RSig') || isempty(data.RSig)
    if ~isfield(data,'LSig') || isempty(data.LSig)
        disp('Error - No signal present to crop responses..')
        return;
    else
        disp('-- Cropped-EAG - R-sig missing, using L-sig instead..')
        raw_sig = data.LSig;
    end
else
    disp('-- Plotting overlapped eag-response')
    raw_sig = data.RSig;
end

% Read D-in and stim
if isfield(data,'EnSig') && ~isempty(data.EnSig)
    indStart = find(diff(data.EnSig)==1); 
    if isempty(indStart); indStart=1; end % all-1 or all-0
    indStop = find(diff(data.EnSig)==-1);
    if isempty(indStop); indStop=length(data.time); end
else
    indStart=1; indStop=length(data.time);
end

% Find Stim 
indStimSt = find(diff(raw_sig)==1);
indStimSt = indStimSt(indStimSt>indStart & indStimSt<indStop);
indStimStp = find(diff(raw_sig)==-1);
indStimStp = indStimStp(indStimStp>indStart & indStimStp<indStop);
indStim = round(mean(indStimStp - indStimSt)); % actual stim-length (sec)

% get cropped-traces
cropSec = [-.5 2]; 
fs = 2e4;
t_sec = [cropSec(1)*fs:0 1:cropSec(2)*fs]/fs;
stimStart = -cropSec(1)*fs + 1;
stimStop = indStim + stimStart;
eag_uV = nan(length(indStimSt),length(t_sec));

if plot_flag(2); figure; hold on; end
for i=1:length(indStimSt)
    eag_uV(i,:) = data.amp1_uV(indStimSt(i)+cropSec(1)*fs:indStimSt(i)+cropSec(2)*fs);
    eag_uV(i,:) = bandpass_filter(eag_uV(i,:)',fs,0.1,30);
    eag_uV(i,:) = eag_uV(i,:) - eag_uV(i,stimStart);
    if plot_flag(2); plot(t_sec, eag_uV(i,:)); end
end 
if plot_flag(2)
    xline(t_sec(stimStart),':k','Start','LabelVerticalAlignment','bottom');
    if ~isnan(stimStop)
        xline(t_sec(stimStop),':k','Stop','LabelVerticalAlignment','bottom');
    end
    xlabel('Time (Sec)')
    ylabel('EAG Amplitude (uV)')
    title(['EAG EXP -- ' data.info.notes.note1 ]);
end

% export overlapped EAG responses
cropped.t_sec = t_sec;
cropped.mat_uV = eag_uV; 
cropped.stim_ind = [stimStart stimStop];
cropped.info = data.info;

end

function data = get_header(folder)
fprintf('START :: Reading Intan info.rdh file...\n');
if ~isempty(folder)
    data.info = read_Intan_header(folder);
else
    data.info = read_Intan_header();
end
fprintf('END :: Reading \n');
end

function t = get_time(data)
fileinfo = dir(data.file.time);
num_samples = fileinfo.bytes/4; % int32 = 4 bytes
fid = fopen(data.file.time, 'r');
t = fread(fid, num_samples, 'int32');
fclose(fid);
t = t / data.info.frequency_parameters.amplifier_sample_rate; % sample rate from header file
end

function v = get_amp(filename)
fileinfo = dir(filename);
num_samples = fileinfo.bytes/2; % int16 = 2 bytes
fid = fopen(filename, 'r');
v = fread(fid, num_samples, 'int16');
fclose(fid);
v = v * 0.195; % convert to microvolts
end

function din = get_din(filename)
fileinfo = dir(filename);
num_samples = fileinfo.bytes/2; % uint16 = 2 bytes
fid = fopen(filename, 'r');
din = fread(fid, num_samples, 'uint16');
fclose(fid);
end

function [y] = bandpass_filter(x,Fs,fstart,fstop)
%
%
% Dinesh Natesan

% 
highpass = designfilt('highpassiir','FilterOrder',4, ...
    'PassbandFrequency',fstart,'PassbandRipple',0.1, ...
    'SampleRate',Fs);
lowpass = designfilt('lowpassiir','FilterOrder',4, ...
    'PassbandFrequency',fstop,'PassbandRipple',0.1, ...
    'SampleRate',Fs);

% x = to_column_matrix(x);    % convert to column matrix
y = nan(size(x));

for i=1:size(x,2)
    
    tx = filtfilt(highpass, x(:,i));
    y(:,i) = filtfilt(lowpass, tx);

end

end

