function [newtrig,events]=fixAudTrig(trig,Aud,alltrigs,thr,sampForw)
% replacing auditory signal X3) with onsets or offsets
% changes values according to previous triger (sent by eprime)
% requires:
%
% trig (output of readTrig_BIU)
%
%
% alltrigs: in order to mark all trials (to run ICA on all conditions for example)
% 10 samples before every visual trigger the specified value (alltrigs) is
% added to newtrig.
%
% thr: threshold for auditory signal detection. 0.05 is the default.
%
% sampForw: how many samples after the trigger to look for the auditory
% signal
%
% event list is created with columns for trigger onset, trigger value and
% trigger offset.
% 
% for standart visual experiments run as
% [newtrig,events]=fixVAudTrig(trig,X3,1);
%%
if ~exist('thr','var')
    thr=[];
end
if isempty(thr)
    thr=0.05;
end
if ~exist('sampForw','var')
    sampForw=[];
end
if isempty(sampForw)
    sampForw=300;
end

warning('50Hz cleaning with cleanMEG pack will not be possible using the new trigger'); %#ok<WNTAG>
trig16=uint16(trig);
trigf=bitset(trig16,9,0); %getting rid of trigger 256 (9)
trigf=bitset(trigf,10,0);  %getting rid of trigger 512 (9)
endtrg=size(trigf,2);
trg(1,2:endtrg)=trigf(1,2:endtrg)-trigf(1,1:(endtrg-1));%finding onsets of trigf
trigonsets=find(trg>0);

% vis=bitand(trigf,2048);   % reading the visual information
% trigf=bitset(trigf,12,0);   %getting rid of trigger 2048 (12)
% visonset=vis(1,:);visonset(1,1)=0;visonset(1,2:end)=visonset(1,2:end)-visonset(1,1:(end-1));
% visoffset=vis(1,:);visoffset(1,end)=0;visoffset(1,1:(end-1))=visoffset(1,1:(end-1))-visoffset(1,2:end);
% visonset=visonset==2048;visoffset=visoffset==2048;
% onsets=find(visonset);offsets=find(visoffset);
newtrig=zeros(size(trigf));
events=[];
for i=1:size(trigonsets,2)
    ionset=trigonsets(1,i);
    [~,v]=find(abs(Aud(ionset:(ionset+sampForw)))>thr,1);
    tvalue=trigf(ionset);
    %if tvalue>0;
    %         ioffset=find(offsets>ionset,1);
    %         if strcmp(onORoffset,'onset');
    newtrig(1,ionset+v)=tvalue;
    %         elseif strcmp(onORoffset,'offset');
    %             newtrig(1,offsets(ioffset))=tvalue;
    %         end
    events(i,1)=ionset; %#ok<AGROW>
    events(i,2)=tvalue; %#ok<AGROW>
    %events(i,3)=offsets(ioffset); %#ok<AGROW>
    tvalue=0; %#ok<NASGU>
    %end
end
if exist('alltrigs','var')
    if ~isempty(alltrigs)
        trigs=find(newtrig>0);
        newtrig(1,trigs-10)=alltrigs;
    end
end
figure;%plot(trig);
hold on;plot(newtrig,'r');plot(100*Aud,'k');
end