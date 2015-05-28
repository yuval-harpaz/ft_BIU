function srci=chooseNearSrc(data,pnt,chans,dist)
% data is average ft structure
% pnt is the xyz (N by 3)of all sources
% chans is index or logical of the channel or channels of interest
% dist is how far into the head you want sources to be included
if islogical(chans)
    chans=find(chans)
end
% find high amplitude channels
%mostActive=abs(M)>thr;

pos=data.grad.chanpos(chans,:);

srci=false(size(pnt,1),1);
for i=1:length(chans)
    distances=sqrt(sum((pnt-repmat(pos(i,:),size(pnt,1),1)).^2,2));
    srci(distances<dist)=true;
end
sum(srci)

disp(['chose ',num2str(sum(srci)),' of ',num2str(length(pnt))])

