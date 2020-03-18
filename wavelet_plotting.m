%% Reconstruct wavelet processed data into something useful
% Run this script after the standard processing
load noco01_processed.mat
%%
filebase = 'hela_noco001_';
run_no = '2';
confile = strcat(filebase,run_no);      % con file name no extension
scan_type = 'd_scan';                   % or 'c_scan'
filename.file_size_check=200;
filename.base = confile;
[filename,axis_info]=func_scan_details(filename,scan_type);

W_params.f_min=4.8e9;
W_params.f_max=6.5e9;
W_params.freq_to_track = [5.2 5.4 6.2]*1e9;
W_params.freq_sel_cut=8;
W_params.object_vel=1.5;            %in microns per ns
W_params.thresh = 0.09;             % max data is 1, this is what the tranisition of tracked freq uses.
W_params.select = (61:1:800);      %selection to use for 3D (need to skip inital trans response.


%% Rerun the wavelet processing
W_params.wavelet_nm = 'cmor2-2.5';
W_params.slice_avg=40;
tic
[W_data,W_params] = func_wavelet_processing(data,axis_info,W_params);
toc
%%
cd /home/fperez/0612_Will
load hela_noco001_2processed.mat
%%
load hela_noco0001_4_process.mat
%%
cd /home/fperez/0611_Will
load hela_noco01_5_processed.mat
%%
load hela_noco_day2_3_process.mat
%
[szX, szY, szT] = size(W_data.max_loc{1});
pct = [0.05, 0.75];
step = 20;
slices = round(szT * pct(1)):step:round(szT * pct(2));
n_avgs = size(slices,2);
% Calculate cross-sections

% Calculate the data to show on cross-sections, call the sectioning plot
% function

plotting_vars{1} = zeros(szX, szY, n_avgs);
plotting_vars{2} = axis_info;
plotting_vars{3} = zeros(n_avgs,1);
plotting_vars{4} = W_params.f_min;
plotting_vars{5} = W_params.f_max;
for slice = 1:n_avgs
    Z = slices(slice):slices(slice)+step-1;
    plotting_vars{1}(:,:,slice) = mean(W_params.Frq(W_data.max_loc{1}(:,:,Z)),3);
    plotting_vars{3}(slice) = W_data.t(slices(slice));
end
fh = func_section_plot(plotting_vars);
colorbar
set(gcf,'Name',W_params.wavelet_nm)
%% "fly through" stack
% Average some layers and display them in turn. Would be more efficient if
% it did all the averaging, then the displaying
figure(5)
for slice = round(szT*pct(1)):step:round(szT*pct(2))
    % Voxel-wise data is stored in W_data.max_loc{1}, as a 3D array. The
    % values in this array are lookup indices to be taken from W_params.Frq
    % to translate into frequencies.
    im_data = mean(W_params.Frq(squeeze(W_data.max_loc{1}(:,:,slice:slice+step-1))),3);
    imagesc(im_data,[min(W_params.Frq), max(W_params.Frq)])
    axis image
    colorbar
    pause(0.05)
end
%% Look at the cmor wavelet (only plots the real part because I'm lazy)
cmor = @(x, Fb, Fc) (pi*Fb)^(-0.5) .*exp(2*1i*pi*Fc.*x).*exp(-(x.^2)./Fb);
x = -5:0.01:5;
figure
plot(x, cmor(x, 4, 1))
