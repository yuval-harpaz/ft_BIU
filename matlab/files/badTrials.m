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
switch cfg.method
    case 'abs'
        trials=[];
        for triali=1:length(data.trial)
            trials(triali)=mean(mean(abs(data.trial{1,triali})));
        end
    case 'var'
        trials=[];
        for triali=1:length(data.trial)
            trials(triali)=var(reshape(data.trial{1,triali},1,size(data.trial{1,1},1)*size(data.trial{1,1},2)));
        end
end
switch cfg.criterion
    case 'sd'
        thr=median(trials)+cfg.critval*std(trials);
    case 'fixed'
        thr=cfg.critval;
end
good=find(trials<thr);
bad=find(trials>thr);
badn=num2str(length(bad));
display(['rejected ',badn,' trials']);
if plt
    plot(trials,'o')
    hold on
    plot(bad,trials(bad),'r.')
    xlim([-5 length(trials)+5])
end