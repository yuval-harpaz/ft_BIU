function fixFT4BIU
% this function meant to fix newly downloaded fieldtrip packages, after 
% adding them to matlab path, for bar ilan university use.

ft=which('ft_definetrial');
k = findstr('ft_definetrial.m', ft);
path2ft=ft(1:k-1);
cd(path2ft)
if ~exist('./ftFixed4BIU','file')
    if ~exist('fileio/private/read_triggerOrig.m','file')
        movefile('fileio/private/read_trigger.m','fileio/private/read_triggerOrig.m');
        copyfile('~/ft_BIU/matlab/ft_files/read_triggerBIU.m','fileio/private/read_trigger.m')
    end
    if exist('external/spm2','dir')
        if ~exist('~/Dektop/outOfFT','dir')
            mkdir('~/Dektop/outOfFT')
        end
        movefile('external/spm2','~/Dektop/outOfFT/')
        display('I put external/spm2 on ~/Desktop/outOfFT/')
    end
    if exist('external/spm8','dir')
        if ~exist('~/Dektop/outOfFT','dir')
            mkdir('~/Dektop/outOfFT')
        end
        movefile('external/spm8','~/Dektop/outOfFT/')
        display('I put external/spm8 on ~/Desktop/outOfFT/')
    end
    display('for beamformer_sam.m replace progress with ft_progress a few times')
    
    if ~exist('./fileio/private/read_4d_hdr_old.m','file')
        movefile('fileio/private/read_4d_hdr.m','fileio/private/read_4d_hdr_old.m')
        copyfile('~/ft_BIU/matlab/ft_files/read_4d_hdr_BIU1.m','fileio/private/read_4d_hdr.m')
    end
    copyfile('~/ft_BIU/matlab/files/ftFixed4BIU','ftFixed4BIU')
else
    display('it seems that this ft package was fixed already')
end
    

