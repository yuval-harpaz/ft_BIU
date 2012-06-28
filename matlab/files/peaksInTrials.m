function peaks=peaksInTrials(data,wlt);
% requires the output of freqanalysis_triang_temp


peaks.label=data.label;
peaks.wlt=wlt;
th=1;
t=data.time;
for chani=1:length(data.label)
    for triali=1:size(data.powspctrm,1)
        firstSamp=true;
        lastSamp=false;
        ispeak=false;
        %pkCount=0;
        peaks.chan{1,chani}.trial{1,triali}.time=[];
        peaks.chan{1,chani}.trial{1,triali}.SNR=[];
        peaks.chan{1,chani}.trial{1,triali}.wlti=[];
        for sampi=1:length(t)
            gtn=[];gtp=[];
            yNow=squeeze(data.powspctrm(triali,chani,:,sampi));
            if ~(sampi==length(t))
                yNext=squeeze(data.powspctrm(triali,chani,:,sampi+1));
            else
                lastSamp=true;
            end
            freqi=find(~isnan(yNow)); %there are numbers at this latency
            if ~isempty(freqi)
                nums=yNow(freqi);
                [maxv,maxi]=max(abs(nums));
                maxv=nums(maxi);
                maxi=freqi(maxi);
                if abs(maxv)>th;
                    if ~lastSamp
                        gtn=sum(abs(maxv)<abs(yNext))==0; % 1 if greater than next
                    end
                    if ~firstSamp
                        yPrev=squeeze(data.powspctrm(triali,chani,:,sampi-1));
                        gtp=sum(abs(maxv)<abs(yPrev))==0; % 1 if greater than prev
                    else
                        firstSamp=false;
                    end
                    if isempty(gtp) %first sample with data
                        if gtn
                            ispeak=true;
                        else
                            ispeak=false;
                        end
                    elseif isempty(gtn) % last sample
                        if gtp
                            ispeak=true;
                        else
                            ispeak=false;
                        end
                    else
                        if gtp && gtn
                            ispeak=true;
                        else
                            ispeak=false;
                        end
                    end
                    if ispeak
                        %pkCount=pkCount+1;
                        peaks.chan{1,chani}.trial{1,triali}.time=[peaks.chan{1,chani}.trial{1,triali}.time,t(sampi)];
                        peaks.chan{1,chani}.trial{1,triali}.SNR=[peaks.chan{1,chani}.trial{1,triali}.SNR,maxv];
                        peaks.chan{1,chani}.trial{1,triali}.wlti=[peaks.chan{1,chani}.trial{1,triali}.wlti,maxi]; %wavelet index
                    end
                end
            end
        end
        if isempty(peaks.chan{1,chani}.trial{1,triali}.time)
            display(['nothoing for trial ',num2str(triali)]);
        else
            display(['trial ',num2str(triali)]);
        end
    end
end