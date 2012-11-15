function [freq,wlt] = freqanalysis_triang_temp(cfg, data)
% this function finds transient activity in raw, unaveraged data.
% the data should be 1Hz highpass filtered with no lowpass filter.
% the template is allways a triangle ( /\ )
% tail - zeros added to the template at the beginning ( __/\ ), end ( /\__ ) or both
% sides of the template ( __/\__ ).
%
% NOTE!!! for convenience only the function is based on ft_freqanalysis.
% this function multiplies data by a triangular template, in the TIME, and
% not frequency domain. the template changes it's width according to "freq"
% but this is no freqanalysis at all. 10Hz means that the triangular
% template used was 100ms wide, nothing to do with 10Hz oscilations.
% therefore the freq.powspctrm results field are not really power spectrum
% but kept this way for visualization with ft_multiplotTFR.

% 
% cfg              = [];
% cfg.keeptrials = 'yes';
% cfg.output       = 'pow';
% cfg.channel      = 'MEG';
% cfg.method       = 'mtmconvol';
% cfg.taper        ='triang'; % not required
% cfg.foi          = [5:30];                            % freq of interest 3 to 100Hz
% cfg.t_ftimwin    = 1./cfg.foi;   % ones(length(cfg.foi),1).*0.5;  % length of time window fixed at 0.5 sec
% cfg.toi          = -0.2:0.005:0.7;                  % time window "slides" from -0.1 to 0.5 sec in steps of 0.02 sec (20 ms)
% cfg.tapsmofrq  = 1;
% cfg.trials='all';%[1:2];
% cfg.channel='A191';
% cfg.tail=[]; % pad the template with zeros, 'beg' 'end' 'both' or [] for no padding
% [TF,wlt] = freqanalysis_triang_temp(cfg, dataNoMOG);



revision = '$Id: ft_freqanalysis.m 5207 2012-02-01 13:40:36Z sashae $';

% do the general setup of the function
ft_defaults
ft_preamble help
ft_preamble callinfo
ft_preamble trackconfig
ft_preamble loadvar data

% defaults for optional input/ouputfile and feedback
cfg.inputfile  = ft_getopt(cfg, 'inputfile',  []);
cfg.outputfile = ft_getopt(cfg, 'outputfile', []);
cfg.feedback   = ft_getopt(cfg, 'feedback',   'text');
cfg.inputlock  = ft_getopt(cfg, 'inputlock',  []);  % this can be used as mutex when doing peercellfun or another distributed computation
cfg.outputlock = ft_getopt(cfg, 'outputlock', []);  % this can be used as mutex when doing peercellfun or another distributed computation

% check if the input data is valid for this function
data = ft_checkdata(data, 'datatype', {'raw', 'comp', 'mvar'}, 'feedback', cfg.feedback, 'hassampleinfo', 'yes');

% select trials of interest
cfg.trials = ft_getopt(cfg, 'trials', 'all');
if ~strcmp(cfg.trials, 'all')
    fprintf('selecting %d trials\n', length(cfg.trials));
    data = ft_selectdata(data, 'rpt', cfg.trials);
end

% check if the input cfg is valid for this function
cfg = ft_checkconfig(cfg, 'renamed',     {'label', 'channel'});
cfg = ft_checkconfig(cfg, 'renamed',     {'sgn',   'channel'});
cfg = ft_checkconfig(cfg, 'renamed',     {'labelcmb', 'channelcmb'});
cfg = ft_checkconfig(cfg, 'renamed',     {'sgncmb',   'channelcmb'});
cfg = ft_checkconfig(cfg, 'required',    {'method'});
cfg = ft_checkconfig(cfg, 'renamedval',  {'method', 'fft',    'mtmfft'});
cfg = ft_checkconfig(cfg, 'renamedval',  {'method', 'convol', 'mtmconvol'});





