function win=getTwin(edges,wini)
% edges are edges of a histogram, equal time bins.
% wini is a vector of indices for bins with over threshold count of events.

sep=find(diff(wini)>1);
sepn=length(sep);
if ~isempty(wini)
    for sepi=0:sepn
        if sepi==0
            b=wini(1);
            if sepn==0;
                e=wini(end)+1;
            else
                e=wini(sep(sepi+1))+1;
            end
        else
            b=wini(sep(sepi)+1);
            if sepi==sepn
                e=wini(end)+1;
            else
                e=wini(sep(sepi+1)+1)+1;
            end
        end
        win(sepi+1,1:2)=edges([b e]);
    end
end