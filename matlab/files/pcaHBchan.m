function HBchan=pcaHBchan(data,lat,bpfreq)
if ischar(data) % read original data ('c,rfhp...')
    cfg=[];
    cfg.dataset=data;
    if exist('lat','var')
        if ~isempty(lat)
            cfg.trialdef.beginning=lat(1);
            cfg.trialdef.end=lat(2);
        end
    end
    cfg.trialfun='trialfun_raw';
    cfg1=ft_definetrial(cfg);
    cfg1.channel='MEG';
    if exist('bpfreq','var');
        cfg1.bpfilter='yes';
        cfg1.bpfreq=bpfreq;
    end
    data=ft_preprocessing(cfg1);
else
    error ('needs name of original data file, c,rfhp...')
end
cfg2            = [];
cfg2.method='pca';
comp           = ft_componentanalysis(cfg2, data);
% cfg3=[];
% cfg3.comp=1:20;
% cfg3.layout='4D248.lay';
% comppic=ft_componentbrowser(cfg3,comp);
[posrate,hbcomp]=max(abs(mean(1000*comp.topo(:,1:20)>0)));
display(['hb like component is pca ',num2str(hbcomp),' with ',num2str(round(100*posrate)),'% weights positive']);

if posrate>0.9
    figure;plot(comp.trial{1,1}(hbcomp,1:10172));
    HBchan=comp.trial{1,1}(hbcomp,:);
else
    warning(['maybe heart component wasn''','t found, leaving data as is']);
end
end
