function D = spm_eeg_convert(S)
% Main function for converting different M/EEG formats to SPM8 format.
% FORMAT D = spm_eeg_convert(S)
% S                - can be string (file name) or struct (see below)
%
% If S is a struct it can have the optional following fields:
% S.dataset        - file name
% S.continuous     - 1 - convert data as continuous
%                    0 - convert data as epoched (requires data that is
%                        already epoched or a trial definition file).
% S.timewindow     - [start end] in sec. Boundaries for a sub-segment of
%                     continuous data [default: all]
% S.outfile        - name base for the output files [default - same as input]
% S.channels       - 'all' - convert all channels
%                    or cell array of labels
% S.usetrials      - 1 - take the trials as defined in the data [default]
%                    0 - use trial definition file even though the data is
%                        already epoched
% S.trlfile        - name of the trial definition file
% S.datatype       - data type for the data file one of
%                    'float32-le' [default], 'float64-le'
% S.inputformat    - data type (optional) to force the use of specific data 
%                    reader
% S.eventpadding   - the additional time period around each trial for which
%                    the events are saved with the trial (to let the user 
%                    keep and use for analysis events which are outside
%                    trial borders), in seconds. [default: 0]
% S.conditionlabel - labels for the trials in the data [default: 'Undefined']
% S.blocksize      - size of blocks used internally to split large files
%                    [default: ~100Mb]
% S.checkboundary  - 1 - check if there are breaks in the file and do not
%                        read across those breaks [default]
%                    0 - ignore breaks (not recommended).
% S.saveorigheader - 1 - save original data header with the dataset
%                    0 - do not keep the original header [default]
%
% % D              - MEEG object (also written on disk)
%__________________________________________________________________________
% Copyright (C) 2008 Wellcome Trust Centre for Neuroimaging

% Vladimir Litvak
% $Id: spm_eeg_convert.m 3432 2009-09-29 23:37:45Z vladimir $

if ischar(S)
    temp      = S;
    S         = [];
    S.dataset = temp;
end

if ~isfield(S, 'dataset')
    error('Dataset must be specified.');
end

if ~isfield(S, 'outfile'),         S.outfile = ['spm8_' spm_str_manip(S.dataset,'tr')];  end
if ~isfield(S, 'channels'),        S.channels = 'all';                                   end
if ~isfield(S, 'timewindow'),      S.timewindow = [];                                    end
if ~isfield(S, 'blocksize'),       S.blocksize = 3276800;                                end %100 Mb
if ~isfield(S, 'checkboundary'),   S.checkboundary = 1;                                  end
if ~isfield(S, 'usetrials'),       S.usetrials = 1;                                      end
if ~isfield(S, 'datatype'),        S.datatype = 'float32-le';                            end
if ~isfield(S, 'eventpadding'),    S.eventpadding = 0;                                   end
if ~isfield(S, 'saveorigheader'),  S.saveorigheader = 0;                                 end
if ~isfield(S, 'conditionlabel'),  S.conditionlabel = 'Undefined' ;                      end
if ~isfield(S, 'inputformat'),     S.inputformat = [] ;                                  end

if ~iscell(S.conditionlabel)
    S.conditionlabel = {S.conditionlabel};
end

%--------- Read and check header

hdr = fileio_read_header(S.dataset, 'fallback', 'biosig', 'headerformat', S.inputformat);

if isfield(hdr, 'label')
    [unique_label junk ind]=unique(hdr.label);
    if length(unique_label)~=length(hdr.label)
        warning(['Data file contains several channels with ',...
            'the same name. These channels cannot be processed and will be disregarded']);
        % This finds the repeating labels and removes all their occurences
        sortind=sort(ind);
        [junk ind2]=setdiff(hdr.label, unique_label(sortind(find(diff(sortind)==0))));
        hdr.label=hdr.label(ind2);
        hdr.nChans=length(hdr.label);
    end
end

if ~isfield(S, 'continuous')
    S.continuous = (hdr.nTrials == 1);
end

%--------- Read and prepare events

