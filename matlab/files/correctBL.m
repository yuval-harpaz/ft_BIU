function dataBL=correctBL(data,blcwindow)
% dataBL=correctBL(dataica,[-0.2 0]);
dataBL=data;
if ~isfield(dataBL,'avg')
    firstSamp=nearest(dataBL.time{1,1},blcwindow(1));
    lastSamp=nearest(dataBL.time{1,1},blcwindow(2));
    trialLength=size(dataBL.trial{1,1},2);
    for trial=1:size(dataBL.trial,2)
        m=mean(dataBL.trial{1,trial}(:,firstSamp:lastSamp),2);
        for i=1:size(m,1); m(i,2:trialLength)=m(i,1);end
        dataBL.trial{1,trial}=dataBL.trial{1,trial}-m;
    end
else
    firstSamp=nearest(dataBL.time,blcwindow(1));
    lastSamp=nearest(dataBL.time,blcwindow(2));
    trialLength=size(dataBL.avg,2);
    m=mean(dataBL.avg(:,firstSamp:lastSamp),2);
    for i=1:size(m,1); m(i,2:trialLength)=m(i,1);end
    dataBL.avg=dataBL.avg-m;
end
end