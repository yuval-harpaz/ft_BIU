function [dip,R,mom]=dipolefitBIU(cfg,data)
% dipole fit for fieldtrip structure data
% by default, makes single sphere vol from headshape
% please give cfg.latency (sec) or else!
% use cfg.symmetry    = 'y' for left-right symmetric dipole.
% note that coordinates here are in PRI order to fit the headshape
% if you use cfg.method = 'fieldtrip' you can use cfg options from
% ft_dipolefitting
%
% dip is ft_structure for dipole
% R is the map of R distribution, sort of source localization image
% mom is the direction of each dipole in R (symmetric)
R=[];
if isfield(cfg,'grid') && isfield(cfg,'vol') && isfield(cfg,'ori')
    fixedOri=true;
else
    fixedOri=false;
end
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
else
    if isfield(cfg.vol,'type')
        if ~strcmp(cfg.vol.type,'singlesphere')
            error ('only singlesphere type is possible for now')
        end
    else
        if sum(size(cfg.vol.o)==[1,3])==2 && length(cfg.vol.r)==1
            cfg.vol.type='singlesphere';
        end
    end
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
    cfg1.grid.ygrid=cfg1.grid.ygrid+cfg.vol.o(2); % for symmetry
    cfg.grid=ft_prepare_leadfield(cfg1,data);
end
mom=zeros(length(cfg.grid.inside),3);

if fixedOri % find dipole based on anatomically difined location and orientation points
    t=nearest(data.time,cfg.latency(1)):nearest(data.time,cfg.latency(2));
    M=data.avg(:,t);
    if size(M,2)>1
        M=mean(M,2);
    end
    for srci=1:length(cfg.ori);
        gain=cfg.grid.leadfield{srci}*cfg.ori(srci,:)';
        R(srci,1)=corr(gain,M).^2;
        mom(srci,1:3)=gain'*M*cfg.ori(srci,:);
    end
    [~,maxi]=max(R);
    dip=[];
    dip.label=data.label;
    dip.dip.pos=cfg.grid.pos(maxi,:);
    dip.Vdata=M;
    dip.Vmodel=cfg.grid.leadfield{maxi}*mom(maxi,:)';
    dip.time=cfg.latency;
    dip.dimord=data.dimord;
    dip.dip.mom=mom(maxi,:)';
    dip.leadfield{1,1}=cfg.grid.leadfield{maxi};
    dip.grid_index=maxi;
    dip.dip.rv=sum((dip.Vdata-dip.Vmodel).^2) ./ sum(dip.Vdata.^2);
    dip.dip.pot=dip.Vmodel;
