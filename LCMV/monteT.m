function [cfg1,probplot,cfg2,statplot]=monteT(compt,condA,condB,lowlim)


% run as: [cfg1,probplot,cfg2,statplot]=monteT('750','s1p','s2p');
% click on interactive map to explore. press q to quit.
% first map is p values. second map is t values.
% later plot images by: ft_sourceplot(cfg1,probplot) and ft_sourceplot(cfg2,statplot)

% condA='s1p'; %  n for nai, p for pow, e for epochs, m for mean.

cfg1=[];probplot=[];cfg2=[];statplot=[];
%condA='s4p'; % nn for new nai, n for nai, p for pow, e for epochs, m for mean.
%condB='s3p';


eval(['load ',condA, compt])
eval(['load ',condB,  compt])
cfg=[];
eval(['cfg.dim = ',condA,'.dim;']);
cfg.method      = 'montecarlo';
cfg.statistic   = 'depsamplesT';
%cfg.statistic = 'ttest';
%cfg.method      = 'stats';
%cfg.statistic   = 'paired-ttest';
cfg.parameter   = 'nai';
if condA(1,end)=='p'
    cfg.parameter   = 'pow';
end
cfg.correctm    = 'no'; %  'no', 'max', 'cluster', 'bonferoni', 'holms', 'fdr'
cfg.numrandomization = 1000;
cfg.alpha       = 0.05; % 0.05
cfg.tail        = 0;


eval(['nsubj=length(',condA,'.trial)']);
cfg.design(1,:) = [1:nsubj 1:nsubj];
cfg.design(2,:) = [ones(1,nsubj) ones(1,nsubj)*2];
%cfg.design(1,:) = [ones(1,nsubj) ones(1,nsubj)*2];
cfg.uvar        = 1; % row of design matrix that contains unit variable (in this case: subjects)
cfg.ivar        = 2; % row of design matrix that contains independent variable (the conditions)

eval(['stat = sourcestatistics(cfg, ',condA,',',condB,');']);
load ~/ft_BIU/LCMV/pos
stat.pos=pos;
clear(condA,condB)
cfg = [];
cfg.parameter = 'prob'; %'all' 'prob' 'stat' 'mask'
% cfg.downsample = 2;
load ~/ft_BIU/LCMV/sMRI
%read_mri('/home/meg/Documents/MATLAB/spm8/canonical/single_subj_T1.nii');
probplot = sourceinterpolate(cfg, stat,sMRI)
probplot.prob1=1-probplot.prob;
if ~exist('lowlim','var')
    lowlim=0.95;
elseif isempty(lowlim)
    lowlim=0.95;
end

if ~exist('aal_MNI_V4.img','file')==2
    copyfile ~/ft_BIU/ft_files/aal_MNI_V4.img
    copyfile ~/ft_BIU/ft_files/aal_MNI_V4.hdr
end
if max(max(max(probplot.prob1>=lowlim)))==1;
    probplot.mask=(probplot.prob1>=lowlim);
    cfg1 = [];
    cfg1.funcolorlim = [lowlim 1];
    cfg1.interactive = 'yes';
    cfg1.funparameter = 'prob1';
    cfg1.maskparameter= 'mask';
    cfg1.method='ortho';
    cfg1.inputcoord='mni';
    cfg1.atlas='aal_MNI_V4.img';
    %cfg1.roi='Frontal_Sup_L'
    %cfg1.location=[-42 -58 -11];% wer= -50 -45 10 , broca= -50 25 0, fussiform = -42 -58 -11(cohen et al 2000), change x to positive for RH.
    %cfg1.crosshair='no';
    figure
    ft_sourceplot(cfg1,probplot)
    %figure; YHsourceplot(cfg1,probplot); % requires roi
    cfg.parameter = 'stat';
    statplot = sourceinterpolate(cfg, stat,sMRI)
    cfg2=rmfield(cfg1,'funcolorlim');
    cfg2.funcolorlim = [-3.5 3.5];
    cfg2.funparameter = 'stat';
    cfg2.method='ortho';
    cfg2.inputcoord='mni';
    cfg2.atlas='aal_MNI_V4.img';
    figure
    ft_sourceplot(cfg2,statplot)
else warning('no significant results')
    display('change lower p value limit to explore map by running: lowlim=0.9;')
    display(['[cfg1,probplot,cfg2,statplot]=monteT(''',compt,''',','''',condA,''',','''',condB,''',lowlim);'])
end
end
