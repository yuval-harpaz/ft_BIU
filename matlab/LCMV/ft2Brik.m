function ft2Brik(cfg,vs)

% cfg should include:
% cfg.boxSize is [xmin xmax ymin ymax zmin zmax] in mm and PRI order 
% cfg.step is the spatial resolution in mm (5 ?)
% cfg.prefix for prefix
%
% if there is more than one time sample you should also have:
% cfg.TR (time of requisition) is the difference between two samples in ms.
% cfg.torig the time of the first sample in ms (e.g. -100)
%
% vs (virtual sensors) has rows for voxels and columns for time samples.

xyzMin=cfg.boxSize([1 3 5]);
xyzMax=cfg.boxSize([2 4 6]);
xsize=length(int16(xyzMin(1)):cfg.step:int16(xyzMax(1)));
ysize=length(int16(xyzMin(2)):cfg.step:int16(xyzMax(2)));
zsize=length(int16(xyzMin(3)):cfg.step:int16(xyzMax(3)));
% here I create a functional template from scratch
if exist ('./temp+orig.BRIK','file')
    !rm temp+orig*
end
xyzstr=[num2str(xsize),' ',num2str(ysize),' ',num2str(zsize)];
eval(['!~/abin/3dUndump -dimen ',xyzstr,' -prefix temp']);
eval(['!~/abin/3drefit -xyzscale ',num2str(cfg.step),' temp+orig'])
origins=abs(xyzMin);
eval(['!~/abin/3drefit -orient LPI -xorigin ',num2str(origins(1)),' -yorigin ',num2str(origins(2)),' -zorigin ',num2str(origins(3)),' temp+orig'])


[~, ~, Infofunc, ~] = BrikLoad ('temp+orig');

tsize=size(vs,2);
vsRs=reshape(vs,[xsize,ysize,zsize,tsize]);%figure;plot(squeeze(vsRs(20,20,:))==0,'k');hold on;plot(squeeze(vsRs(20,:,20))==0,'b');plot(squeeze(vsRs(:,20,20))==0,'c');

% newVfunc=permute(vsRs,[3 2 1 4]);
newVfunc=vsRs;
InfoNewTSOut = Infofunc;
InfoNewTSOut.RootName = '';
InfoNewTSOut.BRICK_STATS = [];
InfoNewTSOut.BRICK_FLOAT_FACS = [];
InfoNewTSOut.IDCODE_STRING = '';
InfoNewTSOut.BRICK_TYPES=3*ones(1,tsize); % 1 short, 3 float.
InfoNewTSOut.DATASET_RANK(2)=tsize;
if tsize>1
    for brki=1:tsize
        if brki==1
            labels='samp1';
        else
            labels=[labels,'~samp',num2str(brki)];
        end
    end
    InfoNewTSOut.BRICK_LABS =labels;
    % read README.attributes of afni
    def=-999;
    InfoNewTSOut.TAXIS_NUMS=[tsize,0,77001,def,def,def,def,def]; % 77001 for ms
    if ischar(cfg.TR)
        TR=str2double(cfg.TR);
    else
        TR=cfg.TR;
    end
    InfoNewTSOut.TAXIS_FLOATS=[cfg.torig,TR,0,0,0,-999999,-999999,-999999];
end
OptTSOut.Scale = 1;
OptTSOut.Prefix = cfg.prefix;
OptTSOut.verbose = 1;
%OptTSOut.Slices=tsize;
if exist([cfg.prefix,'+orig.BRIK'],'file')
    eval(['!rm ',cfg.prefix,'+orig*'])
end
%write it
WriteBrik (newVfunc, InfoNewTSOut, OptTSOut);
!rm temp+orig*
end