else
    
    cfg.method=lower(cfg.method);
    switch cfg.method
        case 'fieldtrip'
            if isfield(cfg,'symmetry')
                if ~isfield(cfg,'numdipoles')
                    cfg.numdipoles = 2;
                end
            end
            dip=ft_dipolefitting(cfg,data);
        otherwise
            
            t=nearest(data.time,cfg.latency(1)):nearest(data.time,cfg.latency(2));
            M=data.avg(:,t);
            if size(M,2)>1
                M=mean(M,2);
            end
            if length(M)>length(cfg.grid.label)
                [~,chi]=ismember(cfg.grid.label,data.label);
                M=M(chi);
            end
            
            goodness=zeros(length(cfg.grid.inside),1);
            if ~isfield(cfg,'symmetry')
                cfg.symmetry='no';
            end
            if strcmp(cfg.symmetry,'no')
                warning off; % because of '\' warnings
                for srci=[find(cfg.grid.inside)]';
                    switch cfg.method
                        case '\'
                            mom(srci,1:3)=cfg.grid.leadfield{srci}\M;
                        case 'pinv' % identical to fieldtrip
                            mom(srci,1:3)=pinv(cfg.grid.leadfield{srci})*M;
                        case '*'
                            mom(srci,1:3)=cfg.grid.leadfield{srci}'*M;
                    end
                    goodness(srci)=corr(M,(mom(srci,:)*cfg.grid.leadfield{srci}')').^2;
                end
                [~,maxi]=max(goodness);
                warning on
                dip=[];
                dip.label=data.label;
                dip.dip.pos=cfg.grid.pos(maxi,:);
                dip.Vdata=M;
                dip.Vmodel=cfg.grid.leadfield{maxi}*mom(maxi,:)';
                dip.time=cfg.latency;
                dip.dimord=data.dimord;
                dip.dip.mom=mom(maxi,:)';
                dip.leadfield{1,1}=cfg.grid.leadfield{maxi};
                dip.grid_index=maxi;
                dip.dip.rv=sum((dip.Vdata-dip.Vmodel).^2) ./ sum(dip.Vdata.^2);
                dip.dip.pot=dip.Vmodel;
                R=goodness;
                dip.cfg=cfg;
            else
                % find left-right grid pairs
                
                [left,right,inside]=findLRpairs(cfg.grid,cfg.vol);
                %             left=find(cfg.grid.pos(:,2)>cfg.vol.o(2));
                %
                %             right=[];
                %             for lefti=1:length(left)
                %                 logi1=cfg.grid.pos(:,1)==cfg.grid.pos(left(lefti),1);
                %                 logi2=abs(cfg.grid.pos(:,2)-(2*cfg.vol.o(2)-cfg.grid.pos(left(lefti),2)))<1e-10;
                %                 logi3=cfg.grid.pos(:,3)==cfg.grid.pos(left(lefti),3);
                %                 try
                %                     right(lefti)=find((logi1+logi2+logi3)==3);
                %                 catch
                %                     error(['cannot find a right pair for grid index ',num2str(left(lefti))]);
                %                 end
                %             end
                %             inside=false(size(cfg.grid.inside));
                %             inside(left)=true;
                %             inside(right)=true;
                %             inside(~cfg.grid.inside)=false;
                srcL=zeros(length(left),3);
                srcR=srcL;
                mom=zeros(size(cfg.grid.pos));
                warning off
                for srci=1:length(left);
                    if ~right(srci)==0
                        lefti=left(srci);
                        righti=right(srci);
                        lfl=cfg.grid.leadfield{lefti};
                        lfr=cfg.grid.leadfield{righti};
                        if ~isempty(lfl) && ~isempty(lfr)
                            %                         for coli=1:3
                            %                             switch cfg.method
                            %                                 case '\' % same as pinv for symmetric
                            %                                     tmp=[lfl(:,coli),lfr(:,coli)]\M;
                            %                                 case 'pinv'
                            %                                     tmp=pinv([lfl(:,coli),lfr(:,coli)])*M;
                            %                                 case '*'
                            %                                     tmp=[lfl(:,coli),lfr(:,coli)]'*M;
                            %                             end
                            %                             srcL(srci,coli)=tmp(1);
                            %                             srcR(srci,coli)=tmp(2);
                            %                         end
                            
                            switch cfg.method
                                case '\' % same as pinv for symmetric
                                    tmp=[lfl(:,:),lfr(:,:)]\M;
                                case 'pinv'
                                    tmp=pinv([lfl(:,:),lfr(:,:)])*M;
                                case '*'
                                    tmp=[lfl(:,:),lfr(:,:)]'*M;
                            end
                            srcL(srci,1:3)=tmp(1:3);
                            srcR(srci,1:3)=tmp(4:6);
                            
                            L=srcL(srci,:);
                            R=srcR(srci,:);
                            LL=L-abs(R)./sum(abs([R;L])).*(L-R);
                            RR=LL;
                            LL(2)=L(2)-abs(R(2))./sum(abs([R(2);L(2)])).*(L(2)+R(2));
                            RR(2)=-LL(2);
                            scale=mean(abs(LL));
                            LL=LL./scale;
                            RR=RR./scale;
                            lfL=lfl*LL';
                            lfR=lfr*RR';
                            switch cfg.method
                                case '\' % same as pinv for symmetric
                                    tmp=[lfL,lfR]\M;
                                case 'pinv'
                                    tmp=pinv([lfL,lfR])*M;
                                case '*'
                                    tmp=[lfL,lfR]'*M;
                            end
                            mom(lefti,1:3)=tmp(1).*LL';
                            mom(righti,1:3)=tmp(2).*RR';
                            Vmodel=lfL*tmp(1)+lfR*tmp(2);
                            goodness(lefti)=corr(M,Vmodel).^2;
                            goodness(righti)=goodness(lefti);
                            
                        end
                    end
                end
                warning on
                src=srcL+srcR;
                src(:,2)=srcL(:,2)-srcR(:,2);
                mom(left,1:3)=srcL;
                mom(right,1:3)=srcR;
                dist=sqrt(sum((cfg.grid.pos-repmat(cfg.vol.o,size(mom,1),1)).^2,2));
                [~,maxi]=max(goodness(left));
                lfl=cfg.grid.leadfield{left(maxi)};
                lfr=cfg.grid.leadfield{right(maxi)};
                L=srcL(maxi,:);
                R=srcR(maxi,:);
                LL=L-abs(R)./sum(abs([R;L])).*(L-R);
                RR=LL;
                LL(2)=L(2)-abs(R(2))./sum(abs([R(2);L(2)])).*(L(2)+R(2));
                RR(2)=-LL(2);
                lfL=lfl*LL';
                lfR=lfr*RR';
                %             switch cfg.method
                %                 case '\' % same as pinv for symmetric
                %                     momLR=[lfL,lfR]\M;
                %                 case 'pinv'
                %                     momLR=pinv([lfL,lfR])*M;
                %                 case '*'
                %                     momLR=[lfL,lfR]'*M;
                %             end
                momLR=pinv([lfL,lfR])*M;
                Vmodel=lfL*momLR(1)+lfR*momLR(2);
                %Vmodel=sum(repmat(momLR(1).*LL,size(lfl,1),1).*lfl,2)+sum(repmat(momLR(2).*RR,size(lfr,1),1).*lfr,2);
                %Vmodel=[lfl,lfr]*dip.dip.mom
                dip=[];
                dip.label=data.label;
                dip.dip.pos=[cfg.grid.pos(left(maxi),:);cfg.grid.pos(right(maxi),:)];
                dip.Vdata=M;
                dip.Vmodel=Vmodel;  %  (srcL(maxi,:)*lfl'+srcR(maxi,:)*lfr')';%cfg.grid.leadfield{maxi}*source(maxi,:)'
                dip.time=cfg.latency;
                dip.dimord=data.dimord;
                dip.dip.mom=[momLR(1).*LL';momLR(2).*RR'];
                dip.leadfield{1,1}=lfl;
                dip.leadfield{1,2}=lfr;
                dip.grid_index=[left(maxi),right(maxi)];
                dip.dip.pot=dip.Vmodel;
                dip.dip.rv=sum((dip.Vdata-dip.Vmodel).^2) ./ sum(dip.Vdata.^2); %relative residual variance
                dip.cfg=cfg;
                R=goodness;
            end
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


