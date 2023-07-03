# convertEEGfile
Convert different EEG file formats

This repository contains scripts to convert EEG files from different formats (.trc, .edf) to other format types (.set, .edf+).
It contains also the necessary functions for the proper use of the scripts. 
These scripts work with Matlab R2018b and Python 3.8.5

Trc2set.m
Imports .trc files and saves them as .set files, via EEGLAB. It needs EEGLAB 2020 or newer, and readalltrcdata.m to import .trc files

Trc2edf.m
Imports .trc files and saves them as .edf files, via EEGLAB. It needs EEGLAB 2020 or newer, and readalltrcdata.m to import .trc files. 
It can directly convert .set files to .edf files

Fromedftoedfplus.py
Imports .edf files and saves them as .edf+ files. Important to store annotations
