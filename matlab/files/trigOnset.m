function events=trigOnset(trig)
if ~exist('trig','var')
    trig=readTrig_BIU(source);
end
trig=clearTrig(trig);
close;
trigShift=zeros(size(trig));
trigShift(2:end)=trig(1:end-1);
events=find((trig-trigShift)>0);