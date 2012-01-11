cfg= [];
cfg.dataset='xc,hb,lf_c,rfhp0.1Hz'; % change file name or path+name
cfg.trialdef.eventtype='TRIGGER';
cfg.trialdef.eventvalue=[100,102,104,106]; % all conditions.
cfg.trialdef.prestim=0.3;
cfg.trialdef.poststim=0.9;
cfg.trialdef.offset=-0.3;
% cfg.trialdef.rspwin = 2.5;
% cfg.trialdef.visualtrig='visafter'; 
% cfg.trialdef.visualtrigwin=0.6;
cfg.trialdef.powerline='yes'; % takes into account triggers that contain the electricity in the wall (+256).
cfg.trialfun='BIUtrialfun';
cfg1=ft_definetrial(cfg);
cfg1.blc='yes';
cfg1.continuous='yes';
cfg1.channel={'MEG','-A204','-A74'};
cfg1.blc='yes';

%% looking for high frequency noise (muscle)

cfg2=cfg1;
cfg2.hpfilter='yes';cfg2.hpfreq=60;
datahf=ft_preprocessing(cfg1);
cfg3=[];
cfg3.method='summary'; %trial
cfg3.channel='MEG';
cfg3.alim=1e-12;
datahfrv=ft_rejectvisual(cfg3, datahf);
cfg1.trl=reindex(datahf.cfg.trl,datahfrv.cfg.trl);
%% reading the data
cfg1.blcwindow=[-0.2,0];
cfg1.bpfilter='yes';
cfg1.bpfreq=[1 40];

dataorig=ft_preprocessing(cfg1); % reading the data

%% PCA
cfg            = [];
cfg.method='pca';
%cfg.channel = {'-A204'};
comp           = ft_componentanalysis(cfg, dataorig);

%see the components and find the artifact
cfg=[];
cfg.comp=1:5;
cfg.layout='4D248.lay';
comppic=ft_componentbrowser(cfg,comp);
%% ICA
cfg            = [];
cfg.resamplefs = 300;
cfg.detrend    = 'no';
dummy           = ft_resampledata(cfg, dataorig);
save dummy dummy

%run ica
cfg            = [];
cfg.channel    = {'MEG'};
comp_dummy           = ft_componentanalysis(cfg, dummy);

%see the components and find the artifact
cfg=[];
cfg.comp=[1:5];
cfg.layout='4D248.lay';
comppic=ft_componentbrowser(cfg,comp_dummy);

%run the ICA in the original data
cfg = [];
cfg.topo      = comp_dummy.topo;
cfg.topolabel = comp_dummy.topolabel;
comp     = ft_componentanalysis(cfg, dataorig);

%% remove the artifact component
cfg = [];
cfg.component = [2 3]; % change
dataica = ft_rejectcomponent(cfg, comp);

%% base line correction
dataica=correctBL(dataica,[-0.2 0]);


%% reject visual
cfg=[];
cfg.method='summary'; %trial
cfg.channel='MEG';
cfg.alim=1e-12;
datacln=ft_rejectvisual(cfg, dataica);

cfg=[]            
avg=ft_timelockanalysis(cfg,datacln);
%butterfly
cfg=[];
cfg.layout='butterfly';
figure;
ft_multiplotER(cfg, avg);


%topoplot
cfg=[];
cfg.layout='4D248.lay';
cfg.interactive='yes';
cfg.xlim = [0.15 0.15]; %time window in ms
cfg.electrodes = 'labels';
figure;
ft_topoplotER(cfg, avg);

%% split conditions

cfg=[];
cfg.cond=100; % furniture
fur=splitconds(cfg,datacln);
cfg.cond=102; % Veg
veg=splitconds(cfg,datacln);
cfg.cond=104; % clo
clo=splitconds(cfg,datacln);
cfg.cond=106; % des
des=splitconds(cfg,datacln);

% averaging
fur=ft_timelockanalysis([],fur);
veg=ft_timelockanalysis([],veg);
clo=ft_timelockanalysis([],clo);
des=ft_timelockanalysis([],des);

%% plot
cfg=[];
cfg.interactive='yes';
% cfg.showlabels='yes';
% cfg.fontsize=10;
cfg.layout='4D248.lay';
ft_multiplotER(cfg,fur,veg,clo,des); % cfg.graphcolor='brgkywrgbkywrgbkywrgbkyw'
legend('fur','veg','clo','des');
% save /media/disk/rotem/sub3 dog veg fur des
