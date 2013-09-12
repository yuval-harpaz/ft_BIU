function showHeadInGrad(fileName,unit)
if ~exist('unit','var')
    unit=[];
end
if isempty(unit)
    unit='mm';
end
if ~exist('fileName','var')
    fileName=[];
end
if isempty(fileName)
    fileName=findMEGfileName(1)
end
hdr=ft_read_header(fileName);
hdr.grad=ft_convert_units(hdr.grad,unit);
megchans=find(ismember(hdr.grad.chantype,'meg'));
chanpos=hdr.grad.chanpos;
megx=chanpos(megchans,1);
megy=chanpos(megchans,2);
megz=chanpos(megchans,3);
figure;
plot3(megx,megy,megz,'o');
hold on
hs=ft_read_headshape('hs_file');
hs=ft_convert_units(hs,unit);
hsx=hs.pnt(:,1);
hsy=hs.pnt(:,2);
hsz=hs.pnt(:,3);
plot3(hsx,hsy,hsz,'rx');




