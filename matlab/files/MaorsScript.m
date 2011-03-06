% first step - open: home>meg>ducoments>MATLAB>MatlabTools>C50Hz2msi.m
% Replace the path to your file and run it.

subnum = 1; %change

orig = ['save ','yh',num2str(subnum),'orig', ' dataorig'];
clean = ['save ','yh',num2str(subnum),'cln', ' datacln'];
components = ['save ','yh',num2str(subnum),'comp',' comp'];
ica = ['save ','yh',num2str(subnum),'ica', ' dataica'];

%% defining trials in all the data.
cfg=[];
cfg.dataset='c,rfhp1.0Hz,lp'; % change file name or path+name
cfg.trialdef.eventtype='TRIGGER';
cfg.trialdef.eventvalue=[2,4,6]; % all conditions.
cfg.trialdef.prestim=0.3;
cfg.trialdef.poststim=0.7;
cfg.trialdef.offset=0;
cfg.trialdef.rspwin = 2.5;
cfg.trialdef.visualtrig='before'; 
cfg.trialdef.visualtrigwin=0.6;
cfg.trialdef.powerline='yes'; % takes into account triggers that contain the electricity in the wall (+256).
cfg.trialfun='BIUtrialfun';
cfg=definetrial(cfg);

% creating colume 7 with correct code
for i=1:length(cfg.trl)
	if (cfg.trl(i,4)==2) cfg.trl(i,7)=1; end;
	if ((cfg.trl(i,4)==4) && (cfg.trl(i,6)==256)) cfg.trl(i,7)=1; end;
	if ((cfg.trl(i,4)==6) && (cfg.trl(i,6)==512)) cfg.trl(i,7)=1; end;
end;			

% preprocessing 
cfg.blc='yes';
cfg.continuous='yes';
cfg.blcwindow=[-0.2,0];
cfg.lpfilter='yes';
cfg.lpfreq=50;
dataorig=preprocessing(cfg);
eval(orig); 

%% artifact rejection
%remove muscle
cfg.artfctdef.muscle.feedback='yes';
cfg.artfctdef.muscle. channel='MEG';
cfg=artifact_muscle(cfg);
% מוציא פידבק בצורת גראף עם הנתונים. ציר ה-X הוא זמן וציר ה-Y הוא ציוני התקן. נגדיר ציון תקן ממנו ואלאה זה יחתוך. במסוף אני מקליד Y ואנטר ואז אני רואה ארטיפקט ארטיפקט בטסלות ובציוני תקן. הוא מבקש נקודת חיתוך חדשה (למשל, 10). הוא מוציא שוב גראף ואני בודק אם זה עונה על דרישותיי. אם כן אז אני רושם N ואנטר. אם לא אז אני מקליד Y ואנטר וחוזר על התהליך. בצד חשוב לרשום לעצמי איזה Z בחרתי וכמה ארטיפקטים זה מצא.
%remove jump
cfg.artfctdef.jump.feedback='yes';
cfg.artfctdef.jump.channel='MEG';
cfg=artifact_jump(cfg);
% מוציא פידבק בצורת גראף עם הנתונים. ציר ה-X הוא זמן וציר ה-Y הוא ציוני התקן. נגדיר ציון תקן ממנו ואלאה זה יחתוך. במסוף אני מקליד Y ואנטר ואז אני רואה ארטיפקט ארטיפקט בטסלות ובציוני תקן. הוא מבקש נקודת חיתוך חדשה (למשל, 10). הוא מוציא שוב גראף ואני בודק אם זה עונה על דרישותיי. אם כן אז אני רושם N ואנטר. אם לא אז אני מקליד Y ואנטר וחוזר על התהליך. בצד חשוב לרשום לעצמי איזה Z בחרתי וכמה ארטיפקטים זה מצא.
%reject artifacts
cfg.artfctdef.reject = 'complete';   % this rejects complete trials, use 'partial' if you want to do partial artifact rejection
datacln = rejectartifact(cfg);
datacln = preprocessing(datacln) 
eval(clean);

%rejectvisual summary
cfg=[];
cfg.method='summary';
cfg.channel='MEG';
cfg.alim=1e-12;
datacln=rejectvisual(cfg, datacln); % reject all bad trials/channels manually

%rejectvisual trial
cfg=[];
cfg.method='trial';
cfg.channel='MEG';
cfg.alim=1e-12;
datacln=rejectvisual(cfg, datacln); % reject all bad trials/channels manually

% save only after choosing the trials/channels manually
eval(clean);
 
%% ICA to correct data

%resampling data to speed the ica
cfg            = [];
cfg.resamplefs = 300;
cfg.detrend    = 'no';
dummy           = resampledata(cfg, datacln);
save dummy dummy

%run ica
cfg            = [];
cfg.channel    = {'MEG'};
comp           = componentanalysis(cfg, dummy);
eval(components);

%prepare the layout
cfg = [];
cfg.grad = dummy.grad;
lay = prepare_layout(cfg);

