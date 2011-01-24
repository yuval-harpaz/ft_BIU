function covToMont(pat2data,fileName,startt,endt,conds,groups,skipto,finish,condA,condB)
%   pat2data is the path to a directory where all the data is, with files of every subject
%       in a numbered folder. in addition to fieldtrip preprocessed (averaged or epoched) files add
%       hs_file, config and data file (e.g. c,rfhp0.1Hz wich is also the fileName).
%   startt and endt is the time window for the component of interest, assumes
%       stimulus starts at 0.
%   conds is a cell erray with names of fildtrip data files (averaged or
%       epoched) for different experimental conditions
%   groups is a matrix with 1st row sub numbers, second row indicates 0 - not
%       to analize, or a positive number for group number (1,2...). write
%       one to all subjects for within subject paradigms
%   condA and condB are for monttecarlo analysis (monteT). for example condA='s1p' is the
%       'pow' (p) measurement for the source (s) of conds{1} .
%   skipto and finish limit the analysis for certain stages. if needs to skip to a particular stage use skipto, 1 to 5. 1 for covariance (beggining, not really skipping),
%       2 for head model, 3 for beamforming, 4 for grand averaging and 5 for montecarlo.
%   after creating and saving a list of conditions 'conds' and groups (may be [] for one
%       group) run:
% 
% load conds; load groups; covToMont('exp3/data','c,rfhp0.1Hz',0.7,0.8,conds,groups,3,5,'s1p','s2p');
%
% Note- designed for linux. lists the folders with ls function, needs change for windows.

%% lists the subject data folders
eval(['cd ',pat2data])
!ls > ls.txt
subjects=importdata('ls.txt')';
if isempty('groups'); % when no groups specified assumes all subjects valid members of one group
    groups=subjects;
    groups(2,:)=1;
end
compt=num2str(round(1000*(startt+endt)/2)); % component name for output files
if ~exist('skipto','var')
    skipto=1;
end
if isempty('skipto')
    skipto=1;
end
grid=[]; % avoid conflict with grid function
%load /media/disk/Sharon/MEG/Experiment3/Source_localization/subs
%load /media/disk/Sharon/MEG/Experiment3/Source_localization/conds
%% 1) calculating covariance matrices
if skipto==1
    for sub=1:size(subjects,2)
        pat=num2str(subjects(sub));
        for con=1:size(conds,2)
            c=conds{1,con};
            load ([pat,'/',c]);
            covst=eval(c); %#ok<NASGU>
            cfg                  = [];
            cfg.covariance       = 'yes';
            cfg.removemean       = 'no';
            cfg.covariancewindow = [(startt-endt) 0];
            cfg.channel='MEG';
            eval(['pre',num2str(con),'=timelockanalysis(cfg, covst)']);
            cfg.covariancewindow = [startt endt];
            eval(['pst',num2str(con),'=timelockanalysis(cfg, covst)']);
        end
        save ([num2str(subjects(sub)),'/cov',compt], 'pst*' ,'pre*');
        display(sub);
    end
end
if finish==1
    return
end
%% 2) building head model if necessary
if skipto<=2
    cfg=[];
    cfg.model='singleshell';
    for sub=1:size(subjects,2)  % size(subs,2)
        if ~exist([num2str(subjects(sub)),'/model.mat'],'file')
            load([num2str(subjects(sub)),'/',conds{1,1}]);
            hdr=ft_read_header([num2str(subjects(sub)),'/c,rfhp0.1Hz,lp']);
            eval([conds{1,1},'.grad=hdr.grad;'])
            %eval([conds{1,1},'.hdr=hdr;'])
            [vol,grid]=modelwithspm(cfg,eval(conds{1,1}),[num2str(subjects(sub)),'/hs_file']);
            save([num2str(subjects(sub)),'/model'],'vol','grid');
        end
    end
end
if finish==2
    return
end
%% 3) LCMV beamforming
if skipto<=3
    for sub=1:size(subjects,2); % change to 1:19 or 1:25
        pat=num2str(subjects(sub));
        load ([pat,'/cov',compt]);
        hdr=ft_read_header([pat,'/',fileName]);
        grad=hdr.grad; %#ok<NASGU>
        load ([pat,'/model']);
        cfg        = [];
        cfg.method = 'lcmv';
        cfg.grid= grid;
        cfg.vol    = vol;
        cfg.lambda = '5%';
        cfg.keepfilter='yes';
        for con=1:size(conds,2)
            eval(['pre',num2str(con),'.grad=grad']);
            eval(['pst',num2str(con),'.grad=grad']);
            eval(['spre',num2str(con),'  = sourceanalysis(cfg, pre',num2str(con),')']);
            eval(['spst',num2str(con),'  = sourceanalysis(cfg, pst',num2str(con),')']);
            eval(['spst',num2str(con),'.avg.nai=(spst',num2str(con),'.avg.pow./spre',num2str(con),'.avg.pow)-spre',num2str(con),'.avg.pow']);
            eval(['save ',pat,'/s',num2str(con),'_',compt,' spre',num2str(con),' spst',num2str(con)]);
            eval(['clear spre',num2str(con),' spst',num2str(con),' pre',num2str(con),' pst',num2str(con)])
        end
    end
end
if finish==3
    return
end
%% 4) Grand Averaging
if skipto<=4
    load pos
    dessub=1;
    for con=1:size(conds,2)
        str='';
        for sub=1:size(subjects,2)
            group=groups(2,find(groups(1,:)==(subjects(sub))));
            if group>0;
                load ([num2str(subjects(sub)),'/s',num2str(con),'_',compt]);
                eval(['s',num2str(con),'_',num2str(subjects(sub)),'=spst',num2str(con)]);
                eval(['s',num2str(con),'_',num2str(subjects(sub)),'.dim=[15,18,15]'])
                eval(['s',num2str(con),'_',num2str(subjects(sub)),'.pos=pos'])
                str=[str,',s',num2str(con),'_',num2str(subjects(sub))]; %#ok<AGROW>
                clear sp*
                display(subjects(sub));
                if con==1;
                    DESIGN(1,dessub)=dessub;
                    DESIGN(2,dessub)=group;
                    dessub=dessub+1;
                end
            end
        end
        cfg                    = [];
        cfg.parameter          = 'pow'; % 'pow' 'nai' or 'coh'
        cfg.keepindividual     = 'yes';
        eval(['s',num2str(con),'p=sourcegrandaverage(cfg,',str(2:size(str,2)),')']);
        eval(['save s',num2str(con),'p',compt,' s',num2str(con),'p']);
        cfg.parameter='nai';
        eval(['s',num2str(con),'n=sourcegrandaverage(cfg,',str(2:size(str,2)),')']);
        eval(['save s',num2str(con),'n',compt,' s',num2str(con),'n']);
        clear *_* *n *p
    end
    save DESIGN DESIGN % the design is only used for between group statistics
end
display(['for between group statistics use: [cfg1,probplot,cfg2,statplot]=indepT(''',compt,''',condA);'])
if finish==4
    return
end
%% 5) Montecarlo within subject statistic map
if skipto<=5
    % display('montecarlo not integrated yet')
    [cfg1,probplot,cfg2,statplot]=monteT(compt,condA,condB);
    str=[condA,'_',condB,'_',compt];
    save(str,'cfg1','probplot','cfg2','statplot')
end
if finish==5
    return
end
end
