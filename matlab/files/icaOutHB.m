function data=icaOutHB(data,lat,bpfreq)
if ischar(data) % read original data ('c,rfhp...')
    cfg=[];
    cfg.dataset=data;
    if exist('lat','var')
        cfg.trialdef.beginning=lat(1);
        cfg.trialdef.end=lat(2);
    end
    cfg.trialfun='trialfun_raw';
    cfg1=ft_definetrial(cfg);
    cfg1.channel='MEG';
    if exist('bpfreq','var');
        cfg1.bpfilter='yes';
        cfg1.bpfreq=bpfreq;
    end
    data=ft_preprocessing(cfg1);     %#ok<NASGU>
end

cfg2            = [];
cfg2.resamplefs = 150;
cfg2.detrend    = 'no';
dummy           = ft_resampledata(cfg2, data);
save dummy dummy

%run ica
cfg3            = [];
cfg3.channel    = {'MEG'};
comp_dummy           = ft_componentanalysis(cfg3, dummy);

%see the components and find the artifact
cfg4=[];
cfg4.comp=[1:20];
cfg4.layout='4D248.lay';
comppic=ft_componentbrowser(cfg4,comp_dummy);

%[posrate,hbcomp]=max(abs(mean(1000*comp.topo(:,1:20)>0)));
% display(['hb like component is pca ',num2str(hbcomp),' with ',num2str(round(100*posrate)),'% weights positive']);
% if posrate>0.9
cfg5 = [];
cfg5.topo      = comp_dummy.topo;
cfg5.topolabel = comp_dummy.topolabel;
comp     = ft_componentanalysis(cfg5, data);
    cfg6 = [];
    cfg6.component = [1 2]; % change
    data = ft_rejectcomponent(cfg6, comp);
    data=correctBL(data,[data.time{1,1}(1,1) data.time{1,1}(1,end)]);

end
