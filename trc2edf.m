  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  %
  % Imports trc files
  % Saves trc files as edf files
  % works also from .set file to .edf
  %  
  % needs readalltrcdata.m
  % needs eeglab (2018 or newer)
  % 
  % V Barone  March, 2023
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  clear all; close all;
%% import trc file
datapath = 'C:\Users\vb\Documents\MATLAB\AbsenceChildren_paper4\data\SEIN\EEG\24h_data_SEIN\PAT_4\';
filename = 'EEG_54.trc';

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
% channel types to modify according to your recording- KH
%for neurocenter we need to use these channels name
%T7 T8 = T3 T4; P8 P7 = T6 T5
% chanlist = {'Fp1','Fpz','Fp2','F7','F3','Fz','F4','F8','T3','C3','Cz','C4','T4','T5','P3','Pz','P4','T6','O1','FT11','O2','FT12','F9','F10','EMG1','EMG2','EMG3','EMG4','EMG5','EMG6','EMG7','ECG2','PULS','BEAT','SpO2','MKR'};
% for n = 1:length(chanlist)
%     EEG.chanlocs(n).labels = chanlist{n};
% end
%SEIN
%for neurocenter we need to use these channels name
%T7 T8 = T3 T4; P8 P7 = T6 T5
%if 26 chn
%chanlist = {'Fp1','Fp2','F7','F3','Fz','F4','F8','T3','C3','Cz','C4','T4','T5','P3','Pz','P4','T6','O1','O2','F9','F10','ECG2+-ECG2-','PULS+-PULS-','BEAT+-BEAT-','SpO2+-SpO2-','MKR+-MKR-'};
%if 23 chn
chanlist = {'Fp1','Fp2','F7','F3','Fz','F4','F8','T3','C3','Cz','C4','T4','T5','P3','Pz','P4','T6','O1','O2','F9','F10','ECG2+-ECG2-','MKR+-MKR-'};
for n = 1:length(chanlist)
     EEG.chanlocs(n).labels = chanlist{n};
end

EEG = eeg_checkset( EEG );
eeglab redraw
%% Keep relevant channels 
%for neurocenter
EEG = pop_select( EEG, 'channel',{'Fp1', 'Fp2', 'F7', 'F3', 'Fz', 'F4','F8', 'T3','C3', 'Cz', 'C4','T4', 'T5', 'P3', 'Pz', 'P4', 'T6', 'O1','O2'});
EEG = eeg_checkset( EEG );
eeglab redraw


%% Filter
EEG  = pop_eegfiltnew( EEG, 1,30); 
EEG.setname='filtered';
EEG = eeg_checkset( EEG );
eeglab redraw

% visualize signal
pop_eegplot( EEG, 1, 1, 1);
%% Add channel location
EEG=pop_chanedit(EEG, 'lookup','C:\Users\vb\Documents\MATLAB\R2018b\toolbox\eeglab2022.0\plugins\dipfit\standard_BEM\elec\\standard_1005.elc');
EEG = eeg_checkset( EEG );
eeglab redraw

%% save as edf
pop_writeeeg(EEG,'pat6_EEG_53.edf', 'TYPE','EDF');