% function to cal frequency scale from x

function [fx]=xtof(x)

nx=length(x);
dx=x(2)-x(1);
df=1/(nx*dx);
fm=0.50/dx;
fs=-fm;

nx1=nx-1;
i1=0:nx1;

fx=fs+df*(i1);

