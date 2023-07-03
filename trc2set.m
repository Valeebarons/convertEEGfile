   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  %
  % Imports trc files
  % Saves trc files as set files to be used in eeglab
  %
  %  
  % needs readalltrcdata.m
  % needs eeglab (2018 or newer)
  % 
  % V Barone  March, 2022
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% import trc file
datapath = 'yourpath';
filename = 'yourfile.trc';

[header, data, trigger,electrode] = readalltrcdata(filename, datapath); 
fs = data.SampleRate(1,1);
t = (0:length(data.Micromed)-1)/ fs; %in seconds
data.Micromed = data.Micromed.*1000000; %in microVolts

% visualize data
tminutes = t./60; %to plot
plot(tminutes, data.Micromed(15,:))


%% create EEG structure for set file 
eeglab

EEG.data = data.Micromed;
EEG.subject = '';
EEG.group = '';
EEG.condition = '';
EEG.session = '';
EEG.chaninfo = [];
EEG.times = t;
EEG.specdata = [];
EEG.speciaact = [];
EEG.icachansind = [];
EEG.reject = []; 
EEG.srate = data.SampleRate(1,1);
EEG.nbchan = length(data.channelsImport);
% channel types to modify according to your recording
chanlist = {'Fp1','Fpz','Fp2','F7','F3','Fz','F4','F8','T7','C3','Cz','C4','T8','P7','P3','Pz','P4','P8','O1','FT11','O2','FT12','F9','F10','EMG1','EMG2','EMG3','EMG4','EMG5','EMG6','EMG7','ECG2','PULS','BEAT','SpO2','MKR'};
for n = 1:length(chanlist)
    EEG.chanlocs(n).labels = chanlist{n};
end


EEG = pop_saveset( EEG , 'filename','yourfilename.set','filepath','yourdatapath');


