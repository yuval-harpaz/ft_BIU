fileName = 'c,rfhp0.1Hz';
p=pdf4D(fileName);
cleanCoefs = createCleanFile(p, fileName,...
    'byLF',0,...
    'byFFT',0,...
    'HeartBeat',[]);

cfg=[];
cfg.dataset='hb_c,rfhp0.1Hz'; % change file name or path+name
cfg.trialdef.eventtype='TRIGGER';
%cfg.trialdef.eventvalue= 102; % 
cfg.trialdef.prestim=0.1;
cfg.trialdef.poststim=0.3;
cfg.trialdef.offset=-0.1;
cfg.trialfun='BIUtrialfun';
cfg.trialdef.eventvalue= 104;
cfg1=definetrial(cfg);
cfg1.blc='yes';
cfg1.continuous='yes';
cfg1.blcwindow=[-0.1,0];
cfg1.bpfilter='yes';
cfg1.bpfreq=[3 35];
cfg1.channel={'MEG','MEGREF'}
dataorig=ft_preprocessing(cfg1);
hdr=ft_read_headerOLD('c,rfhp0.1Hz');
dataorig.grad=ft_convert_units(hdr.grad,'mm');
% cfg2=[];
% cfg2.method='summary';%'trial';
% cfg2.channel={'MEG','REF'};
% %cfg2.keepchannel='yes';
% cfg2.alim=1e-12;
% datacln=rejectvisual(cfg2, dataorig);
leftIndSom=timelockanalysis([],dataorig);

%% visual rejection

% datacln=rejectvisual(cfg2, dataorig);
%% averaging and baseline correction
% rightPre=timelockanalysis([],datacln);
%% interactive multiplot
%% interactive multiplot
cfg3=[];
cfg3.interactive='yes';
%cfg.showlabels='yes';
cfg3.fontsize=10;
cfg3.layout='4D248.lay';
%multiplotER(cfg3,rightPre);

%% left ind pre

%figure;multiplotER(cfg3,leftPre);

%% right ind post
cfg.trialdef.eventvalue= 104;
cfg1=definetrial(cfg);
cfg1.blc='yes';
cfg1.continuous='yes';
cfg1.blcwindow=[-0.1,0];
cfg1.bpfilter='yes';
cfg1.bpfreq=[3 35];
dataorig=preprocessing(cfg1);
datacln=rejectvisual(cfg2, dataorig);
leftPre=timelockanalysis([],datacln);
%figure;multiplotER(cfg3,leftPre);

%% dipole fit

[vol,grid,mesh,M1]=headmodel1;
load ~/ft_BIU/matlab/files/sMRI.mat
MRIcr=sMRI;
MRIcr.transform=inv(M1)*sMRI.transform; %cr for corregistered MRI
if ~exist('leftIndSom','var')
    load leftIndSom
end
cfg5 = [];
cfg5.latency = [0.03 0.045];  % specify latency window around M50 peak
cfg5.numdipoles = 1;
cfg5.vol=vol;
cfg5.feedback = 'textbar';
cfg.res=2;
%cfg5.gridsearch='yes';
%cfg5.grid=grid;
dip = ft_dipolefitting(cfg5, leftIndSom);
cfg6 = [];
cfg6.location = dip.dip.pos(1,:) %* 10;   % convert from cm to mm
figure; ft_sourceplot(cfg6, MRIcr);title('L')
%% LCMV
t1=0.15;t2=0.55;
cfg7                  = [];
cfg7.covariance       = 'yes';
cfg7.removemean       = 'no';
cfg7.covariancewindow = [(t1-t2) 0];
cfg7.channel={'MEG','MEGREF'};
covpre=timelockanalysis(cfg7, leftIndSom);
cfg7.covariancewindow = [t1 t2];
covpst=timelockanalysis(cfg7, leftIndSom);
cfg8        = [];
cfg8.method = 'sam';
cfg8.grid= grid;
cfg8.vol    = vol;
cfg8.lambda = 0.05;
cfg8.keepfilter='no';

spre = ft_sourceanalysis(cfg8, covpre);
spst = ft_sourceanalysis(cfg8, covpst);
spst.avg.nai=(spst.avg.pow-spre.avg.pow)./spre.avg.pow;
%% interpolate and plot
% load ~/ft_BIU/matlab/LCMV/pos
cfg10 = [];
cfg10.parameter = 'avg.nai';
inai = sourceinterpolate(cfg10, spst,MRIcr)
% cfg10.parameter = 'avg.pow';
% ipow = sourceinterpolate(cfg10, spst,MRIcr)
cfg9 = [];
cfg9.interactive = 'yes';
cfg9.funparameter = 'avg.nai';
cfg9.method='ortho';
figure;ft_sourceplot(cfg9,inai)
cfg10.xlim=[0.035 0.05];
helmetplot(cfg10,leftIndSom);

%% multiplespheres
hdr=ft_read_headerOLD('c,rfhp0.1Hz');
leftIndSom.grad=ft_convert_units(hdr.grad,'mm');

[vol,grid,mesh,M1,single]=headmodel1([],[],[],[],'localspheres');

cfg8        = [];
cfg8.method = 'sam';
cfg8.grid= grid;
cfg8.vol    = single;
cfg8.lambda = 0.05;
cfg8.keepfilter='no';

spre = ft_sourceanalysis(cfg8, covpre);
spst = ft_sourceanalysis(cfg8, covpst);
spst.avg.nai=(spst.avg.pow-spre.avg.pow)./spre.avg.pow;
