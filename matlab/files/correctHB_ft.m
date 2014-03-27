function [cleanData,temp2e,period2,ECG,Rtopo]=correctHB_ft(fileName,figs);%rawData,sRate,ecg)

% fileName='c,rfhp0.1Hz';
% figs=false;

% FIXME look for bad channels
if ~exist('figs','var')
    figs=[];
end
if isempty(figs)
    figs=false;
end
minPeriod=0.45;
maxPeriod=1.5;
%% read data
cfg=[];
cfg.dataset=fileName;
cfg.channel='MEG';
cfg.bpfilter='yes';
cfg.bpfreq=[5 35];
cfg.demean='yes';
dataFilt=ft_preprocessing(cfg);
sRate=dataFilt.fsample;
sampBefore=round(sRate*maxPeriod);
%% peak detection on ECG like signal
meanMEG=mean(dataFilt.trial{1,1});
% look for jump
zMEG=(meanMEG-mean(meanMEG))./std(meanMEG);
jbeg=find(abs((zMEG))>5,1);
bads=[];
if ~isempty(jbeg)
    jend=find(abs((zMEG))>5,1,'last');
    bads=(jbeg-round(sRate./2)):(jend+round(sRate./2));
    if length(bads)>sRate*3
        error(['jump? what"s the noise at ',num2str(jbeg./sRate),'s ?']);
    else
        meanMEG(bads)=0;
        dataFilt.trial{1,1}(:,bads)=0;
        warning(['jump? what"s the noise at ',num2str(jbeg./sRate),'s ?']);
    end
end

[peaks, Ipeaks]=findPeaks(meanMEG,1.5,round(dataFilt.fsample*minPeriod)); % 450ms interval minimum
if figs
    figure;
    plot(meanMEG)
    hold on
    plot(Ipeaks, peaks,'ro')
end
%% get topography

topo={};
topo.avg=median(dataFilt.trial{1,1}(:,Ipeaks),2);
topo.time=0;
topo.label=dataFilt.label;
topo.dimord='chan_time';
if figs
    cfg=[];
    cfg.layout='4D248.lay';
    cfg.interpolation='linear';
    cfg.xlim=[1,1];
    figure;
    ft_topoplotER(cfg,topo);
end

topoTrace=topo.avg'*dataFilt.trial{1,1}-median(topo.avg'*dataFilt.trial{1,1});
topoTraceN=topoTrace./max(topoTrace(1:round(sRate*10)));
meanMEGN=meanMEG./max(meanMEG(1:round(sRate*10)));

%% check if topo of every peak is correlated to average topo
r=corr(dataFilt.trial{1,1}(:,Ipeaks),topo.avg);
if figs
    figure;
    plot(topoTraceN)
    hold on
    plot(meanMEGN,'r')
    plot(Ipeaks(r>0.5),r(r>0.5),'g.');
    legend('topoTrace','meanMEG','r data-topo > 0.5')
end
%% average good HB and make a template
IpeaksR=Ipeaks(r>0.5);
IpeaksR=IpeaksR(IpeaksR>sampBefore);
IpeaksR=IpeaksR(IpeaksR<(length(dataFilt.time{1,1})-sampBefore));

[temp1e,period1]=makeTempHB(mean(dataFilt.trial{1,1}),sRate,IpeaksR,minPeriod/0.6,sampBefore,figs);
%% find xcorr between template and meanMEG
[xcr,lags]=xcorr(meanMEG,temp1e);
% figure;
% plot(lags,xcr);
xcr=xcr(lags>=0);
lags=lags(lags>=0);
[~,tempMax]=max(temp1e);
%xr(length(t)+1:end)=x(1:end-length(t));

xcrPad=zeros(size(meanMEG));

xcrPad(tempMax:end)=xcr(1:end-tempMax+1);
% figure;
% plot(meanMEGN);
% hold on
% plot(xcrPad/max(xcrPad),'r');
if figs
    figure;
    plot(topoTraceN)
    hold on
    plot(meanMEGN,'r')
    plot(xcrPad/max(xcrPad),'g');
    legend('topoTrace','meanMEG','temp xcorr')
