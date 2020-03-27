function [data_out] = func_LPfilter_multiscan(t,data_in,fcut1)
fcut1=fcut1*1e9;
fx = xtof(t);
[tmp p1] = min(abs(fx-fcut1));
window = zeros(size(data_in));
n = round(size(window,2)/2);
%[p1 n]
width_window = p1-n;
window(n-width_window:n+width_window) =hann(2*width_window+1);
fftdata = fftshift(fft(fftshift(data_in)));
filtered = fftdata.*window;
data_out=real(ifftshift(ifft(ifftshift(filtered))));
