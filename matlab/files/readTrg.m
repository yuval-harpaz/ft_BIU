function events=readTrg(eegFileName)
if ~exist('eegFileName','var')
    eegFileName=ls('*.cnt');
end
dotN=findstr('.',eegFileName);
FNnoSuf=eegFileName(1:dotN-1);
fid = fopen([FNnoSuf,'.trg']);
tline = fgets(fid);
counter=0;
while ischar(tline)
    counter=counter+1;
    %disp(tline)
    num=str2num(tline);
    events(counter,1:length(num))=num;
    tline = fgets(fid);
end
fclose(fid);