end
%% second sweep
% find peaks on xcorr trace
[peaks2, Ipeaks2]=findPeaks(xcrPad,1.5,round(sRate*period1*0.6)); % no peaks closer than 60% of period
if figs
    figure;
    plot(xcrPad)
    hold on
    plot(Ipeaks2, peaks2,'ro')
end
% read unfiltered data
cfg=[];
cfg.dataset=fileName;
cfg.channel='MEG';
cfg.demean='yes';
data=ft_preprocessing(cfg);
Ipeaks2in=Ipeaks2(Ipeaks2>sampBefore);
Ipeaks2in=Ipeaks2in(Ipeaks2in<(length(dataFilt.time{1,1})-sampBefore));
meanMEG=mean(data.trial{1,1});
if ~isempty(bads)
    zMEG=(meanMEG-mean(meanMEG))./std(meanMEG);
    jend=find(abs(zMEG)>5,1,'last');
    bads=(jbeg-round(sRate./2)):(jend+round(sRate./2));
    meanMEG(bads)=0;
end
[temp2e,period2]=makeTempHB(meanMEG,sRate,Ipeaks2in,period1,sampBefore,figs);
% FIXME reject bad SNR HB from averaging

% make ecg trace for meanMEG

% test R amplitude
meanMEGdt=detrend(meanMEG,'linear',round(sRate:sRate:length(meanMEG)));
[~,maxi]=max(temp2e(1:round(length(temp2e/2))));
bef=find(flipLR(temp2e(1:maxi))<0,1)-1;
aft=find(temp2e(maxi:end)<0,1)-1;
Rlims=[maxi-bef,maxi+aft]; % check where R pulls the template above zero

% ampMM=meanMEGdt(Ipeaks2in)./temp2e(maxi);
% mmSm=smooth(meanMEGdt,10);
% tSm=smooth(temp2e,10);
% ampMMsm=mmSm(Ipeaks2in)./tSm(maxi);
for HBi=1:length(Ipeaks2in);
    s0=Ipeaks2in(HBi)-bef;
    s1=Ipeaks2in(HBi)+aft;
    p(HBi,1:2)=polyfit(temp2e(Rlims(1):Rlims(2)),meanMEGdt(s0:s1),1);
end
negp=find(p(:,1)<0);
if ~isempty(negp)
    p(negp,1:2)=0;
end
ampMMfit=p(:,1)+(p(:,2)./temp2e(maxi));

ECG=makeECG(temp2e,Rlims,Ipeaks2in,ampMMfit,length(meanMEG));
% figure;
% plot(meanMEGdt,'r')
% hold on
% plot(ECG)
% legend('detrended meanMEG','line fit amp ECG')


%% remove ecg from each chan


maxi
sBef=maxi-1;
sAft=length(temp2e)-maxi;
HBtemp=HBbyChan(data.trial{1,1},sRate,Ipeaks2in,period2,sBef,sAft);
% FIXME check poor SNG chans on chan temp
ECGall=makeECGbyCh(HBtemp,Rlims,Ipeaks2in,ampMMfit,length(meanMEG),maxi);

cleanData=data.trial{1,1}-ECGall;
figure;
plot(ECG,'k')
hold on
plot(meanMEG,'r')
plot(mean(cleanData),'g')
legend('ECG from template', 'mean MEG','mean clean MEG')
Rtopo=HBtemp(:,maxi);
topo={};
topo.avg=Rtopo;%median(dataFilt.trial{1,1}(:,Ipeaks),2);
topo.time=0;
topo.label=dataFilt.label;
topo.dimord='chan_time';
cfg=[];
cfg.layout='4D248.lay';
cfg.interpolation='linear';
cfg.xlim=[1,1];
cfg.zlim=[-max(abs(Rtopo)) max(abs(Rtopo))];
figure;
ft_topoplotER(cfg,topo);
title ('TOPOGRAPHY OF R')

