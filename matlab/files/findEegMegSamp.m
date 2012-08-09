function samples=findEegMegSamp(megTrigOnset,eegEvent)
dif_evt=diff(eegEvent);
dif_onset=diff(megTrigOnset);
counter=1;
for difi=1:length(dif_onset)
    done=false;
    if dif_onset(difi)<2034
        for difj=1:length(dif_evt)
            if abs(dif_onset(difi)-dif_evt(difj))<3 && abs(dif_onset(difi)-dif_evt(difj))<3 && ~done
                samples(counter,2)=megTrigOnset(difi);
                samples(counter,4)=eegEvent(difj);
                samples(counter,1)=difi; % meg trig index
                samples(counter,3)=difj; % eeg trig index
                counter=counter+1;
                done=true;
            end
        end
    end
end

display('          megi       MEG          eegi      EEG')
samples
end