% function [filename,axis]=func_get_scan_details(confile,cal_y,cal_x)
% takes con file and optionally cal_x cal_y
% confile is parsed to get filenames of data saved
% first data file wfi file is parsed to get scanned details
% axis info is built, using optional cal_x cal_y (defaults present if not)
% only uses these for mirror scanner
% filename and axis contain all scan details.

%%%% (1) %%%  Added pi_stage -- 25/04/16 -- Fernando  

%this function has a number of issues if you try to mix scan types! needs
%major rewrite to fix - RJS mar 2017

%RJS mar 2017 - added code to extract number fo DC samples for live
%processing script.

% WH Oct 2019 - branched to include different axis handling for 1D scans
% with two nested scan actions

function [filename,axis]=func_get_scan_details_fluo(filename,cal_y,cal_x)
if nargin ==1
    cal_y = 33.61;
    cal_x = 48.39;
end
%filename.base = confile;
filename.con = strcat(filename.base,'.con');
display(sprintf('Con file name: %s',filename.con));
txt=file2text(filename.con);
st=size(txt,1);

if strcmp(txt(1),'#2D_fluo')
    [tmp,match]=ismember(txt,{'apt_stage'});
    scan_types = 'fluo';
    axis_loc = find(match==1);
    
    [tmp,match]=ismember(txt,{'count'});
    count_loc = find(match==1);
else
    error('huh')
end
% (1)   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% need section to check for ADC action and if present find out how many ADC samples there are.

adc_action = {'a2d'};
[tmp, match] = ismember(txt,adc_action);
adc_present = find(match==1);
if ~isempty(adc_present)
    [tmp, match] = ismember(txt,{'n_samples'});
    sample_loc = find(match==1);
    for k=1:length(sample_loc)
    filename.dc_samples(k) = str2double(txt(sample_loc(k)+1));
    end
end
%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% READ THIS IF YOU GET ERRORS IN THE BELOW
% this section reads the parsed txt version of scan file looking for scan
% actions, it then grabs the useful info - this is done in a easy to break
% manner as it assumes the varibles in each action are always in the same
% order and format is consistant.
% at some point i may fix this to search for the specific varible strings
% within each action but as there may be a global scan action soon i havent
% done this yet.
switch scan_types
    case 'fluo'
        for k = 1:length(axis_loc)
            axis.number(k) = str2double(txt(axis_loc(k)+2));
            start_val(k) = str2double(txt(axis_loc(k)+4));
            step(k) = str2double(txt(axis_loc(k)+6));
            finish(k) = str2double(txt(axis_loc(k)+5));
        end
        axis.x =1000* (start_val(1):step(1):finish(1));
        axis.x_um = axis.x;
        axis.xpts = length(axis.x);
        if k==2
            % The number of y points is given by the axis settings, but
            % also by the repeats of the same scan - hence repmat
            %axis.y = [1000*(start_val(2):step(2):finish(2)), 1001*(start_val(2):step(2):finish(2))];
            tmp = 1000*(start_val(2):step(2):finish(2));
            axis.y = zeros(1,length(tmp)*str2double(txt(count_loc(1) + 2)));
            for idx = 1:str2double(txt(count_loc(1) + 2))
                axis.y(1+(idx-1)*length(tmp):idx*length(tmp)) = tmp + (idx -1)* max(tmp);
            end
            axis.y_um = axis.y;
            axis.ypts = length(axis.y);
        else
            axis.y=0;
            axis.y_um = axis.y;
            axis.ypts = length(axis.y);
        end
    case 'mirror_pbp'
        for k = 1:length(loc)
            axis.number(k) = str2double(txt(loc(k)+2));
            start_val(k) = str2double(txt(loc(k)+2+1));
            step(k) = str2double(txt(loc(k)+2+3));
            finish(k) = str2double(txt(loc(k)+2+2));
        end
        axis.x = start_val(1):step(1):finish(1);
        axis.y = start_val(2):step(2):finish(2);
        axis.y_um = axis.y*cal_y;  %calibration values for mirror scanner
        axis.x_um = axis.x*cal_x;  %calibration values for mirror scanner
        axis.xpts = length(axis.x);
        axis.ypts = length(axis.y);
    case 'apt_stage'
        for k = 1:length(loc)
            axis.number(k) = str2double(txt(loc(k)+2));
            start_val(k) = str2double(txt(loc(k)+2+2));
            step(k) = str2double(txt(loc(k)+2+4));
            finish(k) = str2double(txt(loc(k)+2+3));
        end
        axis.x =1000* (start_val(1):step(1):finish(1));
        axis.x_um = axis.x;
        axis.xpts = length(axis.x);
        if k==2
            axis.y = 1000*(start_val(2):step(2):finish(2));
            axis.y_um = axis.y;
            axis.ypts = length(axis.y);
        else
            axis.y=0;
            axis.y_um = axis.y;
            axis.ypts = length(axis.y);
        end
    case 'count'
        for k = 1
            axis.number(k) = 1;
            start_val(k) = 1;
            step(k) = 1;
            finish(k) = str2double(txt(loc(k)+2));
        end
        axis.x = start_val(1):step(1):finish(1);
        axis.y = 1;
        axis.y_um = axis.y;
        axis.x_um = axis.x;
        axis.xpts = length(axis.x);
        axis.ypts = length(axis.y);
    case 'd2a_phidget'
        for k = 1
            axis.number(k) = 1;
            start_val(k) = str2double(txt(loc(k)+4));
            step(k) =  str2double(txt(loc(k)+6));
            finish(k) = str2double(txt(loc(k)+5));
        end
        axis.x = start_val(1):step(1):finish(1);
        axis.y = 1;
        axis.y_um = axis.y;
        axis.x_um = axis.x;
        axis.xpts = length(axis.x);
        axis.ypts = length(axis.y);
        %%%%%%%%%%%%%%%%%%%%%55   Fernando added for rotation test
        %%%%%%%%%%%%%%%%%%%%% Not WORKING YET
        
    case 'script'
        for k = 1
            axis.number(k) = 1;
            start_val(k) = str2double(txt(loc(k)+1))
            %start_val(k) = (txt(loc(k)+3))
            step(k) =  str2double(txt(loc(k)+3))
            finish(k) = str2double(txt(loc(k)+2))
        end
        axis.x = start_val(1):step(1):finish(1);
        axis.y = 1;
        axis.y_um = axis.y;
        axis.x_um = axis.x;
        axis.xpts = length(axis.x);
        axis.ypts = length(axis.y);
        
        
        %  (1)  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
    case 'pi_stage'
        for k = 1:length(loc)
            axis.number(k) = str2double(txt(loc(k)+2));
            start_val(k) = str2double(txt(loc(k)+2+2));
            finish(k) = str2double(txt(loc(k)+2+4));
            step(k) = str2double(txt(loc(k)+2+3));
        end
        axis.x = start_val(1):finish(1):step(1);
        axis.x_um = axis.x;
        axis.xpts = length(axis.x);
        if k==2
            axis.y = start_val(2):finish(2):step(2);
            axis.y_um = axis.y;
            axis.ypts = length(axis.y);
        else
            axis.y=0;
            axis.y_um = axis.y;
            axis.ypts = length(axis.y);
        end
        %  (1) %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
