function [str, tag, cind] = gencode(item, tag, tagctx)

% function [str, tag, cind] = gencode(item, tag, tagctx)
% Generate code to recreate an cfg_dep object.
%
% This code is part of a batch job configuration system for MATLAB. See 
%      help matlabbatch
% for a general overview.
%_______________________________________________________________________
% Copyright (C) 2007 Freiburg Brain Imaging

% Volkmar Glauche
% $Id: gencode.m 3355 2009-09-04 09:37:35Z volkmar $

rev = '$Rev: 3355 $'; %#ok

if nargin < 2
    tag = inputname(1);
end;
if nargin < 3
    tagctx = {};
end
if isempty(tag)
    tag = genvarname('val', tagctx);
end;

cind = 1;

str = {};
fn = fieldnames(item);
for k = 1:numel(item)
    % explicitly create each item in array
    str{end+1} = sprintf('%s(%d) = %s;', tag, k, class(item));
    for l = 1:numel(fn)
        switch class(item(k).(fn{l}))
            case 'struct'
                % substruct fields
                % only create if not empty, use gencode_substructcode to
                % produce a one-line code.
                if numel(item(k).(fn{l})) >= 1
                    % force index (1) if there is exactly one entry
                    tag1 = sprintf('%s(%d).%s', tag, k, fn{l});
                    str1 = gencode_substructcode(item(k).(fn{l}), tag1);
                    str  = [str(:)' str1(:)'];
                end;
            otherwise
                % other field should not be indexed
                tag1 = sprintf('%s(%d).%s', tag, k, fn{l});
                str1 = gencode(item(k).(fn{l}), tag1, [{tag1} tagctx]);
                str  = [str(:)' str1(:)'];
        end;
    end;
end;