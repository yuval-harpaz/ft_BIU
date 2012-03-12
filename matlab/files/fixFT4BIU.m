function fixFT4BIU
display(['1. remove fieldtrip*/external/spm2* and fieldtrip*/external/spm8* from the path'])
display('2. replace fieldtrip*/read_trigger.m with ~/ft_BIU/matlam/ft_files/read_trigger.m');
display('3. for beamformer_sam.m replace progress with ft_progress a few times')

