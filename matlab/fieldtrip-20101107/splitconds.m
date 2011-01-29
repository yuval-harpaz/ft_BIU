function ndata=splitconds(cfg,data);

% cfg.cond = event code to extract

tloc = 't = data.cfg';
eval(tloc);

for i=1:100;
  if(isfield(t, 'trl'));
    str = [tloc,'.trl'];
    eval(str);
    break;
 else;
    tloc = [tloc, '.previous'];
    eval(tloc);
 end;
end;

if (i<100);
    x=find(t(:,4)==cfg.cond);
    ndata=data;
    ndata.trial=ndata.trial(x);
    ndata.time=ndata.time(x);
    ndata.cfg.trl=t(x,:);
else;
    error('no trl matrix found');
end;
