function list=findMEGfileName(one)
!ls *c,* >list.txt
list=importdata('list.txt')
if ~exist('one','var')
    one=[];
end
if one==1;
    list=list{1,1};
end   
!rm list.txt
