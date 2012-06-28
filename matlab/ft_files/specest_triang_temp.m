function [spectrum,ntaper,freqoi,timeoi,wlt] = specest_triang_temp(dat, time, varargin)

% FT_SPECEST_MTMCONVOL performs wavelet convolution in the time domain
% by multiplication in the frequency domain
%
% Use as
%   [spectrum,freqoi,timeoi] = specest_mtmconvol(dat,time,...)
% where
%   dat      = matrix of chan*sample
%   time     = vector, containing time in seconds for each sample
%   spectrum = matrix of ntaper*chan*freqoi*timeoi of fourier coefficients
%   ntaper   = vector containing the number of tapers per freqoi
%   freqoi   = vector of frequencies in spectrum
%   timeoi   = vector of timebins in spectrum
%
% Optional arguments should be specified in key-value pairs and can include:
%   taper     = 'dpss', 'hanning' or many others, see WINDOW (default = 'dpss')
%   pad       = number, indicating time-length of data to be padded out to in seconds
%   timeoi    = vector, containing time points of interest (in seconds)
%   timwin    = vector, containing length of time windows (in seconds)
%   freqoi    = vector, containing frequencies (in Hz)
%   tapsmofrq = number, the amount of spectral smoothing through multi-tapering. Note: 4 Hz smoothing means plus-minus 4 Hz, i.e. a 8 Hz smoothing box
%   dimord    = 'tap_chan_freq_time' (default) or 'chan_time_freqtap' for
%                memory efficiency
%   verbose   = output progress to console (0 or 1, default 1)
%   taperopt  = parameter to use for window (see WINDOW)
%   polyorder = number, the order of the polynomial to fitted to and removed from the data
%                  prior to the fourier transform (default = 0 -> remove DC-component)
%
% See also FT_FREQANALYSIS, FT_SPECEST_MTMFFT, FT_SPECEST_TFR, FT_SPECEST_HILBERT, FT_SPECEST_WAVELET

% Copyright (C) 2010, Donders Institute for Brain, Cognition and Behaviour
%
% $Id: ft_specest_mtmconvol.m 5106 2012-01-10 13:10:28Z jansch $

% get the optional input arguments
taper     = ft_getopt(varargin, 'taper', 'dpss');
pad       = ft_getopt(varargin, 'pad');
timeoi    = ft_getopt(varargin, 'timeoi', 'all');
timwin    = ft_getopt(varargin, 'timwin');
freqoi    = ft_getopt(varargin, 'freqoi', 'all');
tapsmofrq = ft_getopt(varargin, 'tapsmofrq');
dimord    = ft_getopt(varargin, 'dimord', 'tap_chan_freq_time');
fbopt     = ft_getopt(varargin, 'feedback');
verbose   = false;%ft_getopt(varargin, 'verbose', true);
polyorder = ft_getopt(varargin, 'polyorder', 0);
tapopt    = ft_getopt(varargin, 'taperopt');

if isempty(fbopt),
    fbopt.i = 1;
    fbopt.n = 1;
end

% throw errors for required input
if isempty(tapsmofrq) && strcmp(taper, 'dpss')
    error('you need to specify tapsmofrq when using dpss tapers')
end
if isempty(timwin)
    error('you need to specify timwin')
elseif (length(timwin) ~= length(freqoi) && ~strcmp(freqoi,'all'))
    error('timwin should be of equal length as freqoi')
end
tail=[];
for vi=1:2:length(varargin)
    if strcmp(varargin{vi},'tail')
        tail=varargin{vi+1};
    end
end
% Set n's

[nchan,ndatsample] = size(dat);

% Remove polynomial fit from the data -> default is demeaning
if polyorder >= 0
    dat = ft_preproc_polyremoval(dat, polyorder, 1, ndatsample);
end

% Determine fsample and set total time-length of data
fsample = 1./mean(diff(time));
dattime = ndatsample / fsample; % total time in seconds of input data

% Zero padding
if round(pad * fsample) < ndatsample
    error('the padding that you specified is shorter than the data');
end
if isempty(pad) % if no padding is specified padding is equal to current data length
    pad = dattime;
end
postpad = zeros(1,round((pad - dattime) * fsample));
endnsample = round(pad * fsample);  % total number of samples of padded data
endtime    = pad;            % total time in seconds of padded data

% Set freqboi and freqoi
if isnumeric(freqoi) % if input is a vector
    freqboi   = round(freqoi ./ (fsample ./ endnsample)) + 1;
    freqboi   = unique(freqboi);
    freqoi    = (freqboi-1) ./ endtime; % boi - 1 because 0 Hz is included in fourier output
elseif strcmp(freqoi,'all')
    freqboilim = round([0 fsample/2] ./ (fsample ./ endnsample)) + 1;
    freqboi    = freqboilim(1):1:freqboilim(2);
    freqoi     = (freqboi-1) ./ endtime;
