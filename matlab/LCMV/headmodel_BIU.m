function [vol,grid,mesh,M1,single]=headmodel_BIU(source,MRI,res,volType,model,fidORhs);
% creates volume for source localizaton.
% Nolte models based on 'scalp', 'iskull' (default) or 'ctx' (not
% recommended).
% source- name of data file (c,rfhp0.1Hz is the default). hs_file
% has to be there too. uses template MRI unless specify MRI='anat.nii'. MRI
% can be nii or img format. for AFNI files use 3dAFNItoNIFTI for
% conversion.
% res- resolution, 5 or 10mm (default).
% model='singleshell' or localspheres'
% fidORhs - template MRI to fiducials only or also to headshape

%setting defaults
single=[];
if ~exist('source','var')
    source=[];
end
if isempty(source)
    source='c,rfhp0.1Hz';
end
if ~ischar(source)
    error('needs name of source file for data, c,rfhp...')
end
if ~exist('MRI','var')
    MRI=[];
end
if ~exist('res','var')
    res=[];
end
if isempty(res)
    res=10;
end
if ~exist('volType','var')
    volType=[];
end
if isempty(volType)
    volType='scalp';
end
if ~strcmp(volType,'ctx') && ~strcmp(volType,'iskull') && ~strcmp(volType,'scalp')
    error('volType has to be ctx iskull or scalp')
end
if ~exist('model','var')
    model=[];
end
if isempty(model)
    model='singleshell';
end
if ~exist('fidORhs','var')
    fidORhs=[];
end
if isempty(fidORhs)
    fidORhs='fid';
end
cfg.dataset=source;
cfg.trialdef.poststim=1;
cfg.trialfun='trialfun_beg';
cfg=ft_definetrial(cfg);
data=ft_preprocessing(cfg);
hdr=ft_read_headerOLD(source); % to get rid of chans 272:276
data.grad=ft_convert_units(hdr.grad,'mm');

%data.avg = data.trial;
if ~isfield(data,'dimord')
    data.dimord = 'chan_time';
end
cfg1.model=model;
cfg1.resolution=res;
headshapefile='hs_file';

hasspm = (exist('spm_eeg_ft2spm') & exist('spm_eeg_inv_mesh') & exist('spm_eeg_inv_datareg') & exist('spm_eeg_inv_checkdatareg'));
if ~hasspm
    error('the SPM8 toolbox is not installed');
end

if ~exist(headshapefile)
    error('Cannot find headshape file');
end
if ~isfield(data,'hdr')
    data.hdr.grad=data.grad;
end;
%convert to spm format
D=spm_eeg_ft2spm(data,'modtempfile');
S.D = D;
S.task = 'headshape';
S.headshapefile = headshapefile;
S.source = 'convert';
S.regfid{1, 1} = 'NZ';
S.regfid{1, 2} = 'NZ';
S.regfid{2, 1} = 'L';
S.regfid{2, 2} = 'L';
S.regfid{3, 1} = 'R';
S.regfid{3, 2} = 'R';
S.regfid{4, 1} = 'fiducial4';
S.regfid{4, 2} = 'fiducial4';
S.regfid{5, 1} = 'fiducial5';
S.regfid{5, 2} = 'fiducial5';
S.save = 1;
D = spm_eeg_prep(S);
D.inv = {struct('mesh', [])};
D.inv{1}.date    = strvcat(date,datestr(now,15));
D.inv{1}.comment = {''};
D.inv{1}.mesh= spm_eeg_inv_mesh(MRI, 2);
% spm_eeg_inv_checkmeshes(D);
tmesh=D.inv{1}.mesh;
%COREGISTRATION WITH TEMPLATE MRI
meegfid = D.fiducials;
mrifid = D.inv{1}.mesh.fid;
meegfid.fid.pnt   = meegfid.fid.pnt(1:3,:);
meegfid.fid.label = meegfid.fid.label(1:3,:);
mrifid.fid.pnt   = mrifid.fid.pnt(1:3,:);
mrifid.fid.label = meegfid.fid.label(1:3,:);
M1=[];
S =[];
S.sourcefid = meegfid;
S.targetfid = mrifid;
S.useheadshape = 1;
S.template = 2;
M1 = spm_eeg_inv_datareg_BIU(S);
D.inv{1}.datareg = struct([]);
D.inv{1}.datareg(1).sensors = D.sensors('MEG');
D.inv{1}.datareg(1).fid_eeg = S.sourcefid;
D.inv{1}.datareg(1).fid_mri = forwinv_transform_headshape(inv(M1), S.targetfid);
D.inv{1}.datareg(1).toMNI = D.inv{1}.mesh.Affine*M1;
D.inv{1}.datareg(1).fromMNI = inv(D.inv{1}.datareg(1).toMNI);
D.inv{1}.datareg(1).modality = 'MEG';