end

filename.scan_type = scan_types;

tmp = dir([filename.base '_*.m']);
filename.metaname = tmp.name;
filename.meta = feval(filename.metaname(1:end-2));
dctmp = dir([filename.base '_*.d']);

for k = 1:length(dctmp)
    filename.dc{k} = dctmp(k).name;
end

axis.no_points = filename.meta.points_per_trace;
axis.no_traces=filename.meta.n_traces;
filename.data = filename.meta.dataname;

%filesizecheck section incase scan dropped point;
fileInfo = dir(filename.data);
size_actual = fileInfo.bytes;

size_expected = axis.xpts.*axis.ypts*filename.meta.format*filename.meta.points_per_trace*filename.meta.n_channels;
if size_actual - size_expected ~=0;
    warning backtrace off
    warning('actual and expected size mismatch, attempting to resolve');
    if axis.xpts~= axis.ypts
        display('x and y points different')
        size_x_tmp = (axis.xpts-1).*axis.ypts*filename.meta.format*filename.meta.points_per_trace*filename.meta.n_channels;
        size_y_tmp = axis.xpts.*(axis.ypts-1)*filename.meta.format*filename.meta.points_per_trace*filename.meta.n_channels;
        size_xy_tmp = (axis.xpts-1).*(axis.ypts-1)*filename.meta.format*filename.meta.points_per_trace*filename.meta.n_channels;
        switch size_actual
            case size_x_tmp
                display('dropped a point from X, sizes now match')
                axis.xpts =axis.xpts-1;
                axis.x = axis.x(1:end-1);
                axis.x_um = axis.x_um(1:end-1);
            case size_y_tmp
                display('dropped a point from Y, sizes now match')
                axis.ypts = axis.ypts -1;
                axis.y = axis.y(1:end-1);
                axis.y_um = axis.y_um(1:end-1);
            case size_xy_tmp
                display('dropped a point from X and Y, sizes now match')
                axis.ypts = axis.ypts -1;
                axis.xpts =axis.xpts-1;
                axis.y = axis.y(1:end-1);
                axis.y_um = axis.y_um(1:end-1);
                axis.x = axis.x(1:end-1);
                axis.x_um = axis.x_um(1:end-1);
            otherwise
                error('not enough data for number of points')
        end
    else
        size_new_expected = (axis.xpts-1).*(axis.ypts-1)*filename.meta.format*filename.meta.points_per_trace*filename.meta.n_channels;
        if size_actual - size_new_expected ==0;
            fprintf(1,'x and y axis have both dropped a point. \n');
            axis.xpts =axis.xpts-1;
            axis.ypts = axis.ypts -1;
            axis.y = axis.y(1:end-1);
            axis.y_um = axis.y_um(1:end-1);
            axis.x = axis.x(1:end-1);
            axis.x_um = axis.x_um(1:end-1);
        else
            fprintf(1,'x and y points the same so ambiguous, using user choice of : %s  :',filename.axis_fix);
            %display([size_actual size_expected size_actual - size_expected]);
            switch filename.axis_fix
                case 'X'
                    display('dropped a point from X, sizes now match')
                    axis.xpts =axis.xpts-1;
                    axis.x = axis.x(1:end-1);
                    axis.x_um = axis.x_um(1:end-1);
                case 'Y'
                    display('dropped a point from Y, sizes now match')
                    axis.ypts = axis.ypts -1;
                    axis.y = axis.y(1:end-1);
                    axis.y_um = axis.y_um(1:end-1);
                otherwise
                    error('filename.axis_fix doesnt contain X or Y')
            end
        end
    end
end




