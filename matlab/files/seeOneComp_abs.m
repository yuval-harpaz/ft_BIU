function badTrials=seeOneComp(comp_dummy)
% This function gets the components data from the ICA (comp_dummy)
comp=input('Which component would you like to check now?');
m=zeros(length(comp_dummy.trial),length(comp_dummy.time{1,1}));
for i=1:length(comp_dummy.trial)
m(i,:)=comp_dummy.trial{1,i}(comp,:);
end;
figure;mesh(m)
xlabel('Time resampled (X)')
ylabel('Trials (Y)')
eval(['title(''comp: ',num2str(comp),''')'])
cut = input('Do you want to enter a cutoff? [1 - yes ; 0 - no] \n');
if cut == 1
    cutOff=input('What is the abs cutoff (for example 1*10^(-13))? \n');
    for i=1:size(m,1)
        if sum(abs(m(i,:))>cutOff)>0
            remTrial(i)=1;
        end
    end
    badTrials=find(remTrial==1);
%    disp(['trials above threshold limitis are saved in BadTrials']);
    n=length(badTrials);
    disp(['number of trials above or below threshold: ',num2str(n)]);
else
    badTrials=[];
end