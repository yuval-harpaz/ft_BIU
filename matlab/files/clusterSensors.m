function [mostActive,neighb]=clusterSensors(data,time,thr,distance,minN)
% data - fieldtrip average structure
% time - at what time point to look for clusters 0.1
% thr - threshold for clustering in Tesla 5e-13 or percents '25%'
% distance - how far from an active channel to look for neighbours
% minN - if there are less than minN close active channels (less than 3cm)
% disregard them (ignore lonely active channels)
samp=nearest(data.time,time);
M=data.avg(:,samp);
if ischar(thr)
   if strcmp(thr(end),'%')
       thr=prctile(abs(M),str2num(thr(1:end-1)));
   else
       error('what threshold?')
   end
end
% find high amplitude channels
mostActive=abs(M)>thr;
[~,gradi]=ismember(data.label,data.grad.label);
pos=data.grad.chanpos(gradi,:);
chi=find(mostActive)';
% remove channels with no neighbours
for i=1:length(chi)
    distances=sqrt(sum((pos(chi,:)-repmat(pos(chi(i),:),length(chi),1)).^2,2));
    chiNei(i)=sum(distances<30);
end

mostActive(chi(chiNei<=minN))=false;
chi=chi(chiNei>minN);
% add neighbouring channels 
neighb=mostActive;
for i=chi
    disp('')
    distances=sqrt(sum((pos-repmat(pos(i,:),length(pos),1)).^2,2));
    neighb(distances<distance)=true;
end
disp(['chose ',num2str(sum(mostActive)),' of ',num2str(length(pos))])

