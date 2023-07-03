function [header,Data,trigger,electrode]=readalltrcdata(DataFileName,DataPath)
% READALLTRCDATA reads all data from .trc file (type 4 only)
% inputs:   DataFileName - string with filename
%           DataPath - path for filename
% Outputs:  header - structure with header information
%           Data - structure with channelname, samplerate and data

% function is based on ReadMicroMedData
% H. v. Dijk, 16-06-2016
%%
header.FileName    = fullfile(DataPath,DataFileName);
% ---------------- Opening File------------------

fid = fopen( [header.FileName] , 'r' );
if fid == -1
    errordlg('Can''t open *.trc file');
    return;
end

%------------------ Reading Header Info ---------

fseek(fid,175,-1);
HeaderType=fread(fid,1,'char');
if HeaderType ~= 4
    errordlg('*.trc file is not Micromed System98 Header type 4');
    fclose(fid);
    return;
end

%try

fseek(fid,138,-1);
DataStartOffset         = fread(fid,1,'uint32');
header.StartOffset    = DataStartOffset;
NumChan                 = fread(fid,1,'uint16');
header.NrOfChannels   = NumChan;
Multiplexer             = fread(fid,1,'uint16');
RateMin                 = fread(fid,1,'uint16');
header.Bytes            = fread(fid,1,'uint16');

fseek(fid,400+8,-1);
header.TriggerArea             = fread(fid,1,'uint32');
header.TriggerAreaLength       = fread(fid,1,'uint32');

% Determine Data File Length
fseek(fid, 0, 1);
endOfFile           = ftell(fid);
header.FileLength = (endOfFile - DataStartOffset);

% Determine Sample Rate
electrode = ReadElectrode( fid , 1 , header.NrOfChannels );
header.SampleRate = electrode.rate_coef * RateMin;
electrode=[];

%---------------- Read & Prep Trigger Area Data ----------
fseek(fid,header.TriggerArea,-1);

trigger = NaN*ones(2,round(header.TriggerAreaLength/6)); %trigger = NaN*ones(2,round(header.TriggerAreaLength/6));
for i = 1 : header.TriggerAreaLength/6
    trigger(1,i) = fread(fid,1,'uint32');
    trigger(2,i) = fread(fid,1,'int16');
    %if trigger(2,i) == 0 || trigger(1,i) > DataFile.FileLength
    if trigger(1,i) > header.FileLength
        trigger = trigger(:,1:i-1);
        break
    end
end

%----------------- Determine Data Type----------
fseek(fid,DataStartOffset,-1);

switch header.Bytes
    case 1
        bstring='uint8';
    case 2
        bstring='uint16';
    case 4
        bstring='uint32';
end

%------------------ Reading Channel Info -------------
for currentChannel = 1 : NumChan
    electrode{currentChannel} = ReadElectrode( fid , currentChannel , NumChan );
    header.ChannelName{ currentChannel } = strrep( [ electrode{currentChannel}.positive_input '-' electrode{currentChannel}.negative_input ] , char( 0 ) , '' );
    header.SampleRate( currentChannel ) = electrode{currentChannel}.rate_coef * RateMin;  
end

%------------------ Import all data -------------
% import all data
channelsToImport = NumChan;
Data.channelsImport      =  header.ChannelName;
Data.SampleRate          =  header.SampleRate;
Data.channelsImportIndex = 1 : NumChan;
%    tracedata = zeros( DataFile.NrOfChannels , DataFile.Duration * DataFile.SampleRate( 1 ) );
fseek(fid,DataStartOffset,-1);
tracedata = fread(fid, header.FileLength * header.NrOfChannels, bstring);
tmptracedata=reshape(tracedata,header.NrOfChannels,length(tracedata)/header.NrOfChannels);
tracedata=tmptracedata;
tmptracedata = [];

% scale to SI unit
for currentChannel = 1 : channelsToImport
    Celectrode=electrode{currentChannel};
    if ischar(Celectrode.measurement_unit)==0
        tracedata(currentChannel,:)=-((tracedata(currentChannel,:)-Celectrode.logical_ground)/...
            (Celectrode.logical_max-Celectrode.logical_min+1))*...
            (Celectrode.physical_max-Celectrode.physical_min)*...
            Celectrode.measurement_unit;
    else
        tracedata(currentChannel,:)=-((tracedata(currentChannel,:)-Celectrode.logical_ground)/...
            (Celectrode.logical_max-...
            Celectrode.logical_min+1))*...
            (Celectrode.physical_max-...
            Celectrode.physical_min);
    end
end
Data.Micromed = tracedata;
tracedata = [];

% file Close
fclose(fid);

% catch ME
%     fclose(fid);
%     errordlg(['Error reading data: ',ME.message])
%     return;
% end;


%---------------- SubFunction---------------------------------------------
function electrode = ReadElectrode( fid , c , NumChan )

fseek(fid,192+8,-1);
ElectrodeArea   = fread(fid,1,'uint32');
fseek(fid,176+8,-1);
CodeArea        = fread(fid,1,'uint32');

fseek(fid,CodeArea,-1);
code            = fread(fid,NumChan,'uint16');

electrode.ChanRecord = code(c);
fseek(fid,ElectrodeArea+code(c)*128,-1);
fseek(fid,2,0);

electrode.positive_input = char(fread(fid,6,'char'))';
electrode.negative_input = char(fread(fid,6,'char'))';
electrode.logical_min=fread(fid,1,'int32');
electrode.logical_max=fread(fid,1,'int32');
electrode.logical_ground=fread(fid,1,'int32');
electrode.physical_min=fread(fid,1,'int32');
electrode.physical_max=fread(fid,1,'int32');

electrode.measurement_unit=fread(fid,1,'int16');
switch electrode.measurement_unit
    case -1
        electrode.measurement_unit=1e-9;
    case 0
        electrode.measurement_unit=1e-6;
    case 1
        electrode.measurement_unit=1e-3;
    case 2
        electrode.measurement_unit=1;
    case 100
        electrode.measurement_unit='percent';
    case 101
        electrode.measurement_unit='bpm';
    case 102
        electrode.measurement_unit='Adim';
    otherwise
        warning('Unknown measurement unit. uV assumed.');
        electrode.measurement_unit=10e-6;
end
fseek(fid,8,0);
electrode.rate_coef=fread(fid,1,'uint16');
