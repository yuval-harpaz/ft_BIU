function samples=findEegMegSampExp(megTrigOnset,eegEvent,drift)
% here we look for 3 clicks with even spacing on eeg and meg
if ~exist('drift','var')
    drift=2;
end
if ~length(eegEvent)==length(megTrigOnset)
    warning('not the same number of triggers for eeg and meg, working on first ones only')
end
lastTrig=min([length(eegEvent),length(megTrigOnset)]);
dif_eeg_onset=diff(eegEvent(1:lastTrig));
dif_meg_onset=diff(megTrigOnset(1:lastTrig));
counter=1;
samples=[];
% check if 3 conseq triggers are equally spaced for eeg and meg
for difi=1:(length(dif_meg_onset)-1) % the difference between two MEG triggers
    done=false;
    if dif_meg_onset(difi)<5086
        if difi==1 % first time go over all eeg triggers
            for difj=1:(lastTrig-1)
                if abs(dif_meg_onset(difi)-dif_eeg_onset(difj))<drift &&  ~done%&& abs(dif_meg_onset(difi+1)-dif_eeg_onset(difj+1))<2
                    if abs(dif_meg_onset(difi+1)-dif_eeg_onset(difj+1))<drift
                        samples(counter,2)=megTrigOnset(difi);
                        samples(counter,4)=eegEvent(difj);
                        samples(counter,1)=difi; % meg trig index
                        samples(counter,3)=difj; % eeg trig index
                        counter=counter+1;
                        done=true;
                        indDif = difj-difi; % second time and on look for fixed index differences
                    end
                end
            end
        else
            if ~exist('indDif','var')
                dif_meg_onset
                dif_eeg_onset
                display('couldnt find any match, see onset difs above')
                error('change drift or check whether this is the right EEG file')
            end
            difj=difi+indDif;
            if abs(dif_meg_onset(difi)-dif_eeg_onset(difj))<drift &&  ~done
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