[Lsens, Llabel]   = spm_eeg_layout3D(D.sensors('MEG'), 'MEG');
mesh=spm_eeg_inv_checkdatareg_BIU(D);
%Build vol
eval(['tinpoints = export(gifti(tmesh.tess_',volType,'), ','''spm''',');'])
%tscalp=export(gifti(tmesh.tess_scalp), 'spm');
%tctx=export(gifti(tmesh.tess_ctx), 'spm');
%mesh=D.inv{1}.mesh;
eval(['svol=','''mesh.tess_',volType,''';']);
display(['building ',volType,' volume'])
switch model
    case 'singleshell'
        vol = [];
        eval(['vol.bnd = export(gifti(',svol,'), ''','ft''',');'])
        vol.type = 'nolte';
        %vol = forwinv_convert_units(vol, 'mm');
        %vol.bnd.pnt=spm_eeg_inv_transform_points(D.inv{1}.datareg.toMNI, vol.bnd.pnt);
        tvol=[];
        tvol.bnd = export(gifti(tinpoints), 'ft');
        tvol.type = 'nolte';
    case 'localspheres'
        cfg                        = [];
        cfg.feedback               = 'yes';
        %            cfg.grad                   = D.inv{1}.datareg(1).sensors;
        cfg.grad = data.grad;
%        mesh.tess_scalp=export(gifti(tmesh.tess_scalp),'spm');
        cfg.headshape.pnt              = mesh.tess_scalp.vert;
        cfg.radius                 = 85;
        cfg.maxradius              = 200;
        cfg.channel={'MEG'};
       % vol  = ft_prepare_localspheres(cfg);
        vol  = ft_prepare_localspheres_mm(cfg);
        cfg.singlesphere='yes';
        single=ft_prepare_localspheres_mm(cfg);
        
        

%         vol.o=spm_eeg_inv_transform_points(D.inv{1}.datareg.toMNI, vol.o);
%         cfg.headshape              = tscalp.vert;
%         tvol  = prepare_localspheres(cfg);
        
end


%% preparing a grid of dipoles
% load template grid works only for scalp.
% eval (['load ~/ft_BIU/matlab/LCMV/template_grid_',num2str(res),'mm.mat'])

template_grad     = [];
template_grad.pnt = [];
template_grad.ori = [];
template_grad.tra = [];
template_grad.label = {};
cfg = [];
cfg.grid.xgrid = -70:cfg1.resolution:70;
cfg.grid.ygrid = -105:cfg1.resolution:75;
cfg.grid.zgrid = -60:cfg1.resolution:80;
% cfg.grid.tight = 'yes'; %new way
cfg.inwardshift = -1.5;
template_grid = prepare_dipole_grid(cfg, tvol, template_grad);

% changing position of grid point from MNI to individual positions.
grid         = [];
grid.pos     = spm_eeg_inv_transform_points(inv(M1), template_grid.pos);
grid.inside  = template_grid.inside;
grid.outside = template_grid.outside;
grid.dim = template_grid.dim;
close all
figure
plot3(meegfid.pnt(:,1),meegfid.pnt(:,2),meegfid.pnt(:,3),'o');
hold on
if strcmp(vol.type,'multisphere');
    ft_plot_vol(single);
else
    ft_plot_vol(vol);
end
ft_plot_mesh(grid);
end
