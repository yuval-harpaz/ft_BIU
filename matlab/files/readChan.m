function data=readChan(source,chan)
%% reads the trigger channel
% data=readTrig_BIU('c,rfhp0.1Hz','X3')
pdf=pdf4D(source);
hdr=get(pdf,'header');
lastSamp=hdr.epoch_data{1,1}.pts_in_epoch;
chiT=channel_index(pdf,chan,'name');
data = read_data_block(pdf,[0 lastSamp],chiT);
end
