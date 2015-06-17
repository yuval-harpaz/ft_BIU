function [dip,R]=dipolefitBIU(cfg,data)
% dipole fit for fieldtrip structure data
% by default, makes single sphere vol from headshape
% please give cfg.latency (sec) or else!
% use cfg.symmetry    = 'y' for left-right symmetric dipole.
% note that coordinates here are in PRI order to fit the headshape
% if you use cfg.method = 'fieldtrip' you can use cfg options from
% ft_dipolefitting
R=[];
data.grad=ft_convert_units(data.grad,'mm');
if ~isfield(cfg,'method')
    cfg.method='fieldtrip';
end
if ~isfield(cfg,'vol')
    if exist('./hs_file','file')
        hs=ft_read_headshape('hs_file');
    elseif exist('1','dir')
        hs=ft_read_headshape('1/hs_file');
    else
        error('where is the bloody headshape?')
    end
    hs=hs.pnt*1000;
    [cfg.vol.o,cfg.vol.r]=fitsphere(hs);
    cfg.vol.type='singlesphere';
end
cfg.vol=ft_convert_units(cfg.vol,'mm');
if ~isfield(cfg,'grid')
    %[-120 120 -90 90 -20 150]
    cfg1=[];
    cfg1.grid.xgrid      =  -120:10:120; 
    cfg1.grid.ygrid      =  -90:10:90;
    cfg1.grid.zgrid      =  -20:10:150; 
    %cfg1.grid.pos        = pnt;
    %cfg1.grid.inside     = true(length(pnt),1);
    cfg1.vol=cfg.vol;
    if strcmp (cfg.vol.type,'singlesphere')
        cfg1.grid.ygrid=cfg1.grid.ygrid+cfg.vol.o(2); % for symmetry
    end
    cfg.grid=ft_prepare_leadfield(cfg1,data);
end
cfg.method=lower(cfg.method);
switch cfg.method
    case 'fieldtrip'
        if isfield(cfg,'symmetry')
            if ~isfield(cfg,'numdipoles')
                cfg.numdipoles = 2;
            end
        end
        if strcmp(cfg.vol.type,'singlesphere')
            % shift center of sphere to be at y=0
            offzero=cfg.vol.o(2);
            data.grad.chanpos(:,2)=data.grad.chanpos(:,2)-offzero;
            data.grad.coilpos(:,2)=data.grad.coilpos(:,2)-offzero;
            if isfield(cfg.grid,'zgrid');
                cfg.grid.zgrid=cfg.grid.zgrid-offzero;
            end
            if isfield(cfg.grid,'pos');
                cfg.grid.pos(:,2)=cfg.grid.pos(:,2)-offzero;
            end
            cfg.vol.o(2)=0;
            dip=ft_dipolefitting(cfg,data);
            dip.grad.chanpos(:,2)=dip.grad.chanpos(:,2)+offzero;
            dip.grad.coilpos(:,2)=dip.grad.coilpos(:,2)+offzero;
            dip.dip.pos(:,2)=dip.dip.pos(:,2)+offzero;
        else
            dip=ft_dipolefitting(cfg,data);
        end
    otherwise
        
        M=data.avg(:,nearest(data.time,cfg.latency(1)):nearest(data.time,cfg.latency(2)));
        
