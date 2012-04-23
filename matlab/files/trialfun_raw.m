function [trl, event] = trialfun_raw(cfg);
% sets one event with trigger value 1 at the beggining of the data
% may be usefull for reading the whole data as one epoch or short data for
% head model requirements. yuval, sep 2011
%
% needed
% cfg.dataset : file name
% cfg.trialdef.beginning : beginning time (s, default time 0).
% cfg.trialdef.end : end time (s, default end of run).

fprintf('reading header...\n');
hdr = read_header(cfg.dataset);
%fprintf('reading events from file...\n');
% event= read_event(cfg.dataset);
event{1,1}.type='TRIGGER';
event{1,1}.sample=1;
event{1,1}.value=1;
event{1,1}.offset=[];
event{1,1}.duration=[];
%nev=[];
trl = [1 hdr.nSamples 0];
if isfield (cfg,'trialdef')
    if isfield (cfg.trialdef,'beginning')
        if ~cfg.trialdef.beginning==0
            trl(1,1)=round(cfg.trialdef.beginning*hdr.Fs);
            trl(1,3)=trl(1,1);
        end
    end
    if isfield (cfg.trialdef,'end')
        trl(1,2)=round(cfg.trialdef.end*hdr.Fs);
    end
end
end
