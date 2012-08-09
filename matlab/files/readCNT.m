function [data,header,events]=readCNT(cfg)
% you can run just readCNT if there is one cnt file in the path
% give it cfg.dataset to specify fileName
% other cfg fields can be added for preprocessing (trl, filter etc)
if exist('cfg','var')
    if ~isfield(cfg,'dataset')
        LS=ls('*.cnt');
        fileName=LS(1:(strfind(LS,'cnt')+2))
        if size(LS,1)>1
            error('no cfg.dataset and more than 1 .cnt file in folder')
        else
            cfg.dataset=fileName;
        end
    end
else
    LS=ls('*.cnt');
    fileName=LS(1:(strfind(LS,'cnt')+2))
    if size(LS,1)>1
        error('no cfg.dataset and more than 1 .cnt file in folder')
    else
        cfg.dataset=fileName;
    end
end
header=ft_read_header(cfg.dataset);
if ~isfield(cfg,'trl')
    cfg.trl=[1,header.nsample,0];
end
data=ft_preprocessing(cfg);
try
    events=readTrg;
catch %#ok<CTCH>
    events=[];
end
end