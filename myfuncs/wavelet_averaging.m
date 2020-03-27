%% Load data in - some variables from the standard processing code first
[filename,axis_info]=func_scan_details(filename,scan_type);
% sanity check exp_params with file infomation
func_param_check(axis_info,exp_params)
% section to load data files, work out which are DC / AC and load, reshape as required.
[data] = func_load_data(filename,axis_info,exp_params,scan_type);
%% Average raw traces and then put into processing
n_traces = size(data.ac{1},2);
n_points = axis_info.no_points;
counts_avg = 10;
new_traces = n_traces/counts_avg;

data2           = data;
data.ac         = {zeros(1,new_traces,n_points)};
data.dc         = {zeros(new_traces,1)};
data.mod        = {zeros(1,new_traces,n_points)};
data.shifted    = {zeros(1,new_traces,length(data2.t_shifted))};
data.copeak_lev = zeros(1,new_traces);
data.loc        = zeros(1,new_traces);

for fn = {'ac' 'mod' 'shifted'}
    for Tr = 1:new_traces    
        data.(fn{:}){1}(1,Tr,:) = mean(data2.(fn{:}){1}(1,counts_avg*(Tr-1)+1:counts_avg*Tr-1,:));
        data.dc{1}(Tr,:) = mean(data2.dc{1}(counts_avg*(Tr-1)+1:counts_avg*Tr-1,:));
    end
end
for fn = {'copeak_lev','loc'}
    for Tr = 1:new_traces
        data.(fn{:})(Tr) = mean(data2.(fn{:})(1,counts_avg*(Tr-1)+1:counts_avg*Tr-1));
    end
end
clear data2
axis_info.x = 1:counts_avg:1000;
axis_info.x_um = 1:counts_avg:1000;
axis_info.no_traces = n_traces/counts_avg;
axis_info.xpts = n_traces/counts_avg;
%% Put into processing (basic and wavelet)
[data] = func_basic_process(data,exp_params);
[W_data, W_params] = func_wavelet_processing(data,axis_info,W_params);
%%
figure(3)
set(gcf,'WindowStyle','docked')
a = imagesc(0:4,W_data.t,fliplr(rot90(squeeze(W_params.Frq(W_data.max_loc{1}(:,:,:))),-1)),[5.3 5.86]*1e9);
a.Parent.YAxis.Direction = 'normal';
title('Max frequency')
colorbar 
figure(8)
set(gcf,'WindowStyle','docked')
for plt = 1:4
    subplot(4,1,plt)
    a = imagesc(0:4,W_data.t,fliplr(rot90(squeeze(W_data.tracked_lev{1}(:,:,plt,:)),-1)));
    a.Parent.YAxis.Direction = 'normal';
    title([num2str(W_params.freq_to_track(plt)/1e9) ' GHz intensity'])
end