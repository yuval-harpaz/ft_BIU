function rewriteSource(patient,pat,source)
PWD=pwd;
%patient='b105';
if ~exist('pat','var')
    pat='/home/yuval/Data/tel_hashomer';
end
if ~exist('source','var')
    source='c,rfhp0.1Hz';
end
cd (pat);
cd(patient);
if ~exist('dataica','var')
    load noICA8_raw
end
if isfield(dataica,'trial')
    label=dataica.label;
    dataica=dataica.trial{1,1};
end
eval(['!cp ',source,' no8_c,rfhp0.1Hz'])
pdf=pdf4D(source);
pdf2=pdf4D('no8_c,rfhp0.1Hz');
chi = channel_index(pdf, {'meg' 'ref' 'TRIGGER' 'RESPONSE' 'UACurrent' 'eeg' 'EXTERNAL'}, 'name');
hdr = get(pdf,'header');
lat = [1 hdr.epoch_data{1,1}.pts_in_epoch];
chn = channel_name(pdf, chi);
data = read_data_block(pdf, lat, chi);
% load /home/yuval/Data/BF4clinic/files/hybrid/sagit
% load dataS
% dataS=dataS(:,1:67817);
for i=1:248
    dataC(chi(i),:)=dataica(find(strcmp((chn(i)),label)),:);
end
for i=249:length(chi)
    dataC(chi(i),:)=data(i,:);
end

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