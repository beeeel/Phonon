

clear all
close all
%addpath F:\Users\Rich\Dropbox\code\PLU_old\PLU_Functions
filebase = 'test_apt_apt_count_1';
%filebase= 'Scan3'
%filebase = 'test_fibre_air_2'
run_no = '';
confile = strcat(filebase,run_no);      % con file name no extension
scan_type = 'd_scan';                   % or 'c_scan'
filename.file_size_check=200;
filename.base = confile;


FMA=0;      %enable fitting method analysis
STM=1;      %enable STFFT analysis
ZCM=0;      %enable zero crossing analysis
WAM=0;      %enable Wavelet analysis
% ***************    Main parameters     **********************************
exp_params.default_loc = 2200;           % where the co peak should be found
%exp_params.default_loc = 250;           % where the co peak should be found

exp_params.start_offset = 30;           % off set from co peak location for data selection
exp_params.co_peak_thresh = 0.5e-4;   % co peak level in volt for ac or mod depth for mod data
exp_params.trace_length=1000;            % how many points to use in trace for basic processing
exp_params.fit_order = 9;               % thermal removal fit order
exp_params.f_min =2;                  % min freq of interest, used in freq search
exp_params.f_max = 20;                  % max freq of interest, used in freq search
exp_params.co_peak_range = (-100:100)+exp_params.default_loc;   %search range for co_peak
exp_params.forced_co_peak = 'no';       % or 'yes', force to use default loc for co peak
exp_params.LPfilter = 60;               % in GHz
exp_params.index_object = 1.57;         % refractive index at wavelength for object, used to get V from brillouin data
exp_params.index_media = 1.33;          % refractive index at wavelength for surrounding media, used to get V from brillouin data
exp_params.index_sel_freq = 7;          % freq threshold to decide which index to assign, used by brillouin processing
exp_params.zp = 2^14;
exp_params.lambda = 780e-9;             % wavelength, used in vel conversion
exp_params.laser_freq = 80e6;           % laser rep rate, needed to convert electrical time base to acoustic
exp_params.delay_freq = 10e3;           % delay rep rate, needed to convert electrical time base to acoustic
exp_params.pump_power =1.2;             % can be used to store useful exp info with data
exp_params.probe_power=1.4;             % can be used to store useful exp info with data
exp_params.ac_gain = 12.5;              % ac gain of amp. (12.5 spectra rig, 8 for menlo)
exp_params.plotting_start_offset=100;   % no points before co peak to grab for raw plot data
exp_params.file_save=1;                 % save data files 1=yes, will query if filesize is larger than filename.file_size_check defined below.
exp_params.force_process =1;            % force reprocess even if there is a save file already

plot_params.enable_mask = 1;             % enable plotting mask, applied mask to freq data if using ac_amp, applied to both ac and freq is using dc_amp
plot_params.mask_threshold = 0.5e-6;     % value for threshold
plot_params.mask_var = 'ac_amp';         % allowed values, ac_amp, dc_amp,
plot_params.figure_save=0;               % save figures? 1=yes.

filename.file_size_check=200;
filename.base = confile;

% Fitting method Parameters
FM_params.range = 100:600;

% Zero crossing Parameters
ZC_params.threshold_freq = 7;
ZC_params.skip_events =8;
ZC_params.events_display=35;

% STFFT Parameters
ST_params.start_pos = [1:75:660];
ST_params.zp=2^12;
ST_params.f_min=exp_params.f_min;
ST_params.f_max=exp_params.f_max;
ST_params.window_size=145*3;
ST_params.amp_threshold=2e-6;
ST_params.freq_track=8.6;
ST_params.freq_water=9.5;

