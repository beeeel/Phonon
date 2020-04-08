

clear all
close all
addpath './multiscan';

%filebase = 'ThreeD_cal_sample_1';  % 3D phidgets

%filebase= 'PEI_20_21_1';   %2D scan  Works

%filebase = 'TwoDcount_cal_sample_1'; % 3D count

%filebase = 'test_2'; % 1D count from PLU
filebase = 'Otherone_1';

run_no = '';
confile = strcat(filebase,run_no);      % con file name no extension
scan_type = 'd_scan';                   % or 'c_scan'
filename.file_size_check=200;
filename.base = confile;

% ***************    Main parameters     **********************************
exp_params.default_loc = 300;           % where the co peak should be found
%exp_params.default_loc = 2483;           % where the co peak should be found
exp_params.start_offset = 30;           % off set from co peak location for data selection
exp_params.co_peak_thresh = 0.5e-4;   % co peak level in volt for ac or mod depth for mod data
exp_params.trace_length=1000;            % how many points to use in trace for basic processing
exp_params.fit_order = 9;               % thermal removal fit order
exp_params.f_min =8;                  % min freq of interest, used in freq search
exp_params.f_max = 13;                  % max freq of interest, used in freq search
exp_params.co_peak_range = (-100:100)+exp_params.default_loc;   %search range for co_peak
exp_params.forced_co_peak = 'no';       % or 'yes', force to use default loc for co peak
exp_params.LPfilter = 60;               % in GHz
exp_params.index_object = 1.57;         % refractive index at wavelength for object, used to get V from brillouin data
exp_params.index_media = 1.33;          % refractive index at wavelength for surrounding media, used to get V from brillouin data
exp_params.index_sel_freq = 7;          % freq threshold to decide which index to assign, used by brillouin processing
exp_params.zp = 2^14;
exp_params.lambda = 780e-9;             % wavelength, used in vel conversion
exp_params.laser_freq = 100e6;           % laser rep rate, needed to convert electrical time base to acoustic
%exp_params.laser_freq = 80e6;
exp_params.delay_freq = 10e3;           % delay rep rate, needed to convert electrical time base to acoustic
exp_params.pump_power =1.2;             % can be used to store useful exp info with data
exp_params.probe_power=1.4;             % can be used to store useful exp info with data
exp_params.ac_gain = 12.5;              % ac gain of amp. (12.5 spectra rig, 8 for menlo)
exp_params.plotting_start_offset=100;   % no points before co peak to grab for raw plot data
exp_params.file_save=1;                 % save data files 1=yes, will query if filesize is larger than filename.file_size_check defined below.
exp_params.force_process =1;            % force reprocess even if there is a save file already

plot_params.enable_mask = 1;             % enable plotting mask, applied mask to freq data if using ac_amp, applied to both ac and freq is using dc_amp
plot_params.mask_threshold = 0.1e-6;     % value for threshold
plot_params.mask_var = 'ac_amp';         % allowed values, ac_amp, dc_amp,
plot_params.figure_save=0;               % save figures? 1=yes.

filename.file_size_check=200;
filename.base = confile;

%% PARSE CON FILE
[filename, axis_info]=func_get_scan_details_multiscan(filename);

% exp_params.check_axis_order=1;
% if exp_params.check_axis_order
%     axis_str='axes type and order:';
%     for k=1:length(axis_info.scan1.axis_order)
%         axis_str=strcat(axis_str,':',axis_info.scan1.axis_order{k});
%     end
%     disp(axis_str);
% end
% exp_params.swap_stage_order = [2 3 1];
% current_scan='scan1';
% tmp = axis_info;
% for k =1:length(axis_info.(current_scan).axis_order)
% axis_info.(current_scan).(strcat('axis',num2str(k))) = tmp.(current_scan).(strcat('axis',num2str(exp_params.swap_stage_order(k))));
% axis_info.(current_scan).axis_pts(k) = tmp.(current_scan).axis_pts(exp_params.swap_stage_order(k));
% axis_info.(current_scan).axis_order{k} = tmp.(current_scan).axis_order{exp_params.swap_stage_order(k)};
% end
%axis_info.(current_scan).axis_pts = permute(axis_info.(current_scan).axis_pts,exp_params.swap_stage_order); 
% need to add sanity checks functions on input params.
%% LOAD DATA
[data] = func_load_all_data_multiscan(filename,axis_info,exp_params);
%% PROCESS DATA
[data] = func_basic_process_multiscan(data,axis_info,exp_params);%
%% PLOTTING
[handles] = func_basic_plot_multiscan(data,axis_info,exp_params,plot_params,filename);
