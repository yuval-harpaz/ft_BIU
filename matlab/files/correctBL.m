function data=correctBL(data,blcwindow)
% dataBL=correctBL(dataica,[-0.2 0]);
% correctBL can make baseline correction for fieldtrip structures -
% averaged data, data with trials or timelockgrandaverage output.
% now it also works for 2D data matrices. For them, give blcwindow in samples.
if isnumeric(data)
    for chani=1:size(data,1)
        data(chani,1:end)=data(chani,1:end)-mean(data(chani,blcwindow(1):blcwindow(2)));
    end
else
    if isfield(data,'avg')
        dataType='avg';
        time=data.time;
    elseif isfield(data,'individual')
        dataType='Gavg';
        time=data.time;
    elseif isfield(data,'trial')
        dataType='trial';
        time=data.time{1};
    end
    
    trialLength=length(time);
    if ~exist('blcwindow','var')
        firstSamp=1;
        lastSamp=trialLength;
    else
        firstSamp=nearest(time,blcwindow(1));
        lastSamp=nearest(time,blcwindow(2));
    end
    switch dataType
        case 'trials'
            for trial=1:size(data.trial,2)
                m=mean(data.trial{1,trial}(:,firstSamp:lastSamp),2);
                m=repmat(m,1,trialLength);
                data.trial{1,trial}=data.trial{1,trial}-m;
            end
        case 'avg'
            m=mean(data.avg(:,firstSamp:lastSamp),2);
            m=repmat(m,1,trialLength);
            data.avg=data.avg-m;
        case 'Gavg'
            m=mean(data.individual(:,:,firstSamp:lastSamp),3);
            m=repmat(squeeze(m),[1,1,trialLength]);
            data.individual=data.individual-m;
    end
end