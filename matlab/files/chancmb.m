function chanpairs=chancmb(chans)
% creates pairs of channels for ft_connectivity analysis.
% give it a 1xN cell array of channels and it gives back two columns of all
% possible pairs. later use as cfg.channelcmb=chanpairs;
linei=1;
for i=1:(length(chans)-1)
    for j=(i+1):length(chans)
        chanpairs{linei,1}=chans(1,i);
        chanpairs{linei,2}=chans(1,j);
        linei=linei+1;
    end
end