cfg.taper = 'triang';
% check for foi above Nyquist



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% HERE THE NEW IMPLEMENTATION STARTS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% set all the defaults
cfg.pad       = ft_getopt(cfg, 'pad',       'maxperlen');
cfg.output    =  'pow';
cfg.calcdof   = ft_getopt(cfg, 'calcdof',   'no');
cfg.channel   = ft_getopt(cfg, 'channel',   'all');
cfg.precision = ft_getopt(cfg, 'precision', 'double');
cfg.foi       = ft_getopt(cfg, 'foi',       []);
cfg.foilim    = ft_getopt(cfg, 'foilim',    []);
cfg.correctt_ftimwin = ft_getopt(cfg, 'correctt_ftimwin', 'no');
cfg.polyremoval      = ft_getopt(cfg, 'polyremoval', 0);

cfg.keeptrials = ft_getopt(cfg, 'keeptrials', 'no');
cfg.keeptapers = ft_getopt(cfg, 'keeptapers', 'no');

% set flags for keeping trials and/or tapers
if strcmp(cfg.keeptrials,'no') &&  strcmp(cfg.keeptapers,'no')
    keeprpt = 1;
elseif strcmp(cfg.keeptrials,'yes') &&  strcmp(cfg.keeptapers,'no')
    keeprpt = 2;
elseif strcmp(cfg.keeptrials,'no') &&  strcmp(cfg.keeptapers,'yes')
    error('There is currently no support for keeping tapers WITHOUT KEEPING TRIALS.');
elseif strcmp(cfg.keeptrials,'yes') &&  strcmp(cfg.keeptapers,'yes')
    keeprpt = 4;
end


powflg = 1;
csdflg = 0;
fftflg = 0;



% ensure that channelselection and selection of channelcombinations is
% perfomed consistently
cfg.channel = ft_channelselection(cfg.channel, data.label);


selchan = cfg.channel;


% subselect the required channels
data = ft_selectdata(data, 'channel', selchan);

% determine the corresponding indices of all channels
chanind    = match_str(data.label, cfg.channel);
nchan      = size(chanind,1);


% determine trial characteristics
ntrials = numel(data.trial);
trllength = zeros(1, ntrials);
for itrial = 1:ntrials
    trllength(itrial) = size(data.trial{itrial}, 2);
end
if strcmp(cfg.pad, 'maxperlen')
    padding = max(trllength);
    cfg.pad = padding/data.fsample;
else
    padding = cfg.pad*data.fsample;
    if padding<max(trllength)
        error('the specified padding is too short');
    end
end

% correct foi and implement foilim 'backwards compatibility'
if ~isempty(cfg.foi) && ~isempty(cfg.foilim)
    error('use either cfg.foi or cfg.foilim')
elseif ~isempty(cfg.foilim)
    % get the full foi in the current foilim and set it too be used as foilim
    fboilim = round(cfg.foilim ./ (data.fsample ./ (cfg.pad*data.fsample))) + 1;
    fboi    = fboilim(1):1:fboilim(2);
    cfg.foi = (fboi-1) ./ cfg.pad;
else
    % correct foi if foilim was empty and try to correct t_ftimwin (by detecting whether there is a constant factor between foi and t_ftimwin: cyclenum)
    oldfoi = cfg.foi;
    fboi   = round(cfg.foi ./ (data.fsample ./ (cfg.pad*data.fsample))) + 1;
    cfg.foi    = (fboi-1) ./ cfg.pad; % boi - 1 because 0 Hz is included in fourier output
    if strcmp(cfg.correctt_ftimwin,'yes')
        cyclenum = oldfoi .* cfg.t_ftimwin;
        cfg.t_ftimwin = cyclenum ./ cfg.foi;
    end
end

