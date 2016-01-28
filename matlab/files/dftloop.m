function [filt,est] = dftloop(dat, Fs, Fl,win)
% see dft
% where
%   dat        data matrix (Nchans X Ntime)
%   Fsample    sampling frequency in Hz
%   Fline      line noise frequency
%   win        size of window to epoch the data in samples. default = Fs.
%
% GNU General Public License as published by
%    the Free Software Foundation, either version 3 of the License, or
%    (at your option) any later version.

if ~exist ('win','var')
    win=Fs;
end
%if win<
% determine the size of the data
[nchans, nsamples] = size(dat);
if nsamples==1 && nchans>1
    dat=dat';
    [nchans, nsamples] = size(dat);
end
% set the default filter frequency
if nargin<3 || isempty(Fl)
    Fl = 50;
end

% ensure to be a column  vector
Fl = Fl(:);

% determine the largest integer number of line-noise cycles that fits in the data
n   = round(floor(nsamples .* Fl./Fs) * Fs./Fl);
if all(n~=n(1)),
    error('when multiple frequencies are in the input, the oscillations should all fit an integer number of cycles in the data provided');
end
if n == 0
    error('better include a whole cycle (100ms for 10Hz estimate) or more')
end
time = (0:win-1)/Fs;
for segmenti=1:floor(n/win)
    sel=(segmenti*win-win+1):segmenti*win;
    % temporarily remove mean to avoid leakage
    datSeg=dat(:,sel);
    meandat = mean(datSeg,2);
    datSeg=datSeg-repmat(meandat,1,win);
    % fit a sine and cosine to each channel in the data and subtract them
    
    tmp  = exp(1i*2*pi*Fl*time);                   % complex sin and cos
    % ampl = 2*dat*tmp'/Nsamples;                  % estimated amplitude of complex sin and cos
    ampl = 2*datSeg/tmp;                % estimated amplitude of complex sin and cos on integer number of cycles
    est(:,sel)  = ampl*tmp;                               % estimated signal at this frequency
    filt(:,sel) = dat(:,sel) - est(:,sel);                              % subtract estimated signal
    filt(:,sel) = real(filt(:,sel));
    filt(:,sel) = filt(:,sel)+repmat(meandat,1,win);
end

