function topoplot248(vec,cfg,sortedChans);
%% reading weights
% topoplot of 248 values
load ~/ft_BIU/matlab/plotwts
if sortedChans
    for chani=1:248
        wts.label{chani,1}=['A',num2str(chani)];
    end
end
if ~exist ('cfg','var')
    cfg=[];
end
wts.avg(:,1)=vec;
figure;ft_topoplotER(cfg,wts);
