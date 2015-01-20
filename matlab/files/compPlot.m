function compPlot(comp)
% view output of ft_componentanalysis, comp by comp, avg over trials
screen_size = get(0, 'ScreenSize');
figure2 = figure('position',[0.35*screen_size(3) 0.45*screen_size(4) 0.5*screen_size(4) 0.5*screen_size(4)],'toolbar','none','menubar','none');
title('FIELDTRIP TOPOPLOT')
cfg.feedback='no';
figure1 = figure(...
    'Position', [0.25*screen_size(3) 0.15*screen_size(4) 0.5*screen_size(3) 0.25*screen_size(4)],...
    'toolbar','none','menubar','none');
axes1 = axes('Parent',figure1);
box('on');
hold all;
avgComp=ft_timelockanalysis(cfg,comp);
info.ntrl    = length(comp.trial);
info.trlop   = 1;
title('COMP 1');
guidata(figure1,info);
uicontrol(figure1,'units','pixels','position',[50 5 50 18],'String','next comp>',...
    'Callback',@markgood_next);
newfig(info.trlop)
    function markgood_next(varargin)
        if info.trlop==length(comp.trial)
            
            return;
        end
        info = guidata(figure1);
        if info.trlop < info.ntrl,
            info.trlop = info.trlop + 1;
        end;
        newfig(info.trlop);
        guidata(figure1,info);
        uiresume;
    end
    function newfig(~)
        datacursormode on
        cla
        plot(avgComp.time,avgComp.avg(info.trlop,:),'Parent',axes1,'color','k');
        title(['TRIAL ',num2str(info.trlop)]);
        topo=comp.topo(:,info.trlop);
        cfg=[];
        cfg.layout='4D248.lay';
        cfg.zlim = [-max(abs(topo)) max(abs(topo))]; %
        cfg.trials=info.trlop;
        figure(figure2);
        topoplot248(topo,cfg);
        display(['topoplot of comp ',num2str(info.trlop)]);
        
    end
end