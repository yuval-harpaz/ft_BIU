function [filt,est] = dft05(dat, Fs, Fl)
% based on the ft function as described below, just wanted to get more OP
% options, Yuval
% designed to allow processing also when you only have

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
Fl = Fl(:);

% determine the largest integer number of line-noise cycles that fits in the data
n   = round(floor(nsamples .* Fl./Fs) * Fs./Fl);
if all(n==n(1)),
    sel = 1:n;
else
    error('when multiple frequencies are in the input, the oscillations should all fit an integer number of cycles in the data provided');
end
if n == 0
    
    n05   =ceil(Fs./Fl/2);
    if nsamples<n05
        error('you must have half a cycle for good baseline correction (e.g. 50ms for 10Hz estimate)')
    end
    %meandat = mean(dat(:,1:n05),2);
    sel=1:n05;
end

% temporarily remove mean to avoid leakage
meandat = mean(dat(:,sel),2);
for i=1:nsamples
    % demean the data
    dat(:,i) = dat(:,i) - meandat;
end


% fit a sine and cosine to each channel in the data and subtract them
time = (0:nsamples-1)/Fs;
tmp  = exp(1i*2*pi*Fl*time);                   % complex sin and cos
% ampl = 2*dat*tmp'/Nsamples;                  % estimated amplitude of complex sin and cos
ampl = 2*dat(:,sel)/tmp(:,sel);                % estimated amplitude of complex sin and cos on integer number of cycles
est  = ampl*tmp;                               % estimated signal at this frequency
filt = dat - est;                              % subtract estimated signal
filt = real(filt);

for i=1:nsamples
    % add the mean back to the filtered data
    filt(:,i) = filt(:,i) + meandat;
end

