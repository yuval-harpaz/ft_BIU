function rewriteData(pat,source,newSource)
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
cfg.trialfun='trialfun_beg';
cfg1=[];
cfg1=ft_definetrial(cfg);
newData=ft_preprocessing(cfg1);
if isfield(newData,'trial')
    label=newData.label;
    newData=newData.trial{1,1};
end
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
write_data_block(pdf2, dataC, 1);
cd(PWD);
end