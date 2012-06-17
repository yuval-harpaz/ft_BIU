function newData=clustData(cfg,origData)
% a new data is created where every channel is replaced with the data of
% itself and its neighbours. the sumation method can be RMS, or mean.
% neighbours can be the output of ft_prepare_neighbours or 'all' or 'LR';
% cfg=[];
% cfg.neighbours=neighbours;
% cfg.method='RMS';
doRMS=false;doMean=false;doAll=false;doLR=false;
if ~isfield(cfg,'method')
    cfg.method='';
end
if strcmp(cfg.method,'RMS')
    doRMS=true;
elseif strcmp(cfg.method,'mean')
    doMean=true;
else
    error('cfg.method can be RMS or, no or just RMS.')
end
if ischar(cfg.neighbours)
    if strcmp(cfg.neighbours,'all')
        doAll=true;
        if doMean
            error('mean method should not be used with cfg.neighbours=all')
        end
        cfg.neighbours=struct;
        if ~ismember('A1',origData.label)
            error('FIXME, doesnt work if A1 is missing')
        end
        cfg.neighbours(1,1).label='A1';
        li=0;
        for labeli=1:247;
            if ismember(['A',num2str(labeli+1)],origData.label)
                li=li+1;
                cfg.neighbours(1,1).neighblabel{li,1}=['A',num2str(labeli+1)];
            end
        end
    elseif strcmp(cfg.neighbours,'LR')
        doLR=true;
        load ~/ft_BIU/matlab/files/LRpairs;
        cfg.neighbours=struct;
        cfg.neighbours(1,1).label='A6';
        cfg.neighbours(1,1).neighblabel(1:114,1)=LRpairs(2:115,1);
        cfg.neighbours(1,2).label='A18';
        cfg.neighbours(1,2).neighblabel(1:114,1)=LRpairs(2:115,2);
    end
end          
newData=origData;
if isfield(origData,'individual')
    dataType='grdAvg';
elseif isfield(origData,'avg')
    dataType='avg';
elseif isfield(origData,'trial')
    dataType='raw';
end
if strcmp(dataType,'grdAvg')
    for chani=1:length(cfg.neighbours)
        [~,ni]=ismember(cfg.neighbours(1,chani).neighblabel,origData.label);
        [~,chi]=ismember(cfg.neighbours(1,chani).label,origData.label);
        clusti=[chi ni'];
        if doRMS
            newData.individual(:,chi,:)=...
                squeeze(sqrt(mean(origData.individual(:,clusti,:).^2,2)));
        elseif doMean
            newData.individual(:,chi,:)=...
                squeeze(mean(origData.individual(:,clusti,:),2));
        end
    end
else
    error([dataType,' data type not supported yet, just grand average']);
end
if doAll
    newData.label={};
    newData.label{1,1}='all';
    newData.individual=newData.individual(:,chi,:);
elseif doLR
    newData.label={};
    newData.label={'L';'R'};
    [~,chiL]=ismember('A6',origData.label);
    [~,chiR]=ismember('A18',origData.label);
    chiLR=[chiL,chiR];
    newData.individual=newData.individual(:,chiLR,:);
end
newData.method=cfg.method;
end

    