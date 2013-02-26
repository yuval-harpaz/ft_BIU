function tracePlot_BIU(begTime,endTime,source)
if ~exist('source','var')
    source='c,rfhp1.0Hz,ee';
end
if ~exist('begTime','var')
    begTime=5;
end
if ~exist('endTime','var')
    endTime=15;
end
cfg.dataset=source;
cfg.trialdef.beginning=begTime;
cfg.trialdef.end=endTime;
cfg.trialfun='trialfun_raw';
cfg1=ft_definetrial(cfg);
str='{';for i=1:248;str=[str,' ','''A',num2str(i),''''];end;str=[str,'}'];
eval(['chans=',str,';']);
cfg1.channel='MEG';
cfg1.hpfilter='yes';
cfg1.hpfreq=3;
display('reading and filtering')
data=ft_preprocessing(cfg1);
trial=zeros(size(data.trial{1,1}));
display('sorting channels')
for i=1:248
    for j=1:248
        if strcmp(['A',num2str(i)],data.label{j,1})
            trial(i,:)=data.trial{1,1}(j,:);
        end
    end
end
trial=trial.*10^12;
% sd=median(std(trial'));
sd=0.3;

screen_size = get(0, 'ScreenSize');
firstChan=1;lastChan=248;
chans=firstChan:4:lastChan;
chart=zeros(62,size(data.trial{1,1},2));
for chan=1:62
    chart(chan,:)=trial(chans(chan),:)-chan*sd*10;
end
ch=firstChan:28:lastChan;
for chTick=1:9
    ticks{1,(10-chTick)}=['A',num2str(ch(chTick))];
end

figure1 = figure('XVisual',...
    '0x23 (TrueColor, depth 32, RGB mask 0xff0000 0xff00 0x00ff)','Position', [0 0 0.9*screen_size(3) 0.9*screen_size(4) ]);
axes1 = axes('Parent',figure1,...
    'YTickLabel',ticks,...
    'YTick',[-171 -150 -129 -108 -87 -66 -45 -24 -3]);
box('on');
hold('all');
plot(data.time{1,1},chart,'Parent',axes1)
xlim([begTime endTime]);
ylim([min(min(chart)) max(max(chart))]);
end