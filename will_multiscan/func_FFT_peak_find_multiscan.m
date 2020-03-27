%function [freq,F_amp,fx_out,F_out]=func_FFT_peak_find(t_in,data,params)
%
function [freq,F_amp,fx_out,F_out,F_pha]=func_FFT_peak_find_multiscan(t_in,data,params)

data_in = data;
zp=params.zp;
f_min=params.f_min;
f_max=params.f_max;

t = (1:zp).*(t_in(2)-t_in(1));
fx = xtof(t);
[nul f_min_loc]=find(fx(zp/2:zp)>f_min*1e9,1);
[nul f_max_loc]=find(fx(zp/2:zp)>f_max*1e9,1);

F_tmp = (2/length(data_in)).*(fftshift(fft(data_in,zp)));
[F_amp sig_loc] = max(abs(F_tmp(zp/2+f_min_loc:zp/2+f_max_loc)));
peak_loc = sig_loc+zp/2+f_min_loc;
F_pha = angle(F_tmp(peak_loc));
freq = fx(peak_loc)/1e9;
F_out = abs(F_tmp(zp/2:zp/2+f_max_loc*2));

fx_out = fx(zp/2:zp/2+f_max_loc*2);
