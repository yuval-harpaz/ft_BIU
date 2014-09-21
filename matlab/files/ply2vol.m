function vol=ply2vol(fileName)
% Read the surface .ply file created by 3dskullstrip (RAI order, mm) and
% make it into a vol structure (PRI order, m, to fit the headshape.
% I recommend displaying the surface (inner skull by default) with the
% headshape like this:
% hs=ft_read_headshape('hs_file');
% plot3pnt(hs.pnt,'.r')
% hold on
% ft_plot_vol(vol)
if ~exist('fileName','var')
    fileName='ortho_innerskull.ply';
end
fid = fopen(fileName);
tline = fgets(fid);
trii=0;
pnti=0;
while ischar(tline)
    %disp(tline)
    try %#ok<TRYNC>
        if strcmp(tline(1:10),'end_header')
            while ischar(tline)
                tline = fgets(fid);
                if strcmp(tline(1:3),'1 3')
                    trii=trii+1;
                    tri(trii,1:3)=str2num(tline(5:end)); %#ok<*ST2NM>
                else
                    pnti=pnti+1;
                    pnt(pnti,1:3)=str2num(tline); %#ok<*AGROW>
                    
                end
                    
            end
            
        end
    end
    tline = fgets(fid);
end

fclose(fid);



% !grep -o ^"1 ".* ortho_innerskull.ply > tri.txt
% tri=importdata('tri.txt');
% % find how to do grep for pnt
% pnt=importdata('pnt.txt');
vol=[];
vol.type='nolte';
vol.unit='m';
vol.bnd.pnt=-pnt(:,2)./1000;
vol.bnd.pnt(:,2)=pnt(:,1)./1000;
vol.bnd.pnt(:,3)=pnt(:,3)./1000;
vol.bnd.tri=tri(:,1:3)+1;