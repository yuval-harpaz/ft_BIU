function [cfg1,probplot,cfg2,statplot]=indepT(compt,condA)


% independent samples T-test to compare groups for oone variable;
% run as: [cfg1,probplot,cfg2,statplot]=indepT('s1p');
% click on interactive map to explore. press q to quit.
% first map is p values. second map is t values.
% later plot images by: ft_sourceplot(cfg1,probplot) and ft_sourceplot(cfg2,statplot)

% condA='s1p'; % nn for new nai, n for nai, p for pow, e for epochs, m for mean.
eval(['load ',[condA,compt]])

cfg=[];
eval(['cfg.dim = ',condA,'.dim;']);
%cfg.method      = 'montecarlo';
cfg.method      = 'analytic';
cfg.statistic   = 'indepsamplesT';
cfg.parameter   = 'nai';
if condA(1,end)=='p'
    cfg.parameter   = 'pow';
end
cfg.correctm    = 'bonferoni';
%cfg.correctm    = 'no'; %  'no', 'max', 'cluster', 'bonferoni', 'holms', 'fdr'
%cfg.numrandomization = 1000;
cfg.alpha       = 0.05; % 0.05
cfg.tail        = 0;


eval(['nsubj=length(',condA,'.trial)']);
load DESIGN
% cfg.design(1,:) = [1:nsubj];
% cfg.design(2,:) = [2 1 1 1 2 2 1 1 2 2 2 1 2 2 1 1 2]; % 1=low anxiety 2=high anxiety
cfg.design=DESIGN;
cfg.uvar        = 1; % row of design matrix that contains unit variable (in this case: subjects)
cfg.ivar        = 2; % row of design matrix that contains independent variable (the conditions)
eval(['stat = sourcestatistics(cfg, ',condA,');']);

load ~/ft_BIU/LCMV/pos
stat.pos=pos;
clear(condA)
cfg = [];
cfg.parameter = 'prob'; %'all' 'prob' 'stat' 'mask'
% cfg.downsample = 2;
% sMRI=read_mri('/home/meg/Documents/MATLAB/spm8/canonical/single_subj_T1.nii');
load ~/ft_BIU/LCMV/sMRI
probplot = sourceinterpolate(cfg, stat,sMRI)
probplot.prob1=1-probplot.prob;
lowlim=0.95;
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
    %cfg1.location=[ -42 -58 -11]
    %cfg1.location=[-42 -58 -11];% wer= -50 -45 10 , broca= -50 25 0, fussiform = -42 -58 -11(cohen et al 2000), change x to positive for RH.
    %cfg1.crosshair='no';
    figure
    ft_sourceplot(cfg1,probplot)
    cfg.parameter = 'stat';
    statplot = sourceinterpolate(cfg, stat,sMRI)
    cfg2=rmfield(cfg1,'funcolorlim');
    cfg2.funcolorlim = [-3.5 3.5]; 
    cfg2.funparameter = 'stat';
    cfg2.method='ortho';
    cfg2.inputcoord='mni';
    cfg2.atlas='aal_MNI_V4.img';
    ft_sourceplot(cfg2,statplot)
    str=[condA,'_',compt];
    display(['to save run: save(''',str,''',''','cfg1',''',','''probplot''',',','''cfg2''',',','''statplot''',')'])
else warning('no significant results')
end