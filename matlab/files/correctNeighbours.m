function [neighbours]=correctNeighbours(neighbours, ch2rem)
% the input "neighnours" is the output structure of ft_prepare_neighbours
% (a structure the contain the labels of each channels, and which are its
% neighbours' labels)
% the input ch2rem is cell array of the channels you'd like to remove from neighbours
% structure. Each cell contains a string with one channel label.
% ch2rem={'A204' 'A74'} etc...
userAns=1;
if size(neighbours,2)~=248
    disp(['The use in ft_prepare_neighbours with data in which channel/s were removed might'...
        ' result in incorrect neighbours devision.']);
    userAns=input('Would you like to continue (=1) or call this function again with a new neighbours structure(=2)? \n');
end
if userAns~=1
    return
end
fields2del=nan(1,length(ch2rem));
for chCounter=1:length(ch2rem)
    for index=1:size(neighbours,2)
        if strcmpi(neighbours(1,index).label, ch2rem(chCounter))
            fields2del(chCounter)=index;
        else
            checkNei=strcmpi(neighbours(1,index).neighblabel, ch2rem(chCounter));
            if sum(checkNei)>0
                neighbours(1,index).neighblabel(checkNei)=[];
            end
        end
    end
end
neighbours(fields2del)=[];
end
