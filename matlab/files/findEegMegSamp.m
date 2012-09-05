function samples=findEegMegSamp(megTrigOnset,eegEvent)
% here we look for 3 clicks with even spacing on eeg and meg

dif_eeg_onset=diff(eegEvent);
dif_meg_onset=diff(megTrigOnset);
counter=1;
samples=[];
% check if 3 conseq triggers are equally spaced for eeg and meg
for difi=1:(length(dif_meg_onset)-1)
    done=false;
    if dif_meg_onset(difi)<2034
        for difj=1:(length(dif_eeg_onset)-1)
            if abs(dif_meg_onset(difi)-dif_eeg_onset(difj))<2 && ~done % && abs(dif_meg_onset(difi+1)-dif_eeg_onset(difj+1))<2
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