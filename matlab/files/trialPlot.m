function trialPlot(data)
% view trials and mark good or bad. in the end it writes a badtrials.mat
% file with 0 for good and 1 for bad trial numbers.
data=rmfield(data,'sampleinfo');
global pos posPrev quitFunc
quitFun=false;
pos=data.time{1}(1);
posPrev=pos;
info=[];
close all
figure2 = figure;
title('FIELDTRIP TOPOPLOT')
cfg=[];
cfg.layout='4D248.lay';
cfg.xlim = [pos(1) pos(1)]; %time window in ms
cfg.trials=1;
cfg.channel=data.label;
figure(figure2);
ft_topoplotER(cfg, data);
display('plot of trial 1');
display('click on the traces to get a topoplot for selected time points')
if ~isfield(data,'trial')
    error('requires fieldtrip data with trials');
end
begTime=data.time{1,1}(1,1);
endTime=data.time{1,1}(1,end);
trial=data.trial{1,1};
trial=trial.*10^12;
% sd=median(std(trial'));
sd=0.15;

screen_size = get(0, 'ScreenSize');


chCount=0;
for chani=1:248
    [member,chi]=ismember(['A',num2str(chani)],data.label);
    if member
        chCount=chCount+1;
        Chi(chCount)=chi;
    end
end
firstChan=1;lastChan=length(Chi);
chans=firstChan:4:lastChan;
chans=Chi(chans);
chart=zeros(62,size(data.trial{1,1},2));
for chan=1:62
    chart(chan,:)=trial(chans(chan),:)-chan*sd*10;
end
%ch=firstChan:28:lastChan;
for chTick=1:9
    ticks{1,(10-chTick)}='';
end

figure1 = figure('XVisual',...
    '0x23 (TrueColor, depth 32, RGB mask 0xff0000 0xff00 0x00ff)',...
    'Position', [0 0.05*screen_size(4) 200 0.9*screen_size(4) ]);
axes1 = axes('Parent',figure1,...
    'YTickLabel',ticks,...
    'YTick',[-171 -150 -129 -108 -87 -66 -45 -24 -3]);
box('on');
hold all;
%plot(data.time{1,1},chart,'Parent',axes1)
xlim([begTime endTime]);
ylim([min(min(chart))-5 max(max(chart))+5]);

ntrl  = length(data.trial);
info.ntrl    = ntrl;
info.trlop   = 1;
badtrials = false(1,length(data.trial));
title(['TRIAL 1']);
guidata(figure1,info);
uicontrol(figure1,'units','pixels','position',[50 5 50 18],'String','good>',...
    'Callback',@markgood_next);
uicontrol(figure1,'units','pixels','position',[100 5 50 18],'String','bad>',...
    'Callback',@markbad_next);
uicontrol(figure1,'units','pixels','position',[0 5 50 18],'String','back<',...
    'Callback',@back);
uicontrol(figure1,'units','pixels','position',[150 5 50 18],'String','quit',...
    'Callback',@quit);

newfig(info.trlop)

    function bt = quit(varargin)
        save badtrials badtrials
        display('badtrials.mat saved')
        if ~isempty(find(badtrials))
            display(['bad trials: ',num2str(find(badtrials))]);
        else
            disp('no bad trials were marked')
        end
        close all
        quitFunc=true;
        %evalin('caller','return')
    end

    function bt = back(varargin)
        if info.trlop == 1
            display('no prior trials');
        end
        next(varargin{:})
        newfig(info.trlop);
        
        function varargout = next(figure1, eventdata, handles, varargin)
            info = guidata(figure1);
            if info.trlop > 1;
                info.trlop = info.trlop - 1;
            end;
            guidata(figure1,info);
            uiresume;
        end
    end

    function bt = markgood_next(varargin)
        %        markgood(varargin{:});
        %         next(varargin{:});
        display(['trial ',num2str(info.trlop),' good']);
        if info.trlop==length(data.trial)
            display('badtrials.mat saved')
            if ~isempty(find(badtrials))
                display(['bad trials: ',num2str(find(badtrials))]);
            else
                disp('no bad trials were marked')
            end
            save badtrials badtrials
            close all
            return;
        end
        badtrials(info.trlop)=0;
        next(varargin{:})
        newfig(info.trlop);
        
        function varargout = next(figure1, eventdata, handles, varargin)
            info = guidata(figure1);
            if info.trlop < info.ntrl,
                info.trlop = info.trlop + 1;
            end;
            guidata(figure1,info);
            uiresume;
        end
    end

    function bt = markbad_next(varargin)
        display(['trial ',num2str(info.trlop),' bad']);
        badtrials(info.trlop)=1;
        if info.trlop==length(data.trial)
            save badtrials badtrials
            display('badtrials.mat saved')
            if ~isempty(find(badtrials))
                display(['bad trials: ',num2str(find(badtrials))]);
            else
                disp('no bad trials were marked')
            end
            
            close all
            return;
            
        end
        next(varargin{:})
        newfig(info.trlop);
        
        function varargout = next(figure1, eventdata, handles, varargin)
            info = guidata(figure1);
            if info.trlop < info.ntrl,
                info.trlop = info.trlop + 1;
            end;
            guidata(figure1,info);
            uiresume;
        end
    end
    function newfig(trnum)
        datacursormode on
        trial=data.trial{1,trnum};
        trial=trial.*10^12;
        firstChan=1;lastChan=248;
        chans=firstChan:4:lastChan;
        chart=zeros(62,size(data.trial{1,1},2));
        for Chan=1:62
            chart(Chan,:)=trial(chans(Chan),:)-Chan*sd*10;
        end
        cla
        plot(data.time{1,1},chart,'Parent',axes1,'color','k');
        title(['TRIAL ',num2str(info.trlop)]);
        dcm_obj = datacursormode(figure1);
        set(dcm_obj,'UpdateFcn',@DCMupdatefcn)
        %datacursormode off
        for loopi=1:600
            pause(0.1)
            if quitFunc
                return
            end
            if posPrev~=pos;
                info.trlop
                cfg=[];
                cfg.layout='4D248.lay';
                cfg.xlim = [pos(1) pos(1)]; %time window in ms
                cfg.trials=info.trlop;
                figure(figure2);
                ft_topoplotER(cfg, data);
                display(['plot of trial ',num2str(info.trlop)]);
                posPrev=pos;
                output_txt = {['X: ',num2str(pos(1),4)],...
                ['Y: ',num2str(pos(2),4)]};
            end
            %datacursormode on
        end
         
        %datacursormode on
        function txt = DCMupdatefcn(empt,event_obj)
            
            pos = get(event_obj,'Position');
           
            %assignin(pos, 'pos', 'caller')
            
            %set(dcm_obj,'Enable','off');
            %delete(findall(gcf,'Type','hggroup'));
            %clear dcm_obj
%             datacursormode off
%             info.trlop
%             cfg=[];
%             cfg.layout='4D248.lay';
%             cfg.xlim = [pos(1) pos(1)]; %time window in ms
%             cfg.trials=info.trlop;
%             figure(figure2);
%             figure;
%             ft_topoplotER(cfg, data);
%             display(['plot of trial ',num2str(info.trlop)]);
%             datacursormode on
            
        end
    end



end