try
    event = fileio_read_event(S.dataset, 'detectflank', 'both', 'eventformat', S.inputformat);

    if ~isempty(strmatch('UPPT001', hdr.label))
        % This is s somewhat ugly fix to the specific problem with event
        % coding in FIL CTF. It can also be useful for other CTF systems where the
        % pulses in the event channel go downwards.
        fil_ctf_events = fileio_read_event(S.dataset, 'detectflank', 'down', 'type', 'UPPT001', 'trigshift', -1, 'eventformat', S.inputformat);
        if ~isempty(fil_ctf_events)
            [fil_ctf_events(:).type] = deal('FIL_UPPT001_down');
            event = cat(1, event(:), fil_ctf_events(:));
        end
    end


    if ~isempty(strmatch('UPPT002', hdr.label))
        % This is s somewhat ugly fix to the specific problem with event
        % coding in FIL CTF. It can also be useful for other CTF systems where the
        % pulses in the event channel go downwards.
        fil_ctf_events = fileio_read_event(S.dataset, 'detectflank', 'down', 'type', 'UPPT002', 'trigshift', -1, 'eventformat', S.inputformat);
        if ~isempty(fil_ctf_events)
            [fil_ctf_events(:).type] = deal('FIL_UPPT002_down');
            event = cat(1, event(:), fil_ctf_events(:));
        end
    end


    % This is another FIL-specific fix that will hopefully not affect other sites
    if isfield(hdr, 'orig') && isfield(hdr.orig, 'VERSION') && isequal(uint8(hdr.orig.VERSION),uint8([255 'BIOSEMI']))
        ind = strcmp('STATUS', {event(:).type});
        val = [event(ind).value];
        if any(val>255)
            bytes  = dec2bin(val);
            bytes  = bytes(:, end-7:end);
            bytes  = flipdim(bytes, 2);
            val    = num2cell(bin2dec(bytes));
            [event(ind).value] = deal(val{:});
        end
    end

catch
    warning(['Could not read events from file ' S.dataset]);
    event = [];
end

% Replace samples with time
if numel(event)>0
    for i = 1:numel(event)
        event(i).time = event(i).sample./hdr.Fs;
    end
end

%--------- Start making the header

D = [];
D.Fsample = hdr.Fs;

%--------- Select channels

if ~strcmp(S.channels, 'all')
    [junk, chansel] = spm_match_str(S.channels, hdr.label);
else
    if isfield(hdr, 'nChans')
        chansel = 1:hdr.nChans;
    else
        chansel = 1:length(hdr.label);
    end
end

nchan = length(chansel);

D.channels = repmat(struct('bad', 0), 1, nchan);

if isfield(hdr, 'label')
    [D.channels(:).label] = deal(hdr.label{chansel});
end
%--------- Preparations specific to reading mode (continuous/epoched)

