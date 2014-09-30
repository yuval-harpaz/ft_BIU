function fig1=topoplot30(vec,cfg)
%% reading weights
% topoplot of 30 EEG values (no M1 and M2)
if ~exist ('cfg','var')
    cfg=[];
end
cfg.layout='WG30.lay';
load ~/ft_BIU/matlab/ploteeg
eeg.label=eeg.label([1:12,14:18,20:32],1); %#ok<NODEF>
if size(vec,1)==1;
    eeg.avg=vec';
else
    eeg.avg=vec;
end

fig1=ft_topoplotER(cfg,eeg);
