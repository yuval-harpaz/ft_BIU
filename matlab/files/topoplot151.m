function fig1=topoplot151(vec,cfg)
%% reading weights
% topoplot of 248 values
if ~exist ('cfg','var')
    cfg=[];
end
load ~/ft_BIU/matlab/plotctf
plotctf.avg(:,1)=vec;
fig1=ft_topoplotER(cfg,plotctf);
