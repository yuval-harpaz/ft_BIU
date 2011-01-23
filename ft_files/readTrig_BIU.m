function trig=readTrig_BIU(source);
%% reads the trigger channel
pdf=pdf4D(source);
hdr=get(pdf,'header');
lastSamp=hdr.epoch_data{1,1}.pts_in_epoch;
chiT=channel_index(pdf,'TRIGGER','name');
trig = read_data_block(pdf,[0 lastSamp],chiT);
end