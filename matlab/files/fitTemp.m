function [SNR,SigX,sigSign]=fitTemp(x,tmplt,time0,dtr)
% x is a vector containing the data
% tmplt is a baseline corrected normalized template
% time0 is the sample where the activity peaks (a min or max point of the
% template)
% SigX is the signal, SNR is SigX./err, sigSign is a vector of ones and -ones
% to keep information about the fit, one when the multiplication of
% template by data was positive (temp and data both had a maximum or a
% minimum)
% if dtr=1 or true the data segments are detrended before the fit.
if ~exist('dtr','var')
    dtr=false;
end
time1=length(tmplt)-time0;
SigX = nan(1,length(x));
TotX = SigX;SNR=SigX;sigSign=SigX;
for ii = time0:(length(x)-time1);
    y = x((ii-time0+1):ii+time1);
    if dtr
        y=detrend(y);  %detrend, has blc in it too;
    else
        y = y-mean(y); % baseline correction
    end
    TotX(ii) = sum(y.*y);
    proj = sum(y.*tmplt);
    sigSign(ii)=proj/abs(proj);
    SigX(ii) = proj*proj;
    err = TotX(ii)-SigX(ii);
    SNR(ii) = SigX(ii)/err;
    %         if ~isempty(find([(time0+10):20:(length(x)-time1-10)]==ii,1))
    %             figure;plot(y.*10^13);
    %             hold on;plot(tmplt,'k');
    %             %ylim(0.6*[-10^-12 10^-12])
    %             close
    %         end
    
end
end