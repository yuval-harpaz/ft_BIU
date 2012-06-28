function [chData,t]=chanDataByTrial(data,chan,timewin)
% makes a matrix of data for one channel.
% rows for trials, columns for sampls.
% data is fieldtrip data structure, unaveraged.
% chan = 'A191'; timewin=[0.12 0.17] (default for whole length)

if ~isfield(data,'trial')
    error('raw data with trials required');
end    
if exist('timewin','var')
    s1=nearest(data.time{1,1},timewin(1));
    s2=nearest(data.time{1,1},timewin(2));
else
    s1=1;
    s2=length(data.time{1,1});
end
[~,chi]=ismember(chan,data.label);
t=data.time{1,1}(1,s1:s2);
% reading the data
chData=data.trial{1,1}(chi,s1:s2);
for triali=2:length(data.trial)
    chData(triali,:)=data.trial{1,triali}(chi,s1:s2);
end