function tfr = dftfr(dat, Fs)
% see dft and dftloop05
% 
%   dat        data matrix (Nchans X Ntime)
%   Fs    sampling frequency in Hz
%   tfr   is Nchans X Ntimes X Nfreq, same units as the data
%   the shift is for overlap, later I take the window with maximum amplitud
tfr=zeros([size(dat),100]);
tfrshift=tfr;
for freq=1:100
    shift=floor(Fs/freq/2/2);
    try
        [~,~,tfr(:,:,freq)] = dftloop05(dat,Fs, freq);
    catch
        tfr(:,:,freq)=0;
    end
    try
        [~,~,tfrshift(:,shift:end,freq)] = dftloop05(dat(:,shift:end),Fs, freq);
    catch
        tfrshift(:,shift:end,freq)=0;
    end
end
tfr=max(tfr,tfrshift);
