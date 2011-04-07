function rindxd=reindex(orig,new);

% restores columns from original trl but using only trials in new trl
% use:    rindxd = reindex(origcfg.trl,newcg.trl);

rindxd=orig(ismember(orig(:,1),new(:,1)),:);

