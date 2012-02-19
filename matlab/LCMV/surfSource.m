function surfSource(nai,pos,inside)
x=pos(inside,1);
y=pos(inside,2);
z=pos(inside,3);
v=nai(inside);
p = patch(isosurface(x,y,z,v,-3));
end