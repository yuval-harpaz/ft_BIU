function peaks=peaksInTrials1freq(data,wlt);
% requires the output of freqanalysis_triang_temp


peaks.label=data.label;
peaks.wlt=wlt;
th=1;
t=data.time;
deadT=30;
for chani=1:length(data.label)
    display(['channel index ',num2str(chani),' of ',num2str(length(data.label)),' ',data.label{chani}]);
    for triali=1:size(data.powspctrm,1)
        %         firstSamp=true;
        %         lastSamp=false;
        ispeak=false;
        %pkCount=0;
        peaks.chan{1,chani}.trial{1,triali}.time=[];
        peaks.chan{1,chani}.trial{1,triali}.SNR=[];
        peaks.chan{1,chani}.trial{1,triali}.wlti=1;
        SNR=squeeze(data.powspctrm(triali,chani,1,:));
        try
            [SigPeaks, SigIpeaks] = findPeaks(abs(SNR),th, deadT, 'MAD');
            if ~isempty(SigIpeaks)
                peaks.chan{1,chani}.trial{1,triali}.time=t(SigIpeaks);
                peaks.chan{1,chani}.trial{1,triali}.SNR=SNR(SigIpeaks);
                %peaks.chan{1,chani}.trial{1,triali}.wlti=[peaks.chan{1,chani}.trial{1,triali}.wlti,maxi];
            end
        end
        if isempty(peaks.chan{1,chani}.trial{1,triali}.time)
            display(['nothoing for trial ',num2str(triali)]);
        end
    end
end