%see the components and find the artifact
cfg=[];
cfg.comp=[1:20];
cfg.layout=lay;
comppic=componentbrowser(cfg,comp);

%run the ICA in the original data
cfg = [];
cfg.topo      = comp.topo;
cfg.topolabel = comp.topolabel;
comp_orig     = componentanalysis(cfg, datacln);

%remove the artifact component
cfg = [];
cfg.component = [1 2 7]; % change
dataica = rejectcomponent(cfg, comp_orig);
eval(ica);

%% defining trials (for correct answers only)
% define
cfg=[];
cfg.cond=10;
cond10=splitcondscrt(cfg,dataica);
cfg=[];
cfg.cond=20;
cond20=splitcondscrt(cfg,dataica);
cfg=[];
cfg.cond=30;
cond30=splitcondscrt(cfg,dataica);
cfg=[];
cfg.cond=40;
cond40=splitcondscrt(cfg,dataica);

% average
sub19avcond10=timelockanalysis(cfg,cond10); % change sub no.
sub19avcond20=timelockanalysis(cfg,cond20); % change sub no.
sub19avcond30=timelockanalysis(cfg,cond30); % change sub no.
sub19avcond40=timelockanalysis(cfg,cond40); % change sub no.
sub19avallcond=timelockanalysis(cfg,dataica); % change sub no.

% interactive plot multi conditions
cfg=[];
cfg.interactive='yes';
cfg.showlabels='yes';
cfg.fontsize=10;
cfg.layout='4D248.lay';
multiplotER(cfg,avcond10,avcond20,avcond30,avcond40);

% interactive plot single condition
multiplotER(cfg,avcond10);
% interactive plot single condition
multiplotER(cfg,avcond20);
% interactive plot single condition
multiplotER(cfg,avcond30);
% interactive plot single condition
multiplotER(cfg,avcond40);

% topoplot
cfg=[];
cfg.layout='4D248.lay';
cfg.xlim=[0.3:0.05:0.5]; % from 600ms to 800ms in 50ms interval
cfg.colorbar='yes';
topoplotER(cfg,avcond30); % avcond10/20/30/40 or avallcond

% statistics
cfg = [];
cfg.keepindividual = 'yes';
[grcond10] =  timelockgrandaverage(cfg, sub13avcond10, sub14avcond10, sub15avcond10, sub16avcond10, sub17avcond10, sub18avcond10, sub19avcond10);
[grcond20] =  timelockgrandaverage(cfg, sub13avcond20, sub14avcond20, sub15avcond20, sub16avcond20, sub17avcond20, sub18avcond20, sub19avcond20);
[grcond30] =  timelockgrandaverage(cfg, sub13avcond30, sub14avcond30, sub15avcond30, sub16avcond30, sub17avcond30, sub18avcond30, sub19avcond30);
[grcond40] =  timelockgrandaverage(cfg, sub13avcond40, sub14avcond40, sub15avcond40, sub16avcond40, sub17avcond40, sub18avcond40, sub19avcond40);

% interactive plot multi conditions for all subjects
cfg=[];
cfg.interactive='yes';
cfg.showlabels='yes';
cfg.fontsize=10;
cfg.layout='4D248.lay';
multiplotER(cfg,grcond10,grcond20,grcond30,grcond40);

% interactive plot single condition for all subjects
multiplotER(cfg,grcond10);

multiplotER(cfg,grcond20);

multiplotER(cfg,grcond30);

multiplotER(cfg,grcond40);

cfg = [];
cfg.channel = 'MEG';
cfg.parameter   = 'individual'; % for 1 subject, type "trial"
cfg.method = 'analytic';
cfg.statistic = 'depsamplesT';
cfg.alpha = 0.1;
design=[1 1 1 1 1 1 1 2 2 2 2 2 2 2; 1 2 3 4 5 6 7 1 2 3 4 5 6 7]; % for 7 subjects
cfg.design = design;
cfg.ivar = 1;
cfg.uvar = 2;

stat = timelockstatistics(cfg,grcond10,grcond30); % for tow conditions: cond10 and cond30

cfg = [];
cfg.layout='4D248.lay';
cfg.highlight=find(stat.mask(:,350)); % change time window
cfg.xlim=[350 500]; % change time window
topoplotER(cfg,grcond30);

% statistics for specific time window
cfg = [];
cfg.channel = 'MEG';
cfg.avgovertime='yes';
cfg.latency=[300 500];
cfg.parameter   = 'individual'; % for 1 subject, type "trial"
cfg.method = 'analytic';
cfg.statistic = 'depsamplesT';
cfg.alpha = 0.1;
design=[1 1 1 1 1 1 1 2 2 2 2 2 2 2; 1 2 3 4 5 6 7 1 2 3 4 5 6 7]; % for 7 subjects
cfg.design = design;
cfg.ivar = 1;
cfg.uvar = 2;

stat = timelockstatistics(cfg,grcond10,grcond30); % for tow conditions: cond10 and cond30

cfg = [];
cfg.layout='4D248.lay';
cfg.highlight=find(stat.mask); % change time window
topoplotER(cfg,grcond30);