%         Mscale=max(abs(M))./10;
%         M=M./Mscale;
        if size(M,2)>1
            M=mean(M,2);
        end
        %Mrand=rand(size(M));
        %Mrand=(Mrand-0.5)*prctile(abs(M),25);
        
        source=zeros(length(cfg.grid.inside),3);
        goodness=zeros(length(cfg.grid.inside),1);
        if ~isfield(cfg,'symmetry')
            warning off; % because of '\' warnings
            for srci=[find(cfg.grid.inside)]';
                %
                switch cfg.method
                    case '\'
                        source(srci,1:3)=cfg.grid.leadfield{srci}\M;
                    case 'pinv' % identical to fieldtrip
                        source(srci,1:3)=pinv(cfg.grid.leadfield{srci})*M;
                    case '*'
                        source(srci,1:3)=cfg.grid.leadfield{srci}'*M;
                end
                goodness(srci)=corr(M,(source(srci,:)*cfg.grid.leadfield{srci}')').^2;
            end
            [~,maxi]=max(goodness);
            warning on
            dip=[];
            dip.label=data.label;
            dip.dip.pos=cfg.grid.pos(maxi,:);
            dip.Vdata=M;
            dip.Vmodel=[source(maxi,:)*cfg.grid.leadfield{maxi}']';
            dip.time=cfg.latency;
            dip.dimord=data.dimord;
            dip.dip.mom=source(maxi,:)';
            dip.leadfield{1,1}=cfg.grid.leadfield{maxi};
            dip.grid_index=maxi;
            R=goodness;
        else
            % for single sphere only
            left=find(cfg.grid.pos(:,2)>cfg.vol.o(2));
            srcL=zeros(length(left),3);
            srcR=srcL;noiseL=srcL;noiseR=srcL;
            right=[];
            for lefti=1:length(left)
                logi1=cfg.grid.pos(:,1)==cfg.grid.pos(left(lefti),1);
                logi2=cfg.grid.pos(:,2)==2*cfg.vol.o(2)-cfg.grid.pos(left(lefti),2);
                logi3=cfg.grid.pos(:,3)==cfg.grid.pos(left(lefti),3);
                right(lefti)=find((logi1+logi2+logi3)==3);
            end
            inside=false(size(cfg.grid.inside));
            inside(left)=true;
            inside(right)=true;
            inside(~cfg.grid.inside)=false;
            warning off
            for srci=1:length(left);
                if ~right(srci)==0
                    lefti=left(srci);
                    righti=right(srci);
                    lfl=cfg.grid.leadfield{lefti};
                    lfr=cfg.grid.leadfield{righti};
                    if ~isempty(lfl) && ~isempty(lfr)
                        for coli=1:3
                            tmp=[lfl(:,coli),lfr(:,coli)]\M;
                            srcL(srci,coli)=tmp(1);
                            srcR(srci,coli)=tmp(2);
                        end
                        [~,gof]=fit(M,(srcL(srci,:)*lfl'+srcR(srci,:)*lfr')','poly1');
                        goodness(lefti)=corr(M,(srcL(srci,:)*lfl'+srcR(srci,:)*lfr')').^2;
                        goodness(righti)=goodness(lefti);
                    end
                end
            end
            src=srcL+srcR;
            src(:,2)=srcL(:,2)-srcR(:,2);
            %ns=noiseL+noiseR;
            %ns(:,2)=noiseL(:,2)-noiseR(:,2);
            source(left,1:3)=srcL;
            source(right,1:3)=srcR;
            %noise(left,1:3)=ns;
            %noise(right,1:3)=ns;
            dist=sqrt(sum((cfg.grid.pos-repmat(cfg.vol.o,size(source,1),1)).^2,2));
            %noise=sqrt(sum(randNoise'.^2));
            %mom=sqrt(sum(source'.^2));
            %NS=sqrt(sum(noise.^2,2));
%             figure;plot3pnt(hs,'.k');hold on;
%             scatter3pnt(cfg.grid.pos(inside,:),[],...
%                 goodness(inside))
            [~,maxi]=max(goodness(left));
            lfl=cfg.grid.leadfield{left(maxi)};
            lfr=cfg.grid.leadfield{right(maxi)};
            dip=[];
            dip.label=data.label;
            dip.dip.pos=[cfg.grid.pos(left(maxi),:);cfg.grid.pos(right(maxi),:)];
            dip.Vdata=M;
            dip.Vmodel=(srcL(maxi,:)*lfl'+srcR(maxi,:)*lfr')';
            dip.time=cfg.latency;
            dip.dimord=data.dimord;
            dip.dip.mom=[srcL(maxi,:)';srcR(maxi,:)'];
            dip.leadfield{1,1}=lfl;
            dip.leadfield{1,2}=lfr;
            dip.grid_index=[left(maxi),right(maxi)];
            R=goodness;
        end
end



% documenting the non linear fit stage (dipole_fit.m) if you choose
% nonlinear in ft_dipolefitting you can use the output dip as input for
% dipole_fit like this:
% % constr.fixedori   = boolean, keep dipole orientation fixed over whole data window
% % constr.rigidbody  = boolean, keep relative position of multiple dipoles fixed
% constr=[];
% constr.reduce=[1 2 3];
% constr.expand=[1 2 3 1 2 3];
% constr.mirror=[1 1 1 1 -1 1];
% constr.symmetry=true; % redundant, may skip this line
% dip1=[];
% dip1.pos=dip.dip.pos;
% dip1.mom=zeros(3,2);
% dip = dipole_fit(dip1, data.grad, vol, data.avg(:,nearest(data.time(cfg.latency(1)):data.time(cfg.latency(1)))), 'constr',constr);


