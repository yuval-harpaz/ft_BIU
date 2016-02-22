function glob=rms(data)
% takes a matrix of say, MEG data, and compute global trace (rows =
% channels).

glob=sqrt(mean(data.^2));