% FIXME check missing / extra HB

function [tempe,period2]=makeTempHB(trace,sRate,peakIndex,period,sampBefore,figs)
betweenHBs=0.7; % after the T wave, before next qrs, 0.7 of period
HB=zeros(size(trace,1),sampBefore*2+1);
for epochi=1:length(peakIndex)
    HB=HB+trace(:,peakIndex(epochi)-sampBefore:peakIndex(epochi)+sampBefore);
end
HB=HB/epochi;
period2=[];

HBxc=xcorr(HB);
% FIXME admit defeat for yoni
[~,ipxc]=findPeaks(HBxc,1.5,sRate*period*0.6); % index peak xcorr
if length(ipxc)>1
    period2=(ipxc(length(ipxc)/2+0.5)-ipxc(length(ipxc)/2-0.5))/sRate;
else
    HBxc1=xcorr(trace,HB);
    [~,ipxc]=findPeaks(HBxc1,1.5,sRate*period*0.6); % index peak xcorr
    
    period2=median(diff(ipxc))/sRate;
end

display(['HB period (2nd sweep) is ',num2str(period2),'s']);

temp=HB(sampBefore-round(sRate*(1-betweenHBs)*period2):sampBefore+round(sRate*betweenHBs*period2));
edgeRepressor=ones(size(temp));
ms20=round(sRate/50);
reducVec=[0:1/ms20:1];
reducVec=reducVec(1:end-1);
edgeRepressor(1:length(reducVec))=reducVec;
edgeRepressor(end-length(reducVec)+1:end)=flipLR(reducVec);
tempe=temp-median(temp);
tempe=tempe.*edgeRepressor;
if figs
    figure;
    plot(temp);
    hold on
    plot(tempe,'g')
    legend('template HB','zero edge HB')
end

function ECG=makeECG(temp,Rlims,Ipeaks,amp,lengt)
ECG=zeros(1,lengt);
[~,maxTemp]=max(temp(1:round(length(temp/2))));
% bef=find(flipLR(temp(1:maxTemp))<0,1)-1;
% aft=find(temp(maxTemp:end)<0,1)-1;
% Rlims=[maxTemp-bef,maxTemp+aft];

for HBi=1:length(Ipeaks);
    s0=Ipeaks(HBi)-maxTemp+1;
    s1=Ipeaks(HBi)+length(temp)-maxTemp;
    ECG(s0:s1)=temp;
    ECG(s0+Rlims(1)-1:s0+Rlims(2)-1)=temp(Rlims(1):Rlims(2))*amp(HBi);
end
function tempe=HBbyChan(trace,sRate,peakIndex,period,sampBefore,sampAfter)
betweenHBs=0.7; % after the T wave, before next qrs, 0.7 of period
HB=zeros(size(trace,1),sampBefore+1+sampAfter);
for epochi=1:length(peakIndex)
    HB=HB+trace(:,peakIndex(epochi)-sampBefore:peakIndex(epochi)+sampAfter);
end
HB=HB/epochi;
edgeRepressor=ones(1,size(HB,2));
ms20=round(sRate/50);
reducVec=[0:1/ms20:1];
reducVec=reducVec(1:end-1);
edgeRepressor(1:length(reducVec))=reducVec;
edgeRepressor(end-length(reducVec)+1:end)=flipLR(reducVec);
tempe=HB-median(HB([1:ms20,end-ms20:end]));
tempe=tempe.*repmat(edgeRepressor,size(HB,1),1);
function ECG=makeECGbyCh(temp,Rlims,Ipeaks,amp,lengt,maxTemp)
ECG=zeros(size(temp,1),lengt);
for HBi=1:length(Ipeaks);
    s0=Ipeaks(HBi)-maxTemp+1;
    s1=Ipeaks(HBi)+length(temp)-maxTemp;
    ECG(:,s0:s1)=temp;
    ECG(:,s0+Rlims(1)-1:s0+Rlims(2)-1)=temp(:,Rlims(1):Rlims(2))*amp(HBi);
end

