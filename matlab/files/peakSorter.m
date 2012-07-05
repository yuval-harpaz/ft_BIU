function pksByTrial=peakSorter(chan,peaks,timewindows,trialinfo,posNeg,method,noWlts) %#ok<STOUT>
try
    if strcmp('noWlts',noWlts)
        doWlts=false;
    else
        doWlts=true;
    end
catch
    doWlts=true;
end
[~,chani]=ismember(chan,peaks.label);
conds=unique(trialinfo);
for condi=1:length(conds)
    tri=find(trialinfo==conds(condi));
    pkinfo=[];
    for timewini=1:size(timewindows,1)
        pkTrCount=0;
        for triali=tri'
            if strcmp(posNeg,'pos')
                pki=find(peaks.chan{1,chani}.trial{1,triali}.SNR>0);
            elseif strcmp(posNeg,'neg')
                pki=find(peaks.chan{1,chani}.trial{1,triali}.SNR<0);
            elseif strcmp(posNeg,'both')
                pki=find(peaks.chan{1,chani}.trial{1,triali}.SNR);
            end
            pkLow=peaks.chan{1,chani}.trial{1,triali}.time(pki)>timewindows(timewini,1);
            pkHigh=peaks.chan{1,chani}.trial{1,triali}.time(pki)<timewindows(timewini,2);
            pkLH=find(pkLow+pkHigh==2); % which peak is within the timewindow
            if length(pkLH)==1
                pkt=peaks.chan{1,chani}.trial{1,triali}.time(pki(pkLH));
                pkSNR=peaks.chan{1,chani}.trial{1,triali}.SNR(pki(pkLH));
                if doWlts
                    pkw=peaks.chan{1,chani}.trial{1,triali}.wlti(pki(pkLH));
                else
                    pkw=1;
                end
                pkTrCount=pkTrCount+1;
                pkinfo.timewin{1,timewini}(pkTrCount,1:4)=[triali,pkt,pkSNR,pkw];
            elseif length(pkLH)>1
                if strcmp(method,'biggest')
                    [pkSNR,pi]=max(abs(peaks.chan{1,chani}.trial{1,triali}.SNR(pki(pkLH))));
                    pkt=peaks.chan{1,chani}.trial{1,triali}.time(pki(pkLH(pi)));
                    if doWlts
                        pkw=peaks.chan{1,chani}.trial{1,triali}.wlti(pki(pkLH(pi)));
                    else
                        pkw=1;
                    end
                    pkTrCount=pkTrCount+1;
                    pkinfo.timewin{1,timewini}(pkTrCount,1:4)=[triali,pkt,pkSNR,pkw];
                elseif strcmp(method,'earliest')
                    pkt=peaks.chan{1,chani}.trial{1,triali}.time(pki(pkLH(1)));
                    pkSNR=peaks.chan{1,chani}.trial{1,triali}.SNR(pki(pkLH(1)));
                    if doWlts
                    pkw=peaks.chan{1,chani}.trial{1,triali}.wlti(pki(pkLH(1)));
                    else
                        pkw=1;
                    end
                    pkTrCount=pkTrCount+1;
                    pkinfo.timewin{1,timewini}(pkTrCount,1:4)=[triali,pkt,pkSNR,pkw];
                else
                    error('choose method for choosing peak, biggest or earliest')
                end
            end
        end
    end
    eval(['pksByTrial.cond',num2str(conds(condi)),posNeg,'=pkinfo;']);
    %save(['cond',num2str(conds(condi)),posNeg],['cond',num2str(conds(condi)),posNeg]);
end