if S.continuous

    if isempty(S.timewindow)
        if hdr.nTrials == 1
            segmentbounds = [1 hdr.nSamples];
        elseif ~S.checkboundary
            segmentbounds = [1 hdr.nSamples*hdr.nTrials];
        else
            error('The data cannot be read without ignoring trial borders');
        end
        S.timewindow = segmentbounds./D.Fsample;
    else
        segmentbounds = round(S.timewindow.*D.Fsample);
        segmentbounds(1) = max(segmentbounds(1), 1);
    end


    %--------- Sort events and put in the trial

    if ~isempty(event)
        event = rmfield(event, {'offset', 'sample'});
        event = select_events(event, ...
            [S.timewindow(1)-S.eventpadding S.timewindow(2)+S.eventpadding]);
        if hdr.nSamplesPre>0
            for i = 1:numel(event)
                event(i).time = event(i).time - (hdr.nSamplesPre+1)./hdr.Fs;
            end
        end
    end

    D.trials.label = S.conditionlabel{1};
    D.trials.events = event;
    D.trials.onset = S.timewindow(1);

    %--------- Break too long segments into blocks

    nblocksamples = floor(S.blocksize/nchan);
    nsampl = diff(segmentbounds)+1;

    trl = [segmentbounds(1):nblocksamples:segmentbounds(2)];
    if (trl(end)==segmentbounds(2))
        trl = trl(1:(end-1));
    end

    trl = [trl(:) [trl(2:end)-1 segmentbounds(2)]'];

    ntrial = size(trl, 1);

    readbytrials = 0;

    D.timeOnset = (-hdr.nSamplesPre+trl(1,1)-1)./hdr.Fs;
    D.Nsamples = nsampl;
else % Read by trials
    if ~S.usetrials
        if ~isfield(S, 'trl')
            trl = getfield(load(S.trlfile, 'trl'), 'trl');
        else
            trl = S.trl;
        end
        
        trl = double(trl);
        
        if size(trl, 2) >= 3
            D.timeOnset = unique(trl(:, 3))./D.Fsample;
            trl = trl(:, 1:2);
        else
            D.timeOnset = 0;
        end

        if length(D.timeOnset) > 1
            error('All trials should have identical baseline');
        end
        
        try 
            conditionlabels = getfield(load(S.trlfile, 'conditionlabels'), 'conditionlabels');
        catch
            conditionlabels = S.conditionlabel;           
        end

        if ~iscell(conditionlabels)
            conditionlabels = {conditionlabels};
        end
        
        if numel(conditionlabels) == 1
            conditionlabels = repmat(conditionlabels, 1, size(trl, 1));
        end

        readbytrials = 0;
    else
        try
            trialind = sort([strmatch('trial', {event.type}, 'exact'), ...
                strmatch('average', {event.type}, 'exact')]);
            trl = [event(trialind).sample];
            trl = double(trl(:));
            trl = [trl  trl+double([event(trialind).duration]')-1];

            try
                offset = unique([event(trialind).offset]);
            catch
                offset = [];
            end
            if length(offset) == 1
                D.timeOnset = offset/D.Fsample;
            else
                D.timeOnset = 0;
            end
            conditionlabels = {};
            for i = 1:length(trialind)
                if isempty(event(trialind(i)).value)
                    conditionlabels{i} = S.conditionlabel{1};
                else
                    if all(ischar(event(trialind(i)).value))
                        conditionlabels{i} = event(trialind(i)).value;
                    else
                        conditionlabels{i} = num2str(event(trialind(i)).value);
                    end
                end
            end
            if  hdr.nTrials>1 && size(trl, 1)~=hdr.nTrials
                warning('Mismatch between trial definition in events and in data. Ignoring events');
                readbytrials = 1;
            else
                readbytrials = 0;
            end
            
            event = event(setdiff(1:numel(event), trialind));
        catch
            if hdr.nTrials == 1
                error('Could not define trials based on data. Use continuous option or trial definition file.');
            else
                readbytrials = 1;
            end
        end
    end
    if readbytrials
        nsampl = hdr.nSamples;
        ntrial = hdr.nTrials;
        trl = zeros(ntrial, 2);
        if exist('conditionlabels', 'var') ~= 1 || length(conditionlabels) ~= ntrial
            conditionlabels = repmat(S.conditionlabel, 1, ntrial);
        end
    else
        nsampl = unique(diff(trl, [], 2))+1;
        if length(nsampl) > 1
            error('All trials should have identical lengths');
        end

        inbounds = (trl(:,1)>=1 & trl(:, 2)<=hdr.nSamples*hdr.nTrials)';

        rejected = find(~inbounds);

        if ~isempty(rejected)
            trl = trl(find(inbounds), :);
            warning([S.dataset ': Trials ' num2str(rejected) ' not read - out of bounds']);
        end

        ntrial = size(trl, 1);
        
        if ntrial == 0
          warning([S.dataset ': No trials to read. Bailing out.']);  
          D = [];
          return;
        end          
    end
    D.Nsamples = nsampl;
    if isfield(event, 'sample')
        event = rmfield(event, 'sample');
    end
end

%--------- Prepare for reading the data
D.data.fnamedat = [S.outfile '.dat'];
D.data.datatype = S.datatype;

if S.continuous
    datafile = file_array(D.data.fnamedat, [nchan nsampl], S.datatype);
else
    datafile = file_array(D.data.fnamedat, [nchan nsampl ntrial], S.datatype);
end

% physically initialise file
datafile(end,end) = 0;

spm_progress_bar('Init', ntrial, 'reading and converting'); drawnow;
if ntrial > 100, Ibar = floor(linspace(1, ntrial,100));
else Ibar = [1:ntrial]; end

%--------- Read the data

offset = 1;
for i = 1:ntrial
    if readbytrials
        dat = fileio_read_data(S.dataset,'header',  hdr, 'begtrial', i, 'endtrial', i,...
            'chanindx', chansel, 'checkboundary', S.checkboundary, 'fallback', 'biosig', 'dataformat', S.inputformat);
    else
        dat = fileio_read_data(S.dataset,'header',  hdr, 'begsample', trl(i, 1), 'endsample', trl(i, 2),...
            'chanindx', chansel, 'checkboundary', S.checkboundary, 'fallback', 'biosig', 'dataformat', S.inputformat);
    end

    % Sometimes fileio_read_data returns sparse output
    dat = full(dat);

    if S.continuous
        nblocksamples = size(dat,2);

        datafile(:, offset:(offset+nblocksamples-1)) = dat;

        offset = offset+nblocksamples;
    else
        datafile(:, :, i) = dat;
        D.trials(i).label = conditionlabels{i};
        D.trials(i).onset = trl(i, 1)./D.Fsample;
        D.trials(i).events = select_events(event, ...
            [ trl(i, 1)./D.Fsample-S.eventpadding  trl(i, 2)./D.Fsample+S.eventpadding]);
    end

    if ismember(i, Ibar)
        spm_progress_bar('Set', i);
    end

end

spm_progress_bar('Clear');

% Specify sensor positions and fiducials
if isfield(hdr, 'grad')
    D.sensors.meg = forwinv_convert_units(hdr.grad, 'mm');
end
if isfield(hdr, 'elec')
    D.sensors.eeg = forwinv_convert_units(hdr.elec, 'mm');
else
    try
        D.sensors.eeg = forwinv_convert_units(fileio_read_sens(S.dataset, 'fileformat', S.inputformat), 'mm');
        % It might be that read_sens will return the grad for MEG datasets
        if isfield(D.sensors.eeg, 'ori')
            D.sensors.eeg = [];
        end
    catch
        warning('Could not obtain electrode locations automatically.');
    end
end

try
    D.fiducials = forwinv_convert_units(fileio_read_headshape(S.dataset, 'fileformat', S.inputformat), 'mm');
catch
    warning('Could not obtain fiducials automatically.');
end

%--------- Create meeg object
D.fname = [S.outfile '.mat'];

D = meeg(D);

% history
D = D.history('spm_eeg_convert', S);

if isfield(hdr, 'orig')
    if S.saveorigheader
        D.origheader = hdr.orig;
    end
    
    % Uses fileio function to get the information about channel types stored in
    % the original header. This is now mainly useful for Neuromag support but might
    % have other functions in the future.
    origchantypes = fileio_chantype(hdr);
    [sel1, sel2] = spm_match_str(D.chanlabels, hdr.label);
    origchantypes = origchantypes(sel2);
    if length(strmatch('unknown', origchantypes, 'exact')) ~= numel(origchantypes)
        D.origchantypes = struct([]);
        D.origchantypes(1).label = hdr.label(sel2);
        D.origchantypes(1).type = origchantypes;
    end
end

S1 = [];
S1.task = 'defaulttype';
S1.D = D;
S1.updatehistory = 0;
D = spm_eeg_prep(S1);

% Assign default EEG sensor positions if possible
if ~isempty(strmatch('EEG', D.chantype, 'exact'))
    if isempty(D.sensors('EEG'))
        S1 = [];
        S1.task = 'defaulteegsens';
        S1.updatehistory = 0;
        S1.D = D;

        D = spm_eeg_prep(S1);
    else
        S1 = [];
        S1.task = 'project3D';
        S1.modality = 'EEG';
        S1.updatehistory = 0;
        S1.D = D;

        D = spm_eeg_prep(S1);
    end
end

% Create 2D positions for MEG 
% by projecting the 3D positions to 2D
if ~isempty(strmatch('MEG', D.chantype)) && ~isempty(D.sensors('MEG')) 
    S1 = [];
    S1.task = 'project3D';
    S1.modality = 'MEG';
    S1.updatehistory = 0;
    S1.D = D;
    
    D = spm_eeg_prep(S1);
end

% If channel units are available, store them.
if isfield(hdr, 'unit')
    [sel1, sel2] = spm_match_str(D.chanlabels, hdr.label);
    D = units(D, sel1, hdr.unit(sel2));
end

% The conditions will later be sorted in the original order they were defined.
if isfield(S, 'trialdef')
    D = condlist(D, {S.trialdef(:).conditionlabel});
end

save(D);

%==========================================================================
% select_events
%==========================================================================
function event = select_events(event, timeseg)
% Utility function to select events according to time segment
% FORMAT event = select_events(event, timeseg)

if ~isempty(event)
    [time ind] = sort([event(:).time]);

    selectind = ind(time>=timeseg(1) & time<=timeseg(2));

    event = event(selectind);
end