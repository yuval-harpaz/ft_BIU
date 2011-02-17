function rewriteTrig(source,trig,prefix,badChans)
% rewriting the trigger channel
% must cd to the directory where the file is
% trig can be 0 or a vector the same length as the data.
destination=[prefix,'_',source]; %tf for trigger fixed
display(['copying; new file named ',destination]);
copyfile(source,destination);
%pdf=pdf4D(source);
display('reading header');
pdf1=pdf4D(destination);
%dr=get(pdf1,'dr');
T1=0;
hdr=get(pdf1,'header');
T2=hdr.epoch_data{1,1}.epoch_duration;
S2=hdr.epoch_data{1,1}.pts_in_epoch;
if size(trig,2)==1; if trig==0;trig=zeros(1,S2);end;end;
if size(trig,2)~=S2; error('length of trig is different than file length');end
chi = channel_index(pdf1, {'meg' 'ref' 'TRIGGER' 'RESPONSE' 'UACurrent'...
    'eeg' 'external'}, 'name');%% add external
chiT=channel_index(pdf1,'TRIGGER','name');
% lastSamp=hdr.epoch_data{1,1}.pts_in_epoch;


%% writing a new file
T1E=0;
splits=(T2-T1)/100;% preparing to splits the data to groups of 100s
for i=1:ceil(splits)
    if ceil(splits)==1;
        T1E=T1;
        T2E=T2;
    elseif i<ceil(splits)
        T2E=i*100;
        T1E=T2E-100;
    else
        T1E=T1E+100;
        T2E=T2;
    end
    latE=lat2ind(pdf1, 1, [T1E T2E]);
    data = read_data_block(pdf1,latE,chi);
    dataC=nan(size(data));
    trigE=trig(latE(1):latE(2));
    % data(channel_index(pdf,'TRIGGER','name'),:)=trigE;
    for in=1:size(chi,2)
        dataC(chi(in),:)=data(in,:);
    end
    dataC(channel_index(pdf1,'TRIGGER','name'),:)=trigE;
    if exist ('badChans')
        if isempty('badChans')==0;
            for j=1:size(badChans,2);
                bch=['A',num2str(badChans(1,j))];
                dataC(channel_index(pdf1,bch,'name'),:)=zeros(size(dataC(1,:)));
                if i==1; display(['replacing ',bch,' with zeros']); end;
            end
        end
    end
    write_data_block(pdf1, dataC, latE(1));
    display(['wrote section ',num2str(i),' of ',num2str(ceil(splits))]);
end
lat=lat2ind(pdf1,1,[T1 T2]);
trigD=read_data_block(pdf1,lat,chiT);
figure;plot(trigD);
title('TRIGGER on NEW file');