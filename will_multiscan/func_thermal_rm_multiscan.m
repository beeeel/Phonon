function [t_out data_out] = func_thermal_rm_multiscan(t_in,data_in,order,startval,endval)

t2=t_in(startval:endval);
data_tmp = squeeze(data_in(startval:endval));
[p s mu] = polyfit(t2,data_tmp,order);
fit = polyval(p,t2,[],mu);
data_out= data_tmp-fit;
t_out=t2;