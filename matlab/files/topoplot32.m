function fig1=topoplot32(vec,cfg)
%% reading weights
% topoplot of 248 values
if ~exist ('cfg','var')
    cfg=[];
end
cfg.layout='WG32.lay';
load ~/ft_BIU/matlab/ploteeg
eeg=rmfield(eeg,'cfg')
eeg.avg(:,1)=vec;
fig1=ft_topoplotER(cfg,eeg);
