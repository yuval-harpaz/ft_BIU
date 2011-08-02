function [trial,time]=findBadChans2(source,MorE,comp)
% MorE = 'E' for EEG or M for
% comp = output of ft_componentanalysis, 5 components only.
cfg.dataset=source;
cfg.trialdef.poststim=10;
cfg.trialfun='trialfun_beg';
cfg1=ft_definetrial(cfg);
if ~exist('MorE','var')
    MorE='M';
end
if strcmp(MorE,'E')
    str='{';for i=1:30;str=[str,' ','''E',num2str(i),''''];end;str=[str,'}']; %#ok<AGROW>
else
    str='{';for i=1:248;str=[str,' ','''A',num2str(i),''''];end;str=[str,'}']; %#ok<AGROW>
end

eval(['chans=',str]);
cfg1.channel=chans; %#ok<NODEF>
% if strcmp(MorE,'E')
%     cfg1.channel='EEG';
% end
cfg1.hpfilter='yes';
cfg1.hpfreq=3;
display('reading and filtering')
data=ft_preprocessing(cfg1);
time=data.time{1,1};
trial=zeros(size(data.trial{1,1}));
display('sorting channels')
if strcmp(MorE,'E')
    for i=1:30
        for j=1:30
            if strcmp(['E',num2str(i)],data.label{j,1})
                trial(i,:)=data.trial{1,1}(j,:);
            end
        end
    end
else
    for i=1:248
        for j=1:248
            if strcmp(['A',num2str(i)],data.label{j,1})
                trial(i,:)=data.trial{1,1}(j,:);
            end
        end
    end
end
if strcmp(MorE,'E')
    trial=trial.*10^5;
else
    trial=trial.*10^12;
end
% sd=median(std(trial'));


screen_size = get(0, 'ScreenSize');
sd=1;
if strcmp(MorE,'E')
    firstChan=1;lastChan=30;
    chans=firstChan:lastChan;
    chart=zeros(30,size(data.trial{1,1},2));
    for chan=1:30
        chart(chan,:)=trial(chans(chan),:)-chan*sd*10;
    end
    ch=firstChan:7:lastChan;
    for chTick=1:5
        ticks{1,(6-chTick)}=['E',num2str(ch(chTick))]; %#ok<AGROW>
    end  
        
    figure1 = figure('XVisual',...
        '0x23 (TrueColor, depth 32, RGB mask 0xff0000 0xff00 0x00ff)','Position', [0 0 screen_size(3) screen_size(4) ]);
    axes1 = axes('Parent',figure1,...
        'YTickLabel',ticks,...
        'YTick',[-290 -220 -150 -80 -10]);
    box('on');
    hold('all');
    plot(data.time{1,1},chart,'Parent',axes1)
    title(['Channels E',num2str(firstChan),' to E',num2str(lastChan)]);
    if exist('comp','var')
        for c=1:5;
            plot(time,(comp(c,1:size(time,2))-300-c*10),'k');
        end
    end
    return
end
firstChan=187;
for i=1:4;
    lastChan=firstChan+61;
    chans=firstChan:lastChan;
    chart=zeros(62,size(data.trial{1,1},2));
    for chan=1:62
        chart(chan,:)=trial(chans(chan),:)-chan*sd*10;
    end
    ch=firstChan:7:lastChan;
    for chTick=1:9
        ticks{1,(10-chTick)}=['A',num2str(ch(chTick))]; %#ok<AGROW>
    end  
        
    figure1 = figure('XVisual',...
        '0x23 (TrueColor, depth 32, RGB mask 0xff0000 0xff00 0x00ff)','Position', [0 0 screen_size(3) screen_size(4) ]);
    axes1 = axes('Parent',figure1,...
        'YTickLabel',ticks,...
        'YTick',[-171 -150 -129 -108 -87 -66 -45 -24 -3]);
    box('on');
    hold('all');
    plot(data.time{1,1},chart,'Parent',axes1)
    title(['Channels A',num2str(firstChan),' to A',num2str(lastChan)]);
    firstChan=firstChan-62;
end
