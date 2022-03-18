function eag = read_raw_data(plot_flag,file)
%% Intan files (.rhd & .dat) to Matlab datatype (.mat)
% Data Format : "One File Per Channel"

% plot_flag  = [ RAW-EXP-DATA-PLOT, EAG-RESPONSES ]
if ~exist('plot_flag','var'); plot_flag=[1,1]; end
if ~exist('file','var'); file=[]; end
data = get_header(file);

%%

% Save data locations
data.file.folder = data.info.path;
data.file.header = [data.info.path, data.info.filename];
data.file.time = [data.file.folder,'time.dat'];
data.file.amp1 = [data.file.folder,'amp-A-014.dat'];
data.file.EnSig = [data.file.folder,'board-DIN-09.dat'];
data.file.LSig = [data.file.folder,'board-DIN-10.dat'];
data.file.RSig = [data.file.folder,'board-DIN-11.dat'];

%%
data.time = get_time(data);
data.amp1_uV = get_amp(data.file.amp1); % check? uV or V
data.EnSig = get_din(data.file.EnSig);
% data.LSig = get_din(data.file.LSig); % DISABLE for SINGLE SIDE STIM
data.RSig = get_din(data.file.RSig);

%%
if plot_flag(1); plot_raw_data(data); end
    
%% Read D-in and stim
indStart = find(diff(data.EnSig)==1); 
if isempty(indStart); indStart=3e5; end
indStop = find(diff(data.EnSig)==-1);
indStimSt = find(diff(data.RSig)==1);
indStimSt = indStimSt(indStimSt>indStart & indStimSt<indStop);
indStimStp = find(diff(data.RSig)==-1);
indStimStp = indStimStp(indStimStp>indStart & indStimStp<indStop);
indStim = round(mean(indStimStp - indStimSt));

%% 
cropSec = [-.5 2]; 
fs = 2e4;
t_sec = [cropSec(1)*fs:0 1:cropSec(2)*fs]/fs;
stimStart = -cropSec(1)*fs + 1;
stimStop = indStim + stimStart;
eag_uV = nan(length(indStimSt),length(t_sec));

%%
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
%         title(ttl)
end

%% 
eag = struct;
eag.t_sec = t_sec;
eag.mat_uV = eag_uV; 
eag.stim_ind = [stimStart stimStop];
eag.info = data.info;
end

function data = get_header(file)
fprintf('START :: Reading Intan info.rdh file...\n');
if ~isempty(file)
    data.info = read_Intan_header(file.name,file.path);
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

