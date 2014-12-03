function fig1=topoplot102(vec,cfg)
%% reading weights
% topoplot of 102 elekta values
if ~exist ('cfg','var')
    cfg=[];
end
load ~/ft_BIU/matlab/plotNeuromag
plotNeuromag.avg(:,1)=vec;
cfg.layout='neuromag306mag.lay';
fig1=ft_topoplotER(cfg,plotNeuromag);