% tapsmofrq compatibility between functions (make it into a vector if it's not)
if isfield(cfg,'tapsmofrq')
    if strcmp(cfg.method,'mtmconvol') && length(cfg.tapsmofrq) == 1 && length(cfg.foi) ~= 1
        cfg.tapsmofrq = ones(length(cfg.foi),1) * cfg.tapsmofrq;
    end
end

% options that don't change over trials
if isfield(cfg,'tapsmofrq')
    options = {'pad', cfg.pad, 'freqoi', cfg.foi, 'tapsmofrq', cfg.tapsmofrq, 'polyorder', cfg.polyremoval};
else
    options = {'pad', cfg.pad, 'freqoi', cfg.foi, 'polyorder', cfg.polyremoval};
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Main loop over trials, inside fourierspectra are obtained and transformed into the appropriate outputs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% this is done on trial basis to save memory
if ~isfield(cfg,'feedback')
    cfg.feedback='yes';
end
ft_progress('init', cfg.feedback, 'processing trials');
for itrial = 1:ntrials
    if strcmp(cfg.feedback,'yes')
    display(['TRIAL ',num2str(itrial),' of ',num2str(ntrials)])
    end
    
    %disp(['processing trial ' num2str(itrial) ': ' num2str(size(data.trial{itrial},2)) ' samples']);
    fbopt.i = itrial;
    fbopt.n = ntrials;
    
    dat = data.trial{itrial}; % chansel has already been performed
    time = data.time{itrial};
    
    % Perform specest call and set some specifics
    clear spectrum % in case of very large trials, this lowers peak mem usage a bit
    
    [spectrum_mtmconvol,ntaper,foi,toi,wlt] = specest_triang_temp(dat, time,'tail',cfg.tail, 'timeoi', cfg.toi, 'timwin', cfg.t_ftimwin, 'taper', ...
        cfg.taper, options{:}, 'dimord', 'chan_time_freqtap', 'feedback', fbopt);
    
    % the following variable is created to keep track of the number of
    % trials per time bin and is needed for proper normalization if
    % keeprpt==1 and the triallength is variable
    if itrial==1, trlcnt = zeros(1, numel(foi), numel(toi)); end
    
    hastime = true;
    % error for different number of tapers per trial
    if (keeprpt == 4) && any(ntaper(:) ~= ntaper(1))
        error('currently you can only keep trials AND tapers, when using the number of tapers per frequency is equal across frequency')
    end
    % create tapfreqind for later indexing
    freqtapind = [];
    tempntaper = [0; cumsum(ntaper(:))];
    for iindfoi = 1:numel(foi)
        freqtapind{iindfoi} = tempntaper(iindfoi)+1:tempntaper(iindfoi+1);
    end
    
    
    % Set n's
    maxtap = max(ntaper);
    nfoi   = numel(foi);
    if hastime
        ntoi = numel(toi);
    else
        ntoi = 1; % this makes the same code compatible for hastime = false, as time is always the last dimension, and if singleton will disappear
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%% Memory allocation
    % memory allocation for mtmfft is slightly different because of the possiblity of variable number of tapers over trials (when using dpss), the below exception
    % is made so memory can still be allocated fully (see bug #1025
    if strcmp(cfg.method, 'mtmfft') && strcmp(cfg.taper,'dpss')
        trllength = cellfun(@numel,data.time);
        % determine number of tapers per trial
        ntaptrl = sum(floor((2 .* (trllength./data.fsample) .* cfg.tapsmofrq) - 1)); % I floored it for now, because I don't know whether this formula is accurate in all cases, by flooring the memory allocated
        % will most likely be less than it should be, but this would still have the same effect of 'not-crashing-matlabs'.
        % I do have the feeling a round would be 100% accurate, but atm I cannot check this in Percival and Walden
        % - roevdmei
    else
        ntaptrl = ntrials .* maxtap; % the way it used to be in all cases (before bug #1025)
    end
    
    % by default, everything is has the time dimension, if not, some specifics are performed
    if itrial == 1
        % allocate memory to output variables
        if keeprpt == 1 % cfg.keeptrials,'no' &&  cfg.keeptapers,'no'
            if powflg, powspctrm     = zeros(nchan,nfoi,ntoi,cfg.precision);             end
            if csdflg, crsspctrm     = complex(zeros(nchancmb,nfoi,ntoi,cfg.precision)); end
            if fftflg, fourierspctrm = complex(zeros(nchan,nfoi,ntoi,cfg.precision));    end
            dimord    = 'chan_freq_time';
        elseif keeprpt == 2 % cfg.keeptrials,'yes' &&  cfg.keeptapers,'no'
            if powflg, powspctrm     = nan+zeros(ntrials,nchan,nfoi,ntoi,cfg.precision);                                                                 end
            if csdflg, crsspctrm     = complex(nan+zeros(ntrials,nchancmb,nfoi,ntoi,cfg.precision),nan+zeros(ntrials,nchancmb,nfoi,ntoi,cfg.precision)); end
            if fftflg, fourierspctrm = complex(nan+zeros(ntrials,nchan,nfoi,ntoi,cfg.precision),nan+zeros(ntrials,nchan,nfoi,ntoi,cfg.precision));       end
            dimord    = 'rpt_chan_freq_time';
        elseif keeprpt == 4 % cfg.keeptrials,'yes' &&  cfg.keeptapers,'yes'
            if powflg, powspctrm     = zeros(ntaptrl,nchan,nfoi,ntoi,cfg.precision);        end %
            if csdflg, crsspctrm     = complex(zeros(ntaptrl,nchancmb,nfoi,ntoi,cfg.precision)); end
            if fftflg, fourierspctrm = complex(zeros(ntaptrl,nchan,nfoi,ntoi,cfg.precision));    end
            dimord    = 'rpttap_chan_freq_time';
        end
        if ~hastime
            dimord = dimord(1:end-5); % cut _time
        end
        
        % prepare calcdof
        if strcmp(cfg.calcdof,'yes')
            if hastime
                dof = zeros(nfoi,ntoi);
                %dof = zeros(ntrials,nfoi,ntoi);
            else
                dof = zeros(nfoi,1);
                %dof = zeros(ntrials,nfoi);
            end
        end
        
        % prepare cumtapcnt
        switch cfg.method %% IMPORTANT, SHOULD WE KEEP THIS SPLIT UP PER METHOD OR GO FOR A GENERAL SOLUTION NOW THAT WE HAVE SPECEST
            case 'mtmconvol'
                cumtapcnt = zeros(ntrials,nfoi);
            case 'mtmfft'
                cumtapcnt = zeros(ntrials,1);
        end
        
    end
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%% Create output
    if keeprpt~=4
        
        for ifoi = 1:nfoi
            
            % mtmconvol is a special case and needs special processing
            if strcmp(cfg.method,'mtmconvol')
                spectrum = reshape(permute(spectrum_mtmconvol(:,:,freqtapind{ifoi}),[3 1 2]),[ntaper(ifoi) nchan 1 ntoi]);
                foiind = ones(1,nfoi);
            else
                foiind = 1:nfoi; % by using this vector below for indexing, the below code does not need to be duplicated for mtmconvol
            end
            
            % set ingredients for below
            acttboi  = squeeze(~isnan(spectrum(1,1,foiind(ifoi),:)));
            nacttboi = sum(acttboi);
            if ~hastime
                acttboi  = 1;
                nacttboi = 1;
            elseif sum(acttboi)==0
                %nacttboi = 1;
            end
            acttap = squeeze(~isnan(spectrum(:,1,foiind(ifoi),find(acttboi,1))));
            acttap = logical([ones(ntaper(ifoi),1);zeros(size(spectrum,1)-ntaper(ifoi),1)]);
            if powflg
                powdum = spectrum(acttap,:,foiind(ifoi),acttboi);
                % sinetaper scaling is disabled, because it is not consistent with the other
                % tapers. if scaling is required, please specify cfg.taper =
                % 'sine_old'
                
                %         if isfield(cfg,'taper') && strcmp(cfg.taper, 'sine')
                %             %sinetapscale = zeros(ntaper(ifoi),nfoi);  % assumes fixed number of tapers
                %             sinetapscale = zeros(ntaper(ifoi),1);  % assumes fixed number of tapers
                %             for isinetap = 1:ntaper(ifoi)  % assumes fixed number of tapers
                %               sinetapscale(isinetap,:) = (1 - (((isinetap - 1) ./ ntaper(ifoi)) .^ 2));
                %             end
                %             sinetapscale = reshape(repmat(sinetapscale,[1 1 nchan ntoi]),[ntaper(ifoi) nchan 1 ntoi]);
                %             powdum = powdum .* sinetapscale;
                %           end
            end
            if fftflg
                fourierdum = spectrum(acttap,:,foiind(ifoi),acttboi);
            end
            if csdflg
                csddum =      spectrum(acttap,cutdatindcmb(:,1),foiind(ifoi),acttboi) .* ...
                    conj(spectrum(acttap,cutdatindcmb(:,2),foiind(ifoi),acttboi));
            end
            
            % switch between keep's
            switch keeprpt
                
                case 1 % cfg.keeptrials,'no' &&  cfg.keeptapers,'no'
                    if exist('trlcnt', 'var'),
                        trlcnt(1, ifoi, :) = trlcnt(1, ifoi, :) + shiftdim(double(acttboi(:)'),-1);
                    end
                    
                    if powflg
                        powspctrm(:,ifoi,acttboi) = powspctrm(:,ifoi,acttboi) + (reshape(mean(powdum,1),[nchan 1 nacttboi]) ./ ntrials);
                        %powspctrm(:,ifoi,~acttboi) = NaN;
                    end
                    if fftflg
                        fourierspctrm(:,ifoi,acttboi) = fourierspctrm(:,ifoi,acttboi) + (reshape(mean(fourierdum,1),[nchan 1 nacttboi]) ./ ntrials);
                        %fourierspctrm(:,ifoi,~acttboi) = NaN;
                    end
                    if csdflg
                        crsspctrm(:,ifoi,acttboi) = crsspctrm(:,ifoi,acttboi) + (reshape(mean(csddum,1),[nchancmb 1 nacttboi]) ./ ntrials);
                        %crsspctrm(:,ifoi,~acttboi) = NaN;
                    end
                    
                case 2 % cfg.keeptrials,'yes' &&  cfg.keeptapers,'no'
                    if powflg
                        powspctrm(itrial,:,ifoi,acttboi) = reshape(mean(powdum,1),[nchan 1 nacttboi]);
                        powspctrm(itrial,:,ifoi,~acttboi) = NaN;
                    end
                    if fftflg
                        fourierspctrm(itrial,:,ifoi,acttboi) = reshape(mean(fourierdum,1), [nchan 1 nacttboi]);
                        fourierspctrm(itrial,:,ifoi,~acttboi) = NaN;
                    end
                    if csdflg
                        crsspctrm(itrial,:,ifoi,acttboi) = reshape(mean(csddum,1), [nchancmb 1 nacttboi]);
                        crsspctrm(itrial,:,ifoi,~acttboi) = NaN;
                    end
                    
            end % switch keeprpt
            
            % do calcdof  dof = zeros(numper,numfoi,numtoi);
            if strcmp(cfg.calcdof,'yes')
                if hastime
                    acttimboiind = ~isnan(squeeze(spectrum(1,1,foiind(ifoi),:)));
                    dof(ifoi,acttimboiind) = ntaper(ifoi) + dof(ifoi,acttimboiind);
                else % hastime = false
                    dof(ifoi) = ntaper(ifoi) + dof(ifoi);
                end
            end
        end %ifoi
        
    else
        % keep tapers
        if ~exist('tapcounter', 'var')
            tapcounter = 0;
        end
        
        if strcmp(cfg.method,'mtmconvol')
            spectrum = permute(reshape(spectrum_mtmconvol,[nchan ntoi ntaper(1) nfoi]),[3 1 4 2]);
        end
        
        currrptind  = tapcounter + (1:maxtap);
        tapcounter  = currrptind(end);
        %rptind = reshape(1:ntrials .* maxtap,[maxtap ntrials]);
        %currrptind = rptind(:,itrial);
        if powflg
            powspctrm(currrptind,:,:) = abs(spectrum).^2;
        end
        if fftflg
            fourierspctrm(currrptind,:,:,:) = spectrum;
        end
        if csdflg
            crsspctrm(currrptind,:,:,:) =          spectrum(cutdatindcmb(:,1),:,:) .* ...
                conj(spectrum(cutdatindcmb(:,2),:,:));
        end
        
    end
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    % set cumptapcnt
    switch cfg.method %% IMPORTANT, SHOULD WE KEEP THIS SPLIT UP PER METHOD OR GO FOR A GENERAL SOLUTION NOW THAT WE HAVE SPECEST
        case {'mtmconvol' 'wavelet'}
            cumtapcnt(itrial,:) = ntaper;
        case 'mtmfft'
            cumtapcnt(itrial,1) = ntaper(1); % fixed number of tapers? for the moment, yes, as specest_mtmfft computes only one set of tapers
    end
    
end % for ntrials
ft_progress('close');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% END: Main loop over trials
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% re-normalise the TFRs if keeprpt==1
if (strcmp(cfg.method, 'mtmconvol') || strcmp(cfg.method, 'wavelet')) && keeprpt==1
    nanmask = trlcnt==0;
    if powflg
        powspctrm = powspctrm.*ntrials;
        powspctrm = powspctrm./trlcnt(ones(size(powspctrm,1),1),:,:);
        powspctrm(nanmask(ones(size(powspctrm,1),1),:,:)) = nan;
    end
    if fftflg
        fourierspctrm = fourierspctrm.*ntrials;
        fourierspctrm = fourierspctrm./trlcnt(ones(size(fourierspctrm,1),1),:,:);
        fourierspctrm(nanmask(ones(size(fourierspctrm,1),1),:,:)) = nan;
    end
    if csdflg
        crsspctrm = crsspctrm.*ntrials;
        crsspctrm = crsspctrm./trlcnt(ones(size(crsspctrm,1),1),:,:);
        crsspctrm(nanmask(ones(size(crsspctrm,1),1),:,:)) = nan;
    end
end

% set output variables
freq = [];
freq.label = data.label;
freq.dimord = dimord;
freq.freq   = foi;
hasdc       = find(foi==0);
hasnyq      = find(foi==data.fsample./2);
hasdc_nyq   = [hasdc hasnyq];
if exist('toi','var')
    freq.time = toi;
end
if powflg
    % correct the 0 Hz or Nyqist bin if present, scaling with a factor of 2 is only appropriate for ~0 Hz
    if ~isempty(hasdc_nyq)
        if keeprpt>1
            powspctrm(:,:,hasdc_nyq,:) = powspctrm(:,:,hasdc_nyq,:)./2;
        else
            powspctrm(:,hasdc_nyq,:) = powspctrm(:,hasdc_nyq,:)./2;
        end
    end
    freq.powspctrm = powspctrm;
end
if fftflg
    % correct the 0 Hz or Nyqist bin if present, scaling with a factor of 2 is only appropriate for ~0 Hz
    if ~isempty(hasdc_nyq)
        if keeprpt>1
            fourierspctrm(:,:,hasdc_nyq,:) = fourierspctrm(:,:,hasdc_nyq,:)./sqrt(2);
        else
            fourierspctrm(:,hasdc_nyq,:) = fourierspctrm(:,hasdc_nyq,:)./sqrt(2);
        end
    end
    freq.fourierspctrm = fourierspctrm;
end
if csdflg
    % correct the 0 Hz or Nyqist bin if present, scaling with a factor of 2 is only appropriate for ~0 Hz
    if ~isempty(hasdc_nyq)
        if keeprpt>1
            crsspctrm(:,:,hasdc_nyq,:) = crsspctrm(:,:,hasdc_nyq,:)./2;
        else
            crsspctrm(:,hasdc_nyq,:) = crsspctrm(:,hasdc_nyq,:)./2;
        end
    end
    freq.labelcmb  = cfg.channelcmb;
    freq.crsspctrm = crsspctrm;
end
if strcmp(cfg.calcdof,'yes');
    freq.dof = 2 .* dof;
end;
if strcmp(cfg.method,'mtmfft') && (keeprpt == 2 || keeprpt == 4)
    freq.cumsumcnt = trllength';
end
if exist('cumtapcnt','var')
    freq.cumtapcnt = cumtapcnt;
end

% backwards compatability of foilim
if ~isempty(cfg.foilim)
    cfg = rmfield(cfg,'foi');
else
    cfg = rmfield(cfg,'foilim');
end

if isfield(data, 'grad'),
    freq.grad = data.grad;
end   % remember the gradiometer array
if isfield(data, 'elec'),
    freq.elec = data.elec;
end   % remember the electrode array

% do the general cleanup and bookkeeping at the end of the function
ft_postamble trackconfig
ft_postamble callinfo
ft_postamble previous data
ft_postamble history freq
% IF OLD OR NEW IMPLEMENTATION

% copy the trial specific information into the output
if isfield(cfg, 'keeptrials') && strcmp(cfg.keeptrials, 'yes') && isfield(data, 'trialinfo'),
    freq.trialinfo = data.trialinfo;
end

ft_postamble savevar freq
