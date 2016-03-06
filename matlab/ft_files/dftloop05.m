function [filt,est,tfr] = dftloop05(dat, Fs, Fl)
% based on the ft function as described below, just wanted to get more OP
% options, Yuval
% designed to allow processing also when you only have half cycle (1Hz
% with 500ms window)
% filt is data filtered of Fl frequency
% est is the noise that was reduced from the data
% tfr is sort of time frequency output

% FT_PREPROC_DFTFILTER applies a notch filter to the data to remove the 50Hz
% or 60Hz line noise components. This is done by fitting a sine and cosine
% at the specified frequency to the data and subsequently subtracting the
% estimated components. The longer the data is, the sharper the spectral
% notch will be that is removed from the data.
%
% Use as
%   [filt] = ft_preproc_dftfilter(dat, Fsample, Fline)
% where
%   dat        data matrix (Nchans X Ntime)
%   Fsample    sampling frequency in Hz
%   Fline      line noise frequency
%
% Copyright (C) 2003, Pascal Fries
% Copyright (C) 2003-2008, Robert Oostenveld
% license GNU General Public License, see <http://www.gnu.org/licenses/>.
%


win=ceil(Fs./Fl./2);
% determine the size of the data
[nchans, nsamples] = size(dat);
if nsamples==1 && nchans>1
    clear nchans
    dat=dat';
    [~, nsamples] = size(dat);
end
% set the default filter frequency
if nargin<3 || isempty(Fl)
    Fl = 50;
end

% ensure to be a column  vector
if length(Fl)>1
    error('one frequency at a time please');
end

% determine the largest integer number of line-noise cycles that fits in the data
n   = floor(nsamples/win);
if nsamples<n
    error('you must have half a cycle for good baseline correction (e.g. 50ms for 10Hz estimate)')
end
%meandat = mean(dat(:,1:n05),2);


time = (0:win-1)/Fs;
tmp  = exp(1i*2*pi*Fl*time); 
filt=dat;
tfr=zeros(size(dat));
for segmenti=1:n
    sel=(segmenti*win-win+1):segmenti*win;
    % temporarily remove mean to avoid leakage
    datSeg=dat(:,sel);
    meandat = mean(datSeg,2);
    datSeg=datSeg-repmat(meandat,1,win);
    % fit a sine and cosine to each channel in the data and subtract them
    
                  % complex sin and cos
    % ampl = 2*dat*tmp'/Nsamples;                  % estimated amplitude of complex sin and cos
    ampl = 2*datSeg/tmp;                % estimated amplitude of complex sin and cos on integer number of cycles
    est(:,sel)  = ampl*tmp;                               % estimated signal at this frequency
    filt(:,sel) = dat(:,sel) - est(:,sel);                              % subtract estimated signal
    filt(:,sel) = real(filt(:,sel));
    filt(:,sel) = filt(:,sel)-repmat(mean(filt(:,sel),2),1,win)+repmat(meandat,1,win);
    tfr(:,sel)=repmat(abs(ampl),1,length(sel));
end


% sel=1:n05;
% 
% 
% % temporarily remove mean to avoid leakage
% meandat = mean(dat(:,sel),2);
% for i=1:nsamples
%     % demean the data
%     dat(:,i) = dat(:,i) - meandat;
% end
% 
% 
% % fit a sine and cosine to each channel in the data and subtract them
% time = (0:nsamples-1)/Fs;
% tmp  = exp(1i*2*pi*Fl*time);                   % complex sin and cos
% % ampl = 2*dat*tmp'/Nsamples;                  % estimated amplitude of complex sin and cos
% ampl = 2*dat(:,sel)/tmp(:,sel);                % estimated amplitude of complex sin and cos on integer number of cycles
% est  = ampl*tmp;                               % estimated signal at this frequency
% filt = dat - est;                              % subtract estimated signal
% filt = real(filt);
% 
% for i=1:nsamples
%     % add the mean back to the filtered data
%     filt(:,i) = filt(:,i) + meandat;
% end
% 
