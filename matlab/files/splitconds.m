function ndata=splitconds(cfg,data)

% cfg.cond = event code to extract

tloc = 't = data.cfg';
eval(tloc);

for i=1:100;
    if isfield(t, 'trl') && size(t.trl,2)<4;
        t=rmfield(t,'trl');
    end
    if(isfield(t, 'trl'));
        str = [tloc,'.trl'];
        eval(str);
        break;
    else
        tloc = [tloc, '.previous']; %#ok<AGROW>
        eval(tloc);
    end;
end;

if (i<100);
    % x=find(t(:,4)==cfg.cond);
    ndata=rmfield(data,'trial');
    ndata.cfg=rmfield(ndata.cfg,'trl');
    ndata=rmfield(ndata,'time');
    cnt=1;
    for i=1:size(t,1);
        if ~isempty(find(data.cfg.trl==t(i,1))) && t(i,4)==cfg.cond; %#ok<EFIND>
            ti=find(data.cfg.trl==t(i,1));
            ndata.cfg.trl(cnt,1:size(t,2))=t(i,:);
            ndata.trial{1,cnt}=data.trial{1,ti};
            ndata.time{1,cnt}=data.time{1,ti};
            cnt=cnt+1;
        end

    end
    %ndata.time=ndata.time(x);
    %ndata.cfg.trl=t(x,:);
else
    error('no trl matrix found');
end;
