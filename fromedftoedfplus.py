# -*- coding: utf-8 -*-
"""
April 2023

@author: VB


Imports edf files and saves them as edfplus using mne and pyedflib


"""

import pyedflib # pip install pyedflib
#from pyedflib import highlevel # new high-level interface
from pyedflib import FILETYPE_BDF, FILETYPE_BDFPLUS, FILETYPE_EDF, FILETYPE_EDFPLUS
from datetime import datetime, timezone, timedelta
import mne
import os

def _stamp_to_dt(utc_stamp):
    """Convert timestamp to datetime object in Windows-friendly way."""
    if 'datetime' in str(type(utc_stamp)): return utc_stamp
    # The min on windows is 86400
    stamp = [int(s) for s in utc_stamp]
    if len(stamp) == 1:  # In case there is no microseconds information
        stamp.append(0)
    return (datetime.fromtimestamp(0, tz=timezone.utc) +
            timedelta(0, stamp[0], stamp[1]))  # day, sec, μs


def write_mne_edf(mne_raw, fname, picks=None, tmin=0, tmax=None, 
                  overwrite=False):
    """
    Saves the raw content of an MNE.io.Raw and its subclasses to
    a file using the EDF+/BDF filetype
    pyEDFlib is used to save the raw contents of the RawArray to disk
    Parameters
    ----------
    mne_raw : mne.io.Raw
        An object with super class mne.io.Raw that contains the data
        to save
    fname : string
        File name of the new dataset. This has to be a new filename
        unless data have been preloaded. Filenames should end with .edf
    picks : array-like of int | None
        Indices of channels to include. If None all channels are kept.
    tmin : float | None
        Time in seconds of first sample to save. If None first sample
        is used.
    tmax : float | None
        Time in seconds of last sample to save. If None last sample
        is used.
    overwrite : bool
        If True, the destination file (if it exists) will be overwritten.
        If False (default), an error will be raised if the file exists.
    """
    if not issubclass(type(mne_raw), mne.io.BaseRaw):
        raise TypeError('Must be mne.io.Raw type')
    if not overwrite and os.path.exists(fname):
        raise OSError('File already exists. No overwrite.')
        
    # static settings
    has_annotations = True if len(mne_raw.annotations)>0 else False
    if os.path.splitext(fname)[-1] == '.edf':
        file_type = FILETYPE_EDFPLUS #if has_annotations else FILETYPE_EDF
        dmin, dmax = -32768, 32767 
    else:
        file_type = FILETYPE_BDFPLUS if has_annotations else FILETYPE_BDF
        dmin, dmax = -8388608, 8388607
    
    print('saving to {}, filetype {}'.format(fname, file_type))
    sfreq = mne_raw.info['sfreq']
    date = _stamp_to_dt(mne_raw.info['meas_date'])
    
    if tmin:
        date += timedelta(seconds=tmin)
    # no conversion necessary, as pyedflib can handle datetime.
    #date = date.strftime('%d %b %Y %H:%M:%S')
    first_sample = int(sfreq*tmin)
    last_sample  = int(sfreq*tmax) if tmax is not None else None

    
    # convert data
    channels = mne_raw.get_data(picks, 
                                start = first_sample,
                                stop  = last_sample)
    
    # convert to microvolts to scale up precision
    channels *= 1e6

    # set conversion parameters
    n_channels = len(channels)
    
    # create channel from this   
    try:
        f = pyedflib.EdfWriter(fname,
                               n_channels=n_channels, 
                               file_type=file_type)
        
        channel_info = []
        
        ch_idx = range(n_channels) if picks is None else picks
        keys = list(mne_raw._orig_units.keys())
        for i in ch_idx:
            try:
                ch_dict = {'label': mne_raw.ch_names[i], 
                           'dimension': mne_raw._orig_units[keys[i]], 
                           'sample_rate': mne_raw._raw_extras[0]['n_samps'][i], 
                           'physical_min': mne_raw._raw_extras[0]['physical_min'][i], 
                           'physical_max': mne_raw._raw_extras[0]['physical_max'][i], 
                           'digital_min':  mne_raw._raw_extras[0]['digital_min'][i], 
                           'digital_max':  mne_raw._raw_extras[0]['digital_max'][i], 
                           'transducer': '', 
                           'prefilter': ''}
            except:
                ch_dict = {'label': mne_raw.ch_names[i], 
                           'dimension': mne_raw._orig_units[keys[i]], 
                           'sample_rate': sfreq, 
                           'physical_min': channels.min(), 
                           'physical_max': channels.max(), 
                           'digital_min':  dmin, 
                           'digital_max':  dmax, 
                           'transducer': '', 
                           'prefilter': ''}
        
            channel_info.append(ch_dict)
        f.setPatientCode(mne_raw._raw_extras[0]['subject_info'].get('id', '0'))
        f.setPatientName(mne_raw._raw_extras[0]['subject_info'].get('name', 'noname'))
        f.setTechnician('mne-gist-save-edf-skjerns')
        f.setSignalHeaders(channel_info)
        f.setStartdatetime(date)
        f.writeSamples(channels)
        for annotation in mne_raw.annotations:
            onset = annotation['onset']
            duration = annotation['duration']
            description = annotation['description']
            f.writeAnnotation(onset, duration, description)
        
    except Exception as e:
        raise e
    finally:
        f.close()    
    return True

subject_nr ='17'
filepath = 'C:/Users/vb/Documents/MATLAB/AbsenceChildren_paper4/data/Kemp/EEG/24h_data/PAT_'+subject_nr+'/'
filename = 'pat'+subject_nr+'_EEG_4.edf'
filesave = 'pat'+subject_nr+'_EEG_4_plus.edf'

#load EDF FILE
edffile = mne.io.read_raw_edf(filepath+filename)

# WRITE EDF PLUS
write_mne_edf(edffile, filepath+filesave, picks=None, tmin=0, tmax=None, overwrite=True)