% Wavelet Parameters
W_params.f_min=2e9;
W_params.f_max=30e9;
W_params.freq_to_track = [5.3 9.4 10.3]*1e9;
W_params.wavelet_nm = 'cmor1-1';
W_params.freq_sel_cut=8;
W_params.object_vel=2.75;            %in microns per ns
W_params.slice_avg=20;
W_params.thresh = 0.09;             % max data is 1, this is what the tranisition of tracked freq uses.
W_params.select = (61:1:800);      %selection to use for 3D (need to skip inital trans response.

%cal_y = 33.61;
%cal_x = 48.39;
%% PARSE CON FILE
[filename, axis_info]=func_get_scan_details_multiscan(filename);
% need to add sanity checks functions on input params.
%% LOAD DATA
[data] = func_load_all_data_multiscan(filename,axis_info,exp_params);
%% PROCESS DATA
[data] = func_basic_process_multiscan(data,axis_info,exp_params);%
%% PLOTTING
% need wrapper to pass scan data to correct plotting fun depending on the dimensionality of the data for 3D and higher, will need selection criteria.
% the below needs to become a script so it doesnt take up space.
for k=1:length(data)
    currentscan =strcat('scan',num2str(k));
    switch axis_info.number_of_axes(k)
        case 1
            %1D scan plotting scripts
            filename_str = strcat(strip_suffix(filename.con,'.con'),currentscan);
            [fh]=func_plot_basic_1D_multiscan(data.(currentscan),axis_info.(currentscan),filename_str,exp_params,plot_params);
            %2D scan plotting scripts
        case 2
            filename_str = strcat(strip_suffix(filename.con,'.con'),currentscan);
            [fh]=func_plot_basic_multiscan(data.(currentscan),axis_info.(currentscan),filename_str,exp_params,plot_params);
        case 3
            %3D scan plotting scripts
            % the selections below need to be passed as options with defaults.
            v_new = data.scan1.freq{1};             %3D data cube, e.g. processed F from 3D scan, or sectioned data.
            z_um = axis_info.scan1.axis3.um;        %this is the axis info the section (depth, time, whatever) - THIS IS NOT USED ANYMORE!
            f_min =8              ;                 %freq plot limit ranges could be from exp_params if not specified (you might want different plotting ranges than that processed
            f_max = 12;
            
            %make strucutre to pass to plot and also for call back function within
            %plotting script.
            plotting_vars{1}=v_new;
            plotting_vars{2}=axis_info;
            plotting_vars{3}=z_um;
            plotting_vars{4}=exp_params.f_min;
            plotting_vars{5}=exp_params.f_max;
            % actually call the plot
            [fh] = func_section_plot_multiscan(plotting_vars);
        otherwise
            display('more than 3 dimensions, can not plot this data!')
    end
end

%%





%
%
% %% basic processing code, data selection,thermal removal, fft, peak finding, filtering for display
% [data] = func_basic_process(data,exp_params);
% %% basic data plotting script. with point and click data options.
% [fh]=func_basic_plot(data,axis_info,filename,exp_params,plot_params);
% %func_save_basic_data_with_check(data,filename,exp_params,axis_info);
% %%
% %% Advanced processing methods: fitting method.
% if FMA==1
%     [FM_data] = Func_fit_data_values(data,axis_info,FM_params);
%     %% plot fitting method data
%     [fh]=func_fitting_plot(FM_data,axis_info,filename,exp_params);
% end
% %% Advanced processing methods: zero crossing method.
% if ZCM ==1
%     [ZC_data]= func_zero_crossing_analysis(data,ZC_params); %end vals need adding to list, threhold for jump,events to skip
%     %% plot zero crossing method
%     [figure_handles]=func_zero_cross_plot(ZC_data,axis_info,filename,exp_params,ZC_params);
% end
% %% Advanced processing methods: STFFT method.
% if STM==1
%     [ST_data]=func_short_time_fft_process(data,axis_info,ST_params);
%     %% plotting for ST FFT
%     [f_handle]=func_plot_STFFT(data,filename,axis_info,exp_params,ST_data,ST_params);
% end
% %% Advanced processing methods: wavelet method.
% if WAM==1
%     [W_data,W_params] = func_wavelet_processing(data,axis_info,W_params);
%     %% wavelet image plotting and 3D surface
%     [handle] = func_plot_wavelet(W_data,data,axis_info,filename,exp_params,W_params);
% end
%
% %% section to save all the data.. this needs improving.
% if exp_params.file_save==1;
%     func_save_basic_data_with_check(data,filename,exp_params,axis_info); %filename has to be first,main data file second, everything else doesnt matter!
%     if FMA==1;func_save_FMA_data_with_check(FM_data,FM_params,filename,axis_info);end
%     if ZCM==1;func_save_ZC_data_with_check(ZC_data,ZC_params,filename,axis_info);end
%     if STM==1;func_save_STM_data_with_check(ST_data,ST_params,filename,axis_info);end
%     if WAM==1;func_save_WAM_data_with_check(W_data,W_params,filename,axis_info);end
% end
%
%
%
%