end
% check for freqoi = 0 and remove it, there is no wavelet for freqoi = 0
if freqoi(1)==0
    freqoi(1)  = [];
    freqboi(1) = [];
    if length(timwin) == (length(freqoi) + 1)
        timwin(1) = [];
    end
end
nfreqboi = length(freqboi);
nfreqoi  = length(freqoi);

% Set timeboi and timeoi
offset = round(time(1)*fsample);
if isnumeric(timeoi) % if input is a vector
    timeboi  = round(timeoi .* fsample - offset) + 1;
    ntimeboi = length(timeboi);
    timeoi   = round(timeoi .* fsample) ./ fsample;
elseif strcmp(timeoi,'all') % if input was 'all'
    timeboi  = 1:length(time);
    ntimeboi = length(timeboi);
    timeoi   = time;
end

% set number of samples per time-window (timwin is in seconds)
timwinsample = round(timwin .* fsample);

% Compute tapers per frequency, multiply with wavelets and compute their fft
wltspctrm = cell(nfreqoi,1);
ntaper    = zeros(nfreqoi,1);
for ifreqoi = 1:nfreqoi
    
    % create a single taper according to the window specification as a replacement for the DPSS (Slepian) sequence
    
    tap = window(taper, timwinsample(ifreqoi))';
    
    tap = tap ./ norm(tap,'fro'); % make it explicit that the frobenius norm is being used
    
    % set number of tapers
    ntaper(ifreqoi) = size(tap,1);
    
    % Wavelet construction
    tappad   = ceil(endnsample ./ 2) - floor(timwinsample(ifreqoi) ./ 2);
    prezero  = zeros(1,tappad);
    postzero = zeros(1,round(endnsample) - ((tappad-1) + timwinsample(ifreqoi))-1);
    
    % phase consistency: cos must always be 1  and sin must always be centered in upgoing flank, so the centre of the wavelet (untapered) has angle = 0
    anglein  = (-(timwinsample(ifreqoi)-1)/2 : (timwinsample(ifreqoi)-1)/2)'   .*  ((2.*pi./fsample) .* freqoi(ifreqoi));
    wltspctrm{ifreqoi} = complex(zeros(size(tap,1),round(endnsample)));
    
    for itap = 1:ntaper(ifreqoi)
        try
            
            % store the tap wavelet
            if ~isempty(tail)
                ztail=zeros(size(tap));
                if strcmp(tail,'end')
                    tap=[tap ztail];
                elseif strcmp(tail,'beg')
                    tap=[ztail tap];
                elseif strcmp(tail,'both')
                    tap=[ztail tap ztail];
                end
            end
           wlt{ifreqoi}(itap,:) = tap;  
        end
    end
end

% Switch between memory efficient representation or intuitive default representation




% create tapfreqind
freqtapind = [];
tempntaper = [0; cumsum(ntaper(:))];
for ifreqoi = 1:nfreqoi
    freqtapind{ifreqoi} = tempntaper(ifreqoi)+1:tempntaper(ifreqoi+1);
end

% start fft'ing

%datspectrum = transpose(fft(transpose([dat repmat(postpad,[nchan, 1])]))); % double explicit transpose to speedup fft
spectrum = complex(zeros([nchan ntimeboi sum(ntaper)]));
for ifreqoi = 1:nfreqoi
    str = sprintf('frequency %d (%.2f Hz), %d tapers', ifreqoi,freqoi(ifreqoi),ntaper(ifreqoi));
    [st, cws] = dbstack;
    if length(st)>1 && strcmp(st(2).name, 'ft_freqanalysis') && verbose
        % specest_mtmconvol has been called by ft_freqanalysis, meaning that ft_progress has been initialised
        ft_progress(fbopt.i./fbopt.n, ['trial %d, ',str,'\n'], fbopt.i);
    elseif verbose
        fprintf([str, '\n']);
    end
    for itap = 1:ntaper(ifreqoi)
        % compute indices that will be used to extracted the requested fft output
        nsamplefreqoi    = timwin(ifreqoi) .* fsample;
        reqtimeboiind    = find((timeboi >=  (nsamplefreqoi ./ 2)) & (timeboi <    (ndatsample - (nsamplefreqoi ./2))));
        reqtimeboi       = timeboi(reqtimeboiind);
        
        % compute data*wavelet, if there are reqtimeboi's that have data
        
        
        for chi=1:nchan
            x=dat(chi,:);
            % baseline correction for the template
            tapBlc = wlt{1,ifreqoi}-mean(wlt{1,ifreqoi});
            % normalizing the template
            tmplt=tapBlc./sqrt(sum(tapBlc.*tapBlc));
            % find max point for the template
            [~,time0]=max(tmplt);
            % do the fit
            [SNR,SigX,sigSign]=fitTemp(x,tmplt,time0);
%             sx=smooth(x,10);
%             pos=sx>0;neg=-(sx<0);posneg=pos+neg;
%             SNRn=SNR.*posneg';
            SNRn=SNR.*sigSign;
            spectrum(chi,:,freqtapind{ifreqoi}(itap)) = SNRn(timeboi);
        end
    end
end % for nfreqoi


