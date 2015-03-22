function [good,bad,trials]=badTrials(cfg,data,plt)
% give it fieldtrip data and it will find bad trials
% examples:
%
% calculate mean absolute value per trial and exclude trials with values
% greater than 3 SD over the median trial
% cfg.method='abs';
% cfg.criterion='sd';
% cfg.critval=3;
% [good,bad]=badTrials(cfg,data,1)
% 
% calculate variance for each trial and exclude trials exceeding a fixed
% threshold of 1e-25
% cfg.method='var';
% cfg.criterion='fixed';
% cfg.critval=1e-25;
% [good,bad]=badTrials(cfg,data,1)
%
% cfg.badChan = {'A74','A204'}; to ignore certain channels
%
% [good,bad]=badTrials(data) to use default cfg
%
% with criterion='median' you choose what part of the median (e.g. cfg.critval=0.5) to add to
% the median for noise threshold. this worked well for muscle artifact
if nargin==1
    data=cfg;
    cfg=[];
    plt=1;
end
if isempty(cfg)
    cfg.method='abs';
end
if ~isfield(cfg,'method')
    cfg.method='abs';
end
if ~isfield(cfg,'criterion')
    cfg.criterion='sd';
end
if ~isfield(cfg,'critval')
    cfg.critval=3;
end
chi=1:size(data.trial{1},1);
if isfield(cfg,'badChan')
    badChani=find(ismember(data.label,cfg.badChan));
    chi(badChani)=[]; %#ok<*FNDSB>
end
if ~existAndFull('plt')
    plt=1;
end
% 
switch cfg.method
    case 'abs'
        trials=[];
        for triali=1:length(data.trial)
            trials(triali)=mean(mean(abs(data.trial{1,triali}(chi,:))));
        end
    case 'var'
        trials=[];
        for triali=1:length(data.trial)
            trials(triali)=var(reshape(data.trial{1,triali}(chi,:),1,length(chi)*size(data.trial{1,1},2)));
        end
end
switch cfg.criterion
    case 'sd'
        thr=median(trials)+cfg.critval*std(trials);
    case 'fixed'
        thr=cfg.critval;
    case 'median'
        thr=median(trials).*(1+cfg.critval);
end
good=find(trials<thr);
bad=find(trials>thr);
badn=num2str(length(bad));
display(['rejected ',badn,' trials']);
if plt
    figure;
    plot(trials,'o')
    hold on
    plot(bad,trials(bad),'r.')
    xlim([-5 length(trials)+5])
end