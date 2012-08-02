function samp=findEegMegSamp(megTrigOnset,eegEvent)
dif_evt=diff(eegEvent);
dif_onset=diff(megTrigOnset);
counter=1;
for difi=1:length(dif_onset)
    done=false;
    if dif_onset(difi)<2034
        for difj=1:length(dif_evt)
            if abs(dif_onset(difi)-dif_evt(difj))<3 && abs(dif_onset(difi)-dif_evt(difj))<3 && ~done
                samp(counter,1)=megTrigOnset(difi);
                samp(counter,2)=eegEvent(difj);
                counter=counter+1;
                done=true;
            end
        end
    end
end