function [events,values]=trigOnset(trig)
if ~exist('trig','var')
    trig=readTrig_BIU(source);
end
trig=clearTrig(trig,[256,512,1024,2048]);
close;
trigShift=zeros(size(trig));
trigShift(2:end)=trig(1:end-1);
events=find((trig-trigShift)>0);
values=trig(events);