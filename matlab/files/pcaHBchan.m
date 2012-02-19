function [HBchan,irregular,period]=pcaHBchan(data,lat,bpfreq)
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
        if ~isempty(bpfreq)
            cfg1.bpfilter='yes';
            cfg1.bpfreq=bpfreq;
        end
    end
    data=ft_preprocessing(cfg1);
else
    warning ('needs name of original data file, c,rfhp... or ft one trial of the whole data')
    if length(data.trial)>1
        error('epoched data, needs raw data')
    end
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
irregular={};
%if posrate>0.9
    HBchan=comp.trial{1,1}(hbcomp,:);
    HBchan=(HBchan-median(HBchan))/std(HBchan);
    [pks,locs] = findpeaks(HBchan,'minpeakheight',3,'minpeakdistance',305);
    plot(HBchan);hold on;plot(locs,pks,'r*');xlim([0 101724/5]);title('first 50s')
    intervals=diff(locs);
    [i,fastHB]=find(intervals./data.hdr.Fs<0.5);
    irregular.fastHB=locs(fastHB+1);
    [i,slowHB]=find(intervals./data.hdr.Fs>1.7);
    irregular.slowHB=locs(slowHB+1);
    period=median(intervals)/data.hdr.Fs;
%else
    warning(['maybe heart component wasn''','t found, leaving data as is']);
%end
end
