function [trl, event] = BIUtrialfun(cfg);

% needed
% cfg.dataset : file name
% cfg.trialdef.eventvalue : array of event codes;
% optional 
% cfg.trialdef.visualtrig : 'visafter' when the visual trigger comes after the
% E prime trigger,'visbefore' or 'no' (default = no).
% cfg.trialdef.visualtrigwin : in ms (default =0.1) : time-window to look for event after/before visual trigger
% cfg.trialdef.rspwin : in ms (default = 1)  : time window for response (from beginnig of trial)

fprintf('reading header...\n');
hdr = ft_read_header(cfg.dataset);
fprintf('reading events from file...\n');
event= ft_read_event(cfg.dataset);
nev=[];
trl = [];

if ~isfield(cfg.trialdef,'visualtrig') | (isfield(cfg.trialdef, 'visualtrig') && strcmp(cfg.trialdef.visualtrig, 'no'))
% NO VISUAL TRIGGER
   for i=1:length(event)
    if strcmp(event(i).type, 'TRIGGER')
      trval=event(i).value;
        if ismember(trval,cfg.trialdef.eventvalue); 
            begsample= event(i).sample - cfg.trialdef.prestim*hdr.Fs;
            endsample= event(i).sample + cfg.trialdef.poststim*hdr.Fs -1;
            offset = cfg.trialdef.offset*hdr.Fs;
            if isfield(cfg.trialdef,'version');
                if (strcmp(cfg.trialdef.version, 'r') || strcmp(cfg.trialdef.version, 'm'));
                    trl(end+1,:) = round ([begsample endsample offset trval 0 0 0]);
                end;
            else                
                trl(end+1,:) = round ([begsample endsample offset trval 0 0]);
            end;
            %trl(end+1,:) = round ([begsample endsample offset trval 0 0 0]);
            nev=[nev event(i)];
        end %ismem
    end %strcmp
  end %for
else
% VISUAL TRIGGER
 if strcmp(cfg.trialdef.visualtrig, 'visbefore'), modif=-1; else modif=1; end;
 if ~isfield(cfg.trialdef,'visualtrigwin'), cfg.trialdef.visualtrigwin=0.1; end; 
   for i=1:length(event)
    if strcmp(event(i).type, 'TRIGGER')
      trval=event(i).value;
       if bitand(trval,2048) % ==2048 && bitand(event(i-1).value)~=2048
          j=1;          
          if modif==1, jlimit=i-1;  else  jlimit=length(events)-i; end;
          while (j<jlimit) & ((abs(event(i).sample-event(i-j*modif).sample)/hdr.Fs)<=cfg.trialdef.visualtrigwin)
           if strcmp(event(i-j).type, 'TRIGGER') & ismember(event(i-j*modif).value,cfg.trialdef.eventvalue) 
            begsample= event(i).sample - cfg.trialdef.prestim*hdr.Fs;
            endsample= event(i).sample + cfg.trialdef.poststim*hdr.Fs -1;
            offset = cfg.trialdef.offset*hdr.Fs;
            %item = event(i-1).value;
            %if bitand(4096,item)==4096, item=bitset(item,13,0)+1; end;
            trl(end+1,:) = round ([begsample endsample offset event(i-j*modif).value 0 0]);
            nev=[nev event(i)];
            j=i;
           end; %ifstrcmpismem 
           j=j+1;
         end; %while
        end; %iftrval  
       end %strcmp
  end %for
end;
if ~isfield(cfg.trialdef,'rspwin'), cfg.trialdef.rspwin=1; end;
respev=[event(find(strcmp({event(:).type},'RESPONSE'))).value]';
respsm=[event(find(strcmp({event(:).type},'RESPONSE'))).sample]';
for i=1:size(trl,1),
trst=trl(i,1); 
 if (trst+cfg.trialdef.rspwin)>find(respsm>trst,1),
    trl(i,5)=respsm(find(respsm>trst,1));
    trl(i,6)=respev(find(respsm>trst,1)); %change to log2 - 2;
 end;
end;
            
            
