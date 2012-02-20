function rewriteData2to1k(pat,source,newSource)
PWD=pwd;
%patient='b105';
if ~exist('pat','var')
    error('specify the path to the data')
end
if ~exist('source','var')
    source=[];
end
if isempty(source)
    source='c,rfhp0.1Hz';
end
cd (pat);
cfg.dataset=newSource;
%cfg.trialdef.poststim=2;
cfg.trialfun='trialfun_raw';


trig=readTrig_BIU(newSource);
trigC=clearTrig(trig);%DomBlock=find(trigC==14);
m1=[];
m1(1,1)=max(find(trigC==14));
m1(1,2)=max(find(trigC==16));
endDom=max(max(m1))+6000;
begDom=find(trigC==12,1)-6000;
m1=[];
m1(1,1)=max(find(trigC==24));
m1(1,2)=max(find(trigC==26));
endSub=max(max(m1))+6000;
begSub=find(trigC==22,1)-6000;
cfg.trialdef.beginning=begDom/1017.25/2;
cfg.trialdef.end=endDom/1017.25/2;


cfg1=[];
cfg1=ft_definetrial(cfg);
newData=ft_preprocessing(cfg1);
if isfield(newData,'trial')
    label=newData.label;
    newData=newData.trial{1,1};
end
downsampvec=1:length(newData);
odds=~iseven(downsampvec);
newData=newData(:,find(odds));
newFile=['rw_',newSource];
eval(['!cp ',source,' ',newFile])
pdf=pdf4D(source);
pdf2=pdf4D(newFile);
chi = channel_index(pdf, {'meg' 'ref' 'TRIGGER' 'RESPONSE' 'UACurrent' 'eeg' 'EXTERNAL'}, 'name');
hdr = get(pdf,'header');
lat = [1 hdr.epoch_data{1,1}.pts_in_epoch];
chn = channel_name(pdf, chi);
data = read_data_block(pdf, lat, chi);
% load /home/yuval/Data/BF4clinic/files/hybrid/sagit
% load dataS
% dataS=dataS(:,1:67817);
dataC=data;
for i=1:273
    dataC(chi(i),1:size(newData,2))=newData(find(strcmp((chn(i)),label)),:);
end
% for i=249:length(chi)
%     dataC(chi(i),:)=data(i,:);
% end

% for i=1:size(chi,2)
%     dataC(chi(i),:)=data(i,:);
% end
% for i=1:size(chiS,2)
%     dataicaC(chiS(i),:)=dataica(i,:);
% end
% hybrid=dataC;
% hybrid(1:274,:)=dataC(1:274,:)+dataicaC;
display('writing dominant')
pat
write_data_block(pdf2, dataC, 1);

%% sub


cfg.trialdef.beginning=begSub/1017.25/2;
cfg.trialdef.end=endSub/1017.25/2;


cfg1=[];
cfg1=ft_definetrial(cfg);
newData=ft_preprocessing(cfg1);
if isfield(newData,'trial')
    label=newData.label;
    newData=newData.trial{1,1};
end
downsampvec=1:length(newData);
odds=~iseven(downsampvec);
newData=newData(:,find(odds));
newFile=['rwS_',newSource];
eval(['!cp ',source,' ',newFile])
%pdf=pdf4D(source);
pdf2=pdf4D(newFile);
%chi = channel_index(pdf, {'meg' 'ref' 'TRIGGER' 'RESPONSE' 'UACurrent' 'eeg' 'EXTERNAL'}, 'name');
%hdr = get(pdf,'header');
%lat = [1 hdr.epoch_data{1,1}.pts_in_epoch];
%chn = channel_name(pdf, chi);
%data = read_data_block(pdf, lat, chi);
% load /home/yuval/Data/BF4clinic/files/hybrid/sagit
% load dataS
% dataS=dataS(:,1:67817);
dataC=data;
for i=1:273
    dataC(chi(i),1:size(newData,2))=newData(find(strcmp((chn(i)),label)),:);
end
% for i=249:length(chi)
%     dataC(chi(i),:)=data(i,:);
% end

% for i=1:size(chi,2)
%     dataC(chi(i),:)=data(i,:);
% end
% for i=1:size(chiS,2)
%     dataicaC(chiS(i),:)=dataica(i,:);
% end
% hybrid=dataC;
% hybrid(1:274,:)=dataC(1:274,:)+dataicaC;
display('writing subordinate')
pat
write_data_block(pdf2, dataC, 1);
%!mkdir ../3
% !mv rwS_c,rfhp1.0Hz ../3/rw_c,rfhp0.1Hz
% !cp config ../3/
% !cp hs_file ../3/

cd(PWD);
end