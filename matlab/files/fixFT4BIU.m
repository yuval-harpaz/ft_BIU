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
        movefile('external/spm2','~/Dektop/')
        display('I put external/spm2 on ~/Desktop')
    end
    if exist('external/spm8','dir')
        movefile('external/spm8','~/Dektop/')
        display('I put external/spm8 on ~/Desktop')
    end
    display('for beamformer_sam.m replace progress with ft_progress a few times')
    copyfile('~/ft_BIU/matlab/files/ftFixed4BIU','ftFixed4BIU')
else
    display('it seems thif ft package was fixed already')
end
    

