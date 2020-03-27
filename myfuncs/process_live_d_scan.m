%% ******************************************************************************************************************8
% live data scan
% point by point updates if save is in inner loop in dscan con file
% also works with line by line saving
% polls HDD every 5 seconds to see if the file size has changed (can be
% changed)
% finishes when the scan is complete (i.e. filesize = expected filesize)
% works for 1 to 4 channels, can change processing varibles.
% once complete give interactive plot
% RJS oct 2015.
% RJS nov 2015  - major upgrade to fix mouseclick call back issues
%               - fix filereading so that less stuff needs to be defined by user
%               - e.g. files to load, etc. scan regions
% RJS Mar 2017. - fixed issues with d_scan live plots when have DC data (dc currently ignored in this tempory fix
%               - TO DO: poll both scope and DC data to check they match in size or work out what is ok to load.
%               - find copeak automatically, now FIXED
%% ******************************************************************************************************************8
close all
clear variables
addpath /home/share/matlab/PLU/PLU_Functions
% filename details. edit as needed for your data
filebase = 'live_3T3';
run_no = '1';
scan_type = 'd_scan';
fluo = 1;
cell_no = 6;
n_counts = 60;  % For count action

poll_time =10; %check time in sectons

%if stage drops a point uncomment line and say X or Y to correct that
%axis.you wills ee diaganol features in your data which is a sympotom of
%tis point drop. because data is coming in live there is no way to check
%for point drops until after the scan completes so the below gives you an
%option to fix during live scans.
%filename.axis_fix = 'Y';

%% ******************************************************************************************************************
% Main processing variables
% ******************************************************************************************************************
exp_params.default_loc = 350;          % where the co peak should be found
exp_params.start_offset = 10;           % off set from co peak location for data selection
exp_params.co_peak_thresh = 1e-5;       % co peak level in volt for ac or mod depth for mod data
exp_params.trace_length=500;           % how many points to use in trace for basic processing
exp_params.fit_order = 9;               % thermal removal fit order
exp_params.f_min = 5;
exp_params.f_max = 6;
exp_params.co_peak_range = (-10:150)+exp_params.default_loc;   %search range for co_peak
exp_params.forced_co_peak = 'yes';       % force to use default loc for co peak
exp_params.LPfilter = 40;               % in GHz
exp_params.index_object = 1.57;
exp_params.index_media = 1.33;
exp_params.index_sel_freq = 7;          % freq threshold to decide which index to assign
exp_params.zp = 2^16;
exp_params.lambda = 780e-9;             % wavelength, used in vel conversion
exp_params.laser_freq = 100e6;           % laser rep rate, needed to convert electrical time base to acousticclos
exp_params.delay_freq = 10e3;           % delay rep rate, needed to convert electrical time base to acoustic
exp_params.pump_power =[];              % can be used to store useful exp info with data
exp_params.probe_power=[];              % can be used to store useful exp info with data
exp_params.ac_gain = 12.5;              % ac gain of amp. (12.5 spectra rig, 8 for menlo)
exp_params.plotting_start_offset=100;   % no points before co peak to grab for raw plot data

% plotting vars
exp_params.enable_mask=0;
exp_params.mask_var='ac_amp';
exp_params.mask_threshold = 1e-6;

exp_params.allow_dc =1;                 %this if present and 1 stops DC being processed. make default varibles system to remove things  that are not needed all the time.
%%
%**************************************************************************
%**************************************************************************
%**************************************************************************
%
% You shouldn't need to touch anything below this block!
%
%**************************************************************************
%**************************************************************************
%**************************************************************************

%%
%get scan details
confile = strcat(filebase,run_no);
filename.file_size_check=200;
filename.base = confile;
if fluo~= 1
    [filename,axis_info]=func_live_scan_details(filename,scan_type);
else
    [filename, axis_info] = func_live_scan_details_fluo(filename);
end

% work out the expected final file size of AC from data format and total number of points.
switch filename.meta.format
    case 1
        bytes_per_point=1;
        fmt='int8';
    case 2
        bytes_per_point=2;
        fmt='int16';
    case 3
        bytes_per_point=4;
        fmt='float32';
    otherwise
        disp('Error unknown format');
        data=[];
        return;
end
filesize_final = axis_info.xpts*axis_info.ypts*filename.meta.points_per_trace*bytes_per_point;
currentfileSize = 0;
bytes_per_trace = filename.meta.points_per_trace*bytes_per_point;

%% Hacky fix for multiline scans
filename.dc = filename.dc(cell_no);
filename.dc_samples = filename.dc_samples(cell_no);
stripped = strsplit(filename.dc{:},'_');
filename.metaname = strjoin([stripped(1:end-2), 'scope0.m'],'_');
filename.meta = eval([filename.metaname(1:end-2) '()']);
filename.data = strjoin([stripped(1:end-2), 'scope0.dat'],'_');

axis_info.y = axis_info.x;
axis_info.y_um = axis_info.x_um;
axis_info.ypts = axis_info.xpts;

axis_info.x = 1:n_counts;
axis_info.x_um = axis_info.x;
axis_info.xpts = n_counts;
%% check current DC files for size and work out final size.
if isfield(exp_params,'allow_dc')
    if exp_params.allow_dc==1
        dc_info = dir(filename.dc{1});
        dc_bytes = dc_info.bytes;
        dc_points = axis_info.xpts*axis_info.ypts;
        dc_samples  = filename.dc_samples;
        dc_size_per_point = dc_samples*4;                  %4 for ADC we susually use! this could change depending on ADC setup.
        dc_final_size =dc_points*dc_size_per_point ;
        dc_current =0;
    end
end
%%
count =0;
data=[];k=1;
fh=[];
first_run=1;
while(currentfileSize~=filesize_final)
    %current file size checks for dc and ac
    
    fileInfo = dir(filename.data);
    newfileSize = fileInfo.bytes;
    sizechange = newfileSize-currentfileSize;
    ac_traces_change = floor(sizechange/bytes_per_trace/filename.meta.n_channels);  %complete traces only
    traces_change = ac_traces_change;   %default if no dc present
    
    %if DC is allowed process that too!.
    if isfield(exp_params,'allow_dc')
        if exp_params.allow_dc==1
            dc_info = dir(filename.dc{1});
            dc_bytes = dc_info.bytes;
            dc_size_change = dc_bytes - dc_current;
            dc_traces_change = floor(dc_size_change / dc_size_per_point);                   %complete traces only
            if dc_traces_change==ac_traces_change
                traces_change = ac_traces_change;
            else  %if mismatch between ac and dc, use smallest data set and readjust current sizes to reflect what will be loaded.
                traces_change = min([dc_traces_change ac_traces_change]);
                newfileSize = traces_change *bytes_per_trace*filename.meta.n_channels+currentfileSize;
                dc_bytes = traces_change * dc_size_per_point+ dc_current;
            end
            
        end
    end
    
    local_data.file.trace_no=count;                                                 %assign which trace number we are on
    % loop through as many traces as are current and load and process them.
    for k=1:traces_change;
        fprintf(1,'pixel %d out of %d, %2.1f %% complete\r',count+1,(axis_info.xpts*axis_info.ypts)/filename.meta.n_channels,((count+1)/(axis_info.xpts*axis_info.ypts))*100);
        count = count+1;
        local_data.file.trace_no = count;
        [local_data]= func_live_load_all_data_d_scan(filename,axis_info,exp_params,local_data);         %load data for next trace
        [local_data]= func_live_basic_process_d_scan(local_data,exp_params);                            % process data for this trace
        % all the next stuff is for speed as cant pass pointer to var in
        % matlab so keep all main data arrays in main function so more
        % efficient use of memory
        %first go make all data arrays final size but full of zeros,
        if first_run==1;
            data = local_data;
            for P = 1:filename.meta.n_channels;
                data.ac{P}=zeros(axis_info.xpts,axis_info.ypts,axis_info.no_points);
                if isfield(exp_params,'allow_dc')
                    if exp_params.allow_dc==1
                        data.dc{P}=zeros(axis_info.xpts,axis_info.ypts);
                        data.mod{P}=zeros(axis_info.xpts,axis_info.ypts,axis_info.no_points);
                    end
                end
                data.shifted{P}=zeros(axis_info.xpts,axis_info.ypts,length(local_data.shifted{1})); %this will break if data is shifted!
                data.rawLP{P}=zeros(axis_info.xpts,axis_info.ypts,length(local_data.rawLP{1}));
                data.pro{P}=zeros(axis_info.xpts,axis_info.ypts,length(local_data.pro{1}));
                data.fft{P}=zeros(axis_info.xpts,axis_info.ypts,length(local_data.fft{1}));
                data.freq{P}=zeros(axis_info.xpts,axis_info.ypts);
                data.f_amp{P}=zeros(axis_info.xpts,axis_info.ypts);
                
            end
            first_run =2;
        end
        %copy the data that is changing for each trace into the correct
        %data array, this needs to change if DC is being processed.
        %(automatically?)
        local_fields = {'ac','shifted','rawLP','pro','fft','freq','f_amp'};
        if isfield(exp_params,'allow_dc')
            if exp_params.allow_dc==1
                local_fields = {'ac','dc','mod','shifted','rawLP','pro','fft','freq','f_amp'};
            end
        end
        data.X = local_data.X;                                                                  % current pixel in image x co ord
        data.Y = local_data.Y;                                                                  % current pixel in image x co ord
        for kk = 1:length(local_fields);                                                        % for all fields
            currentfield=local_fields{kk};                                                      % current field to process
            for P=1:filename.meta.n_channels;                                                   % for all channels
                data.(currentfield){P}(data.X,data.Y,:) = local_data.(currentfield){P}   ;      % copy data to correct pixel location
            end
        end
        data.loc = local_data.loc;                          % copy out loc info
        data.copeak_lev = local_data.copeak_lev;            % copy over copeak level info.
    end
    still_live=1;          
    clickable=1;%switch for plotting script if live it disables callback function
    [fh]=func_live_plot_d_scan(data,axis_info,filename,k,exp_params,count,fh,still_live,clickable);    %plot all available data, show most recent traces
    pause(poll_time)
    currentfileSize = newfileSize;        %update filesize for next compare
    
    if isfield(exp_params,'allow_dc')
        if exp_params.allow_dc==1
            dc_current = dc_bytes;
        end
    end
    clear local_data
end
still_live=0;
%% final reload of plots, but turn on pixel selection
[fh]=func_live_plot_d_scan(data,axis_info,filename,k,exp_params,count,fh,still_live,0);


