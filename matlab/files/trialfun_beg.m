function [trl, event] = trialfun_beg(cfg);
% sets one event with trigger value 1 at the beggining of the data
% may be usefull for reading the whole data as one epoch or short data for
% head model requirements. yuval, Nov 2010
%
% needed
% cfg.dataset : file name
% cfg.trialdef.poststim : length of epoch, default - whole length.

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
    if isfield (cfg.trialdef,'poststim')
        trl(1,2)=round(cfg.trialdef.poststim*hdr.Fs);
    end
end
