function [filename, axis_info]=get_scan_details_multiscan(filename)

allowed_scan_types = {'apt_stage','pi_stage','count','d2a_phidget'};        %scan action names
% Note: Bytes per sample on a2d depends on the card. Most cards use l_sampl
% which is 4.
a2d_bytes_per_point=4;                                                      %hard coded not stored anywhere so i need o make this a fixed varible, think the d_scan sets this so shouldnt need to be changed....


filename.con = strcat(filename.base,'.con');
display(sprintf('Con file name: %s',filename.con));

%% read confile
txt=file2text(filename.con);
st=size(txt,1);
[tmp,match_action]=ismember(txt,{'action'});
[tmp,match_end]=ismember(txt,{'end'});

%% set up some varibles needed later
action_list = [];
action_location =[];
action_end=[];
action_scan_location=[];
action_location2 = zeros(1,max([length(match_action) length(match_end)]));
action_end2 = zeros(1,max([length(match_action) length(match_end)]));
action_scan_location2 = zeros(1,max([length(match_action) length(match_end)]));
action_scan_closed = zeros(1,max([length(match_action) length(match_end)]));
%% find action names and start/end locations
for k=1:(length(match_action)-1)
    if match_action(k)
        action_list{end+1}= txt{(k+1)} ;
        action_location(end+1) = k+1;
        action_location2(k) = 1;
        switch txt{(k+1)}
            case allowed_scan_types
                action_is_scan(k)=1;
                action_scan_location(end+1)=k+1;
                action_scan_location2(k)=1;
            otherwise
                action_is_scan(k) =0;
        end
    end
end
for k=1:(length(match_end))
    if match_end(k)
        action_end(end+1) = k;
        action_end2(k) = 1;
    end
end
%% look for opening and ending actions
scans = cumsum(action_scan_location2);
all_actions = cumsum(action_location2);
ends = cumsum(action_end2);
open_actions = all_actions - ends;
non_scan_actions_open = open_actions -scans;
for k = 1:length(ends)
    if non_scan_actions_open(k) <0
        action_scan_closed  (k) =1;
        non_scan_actions_open(k:end)=non_scan_actions_open(k:end)+1;
    end
end
[action_scan_location2' action_scan_closed'];

tmp = action_scan_location2-action_scan_closed;
%opened actions adjusted for where scan actions close, this is for nested scan calcs
open_none_scan_actions = cumsum(tmp);  
%% Find the number of nested scans, then check how many axes for each.

% New scans are when the number of open scans is lower than at the last
% scan action
tmp = open_none_scan_actions(action_scan_location(2:end)) <= open_none_scan_actions(action_scan_location(1:end-1));
new_scan = action_scan_location([true tmp]);
% The number of axes is the largest number of open scans between opening a
% scan, and the next new scan starting. This has not been extensively
% tested.
for k = 1:length(new_scan)
    if k ~= length(new_scan)
        num_axis(k) = max(open_none_scan_actions(new_scan(k):new_scan(k+1)-2));
    else
        num_axis(k) = max(open_none_scan_actions(new_scan(k):end));
    end
end
% Below is Richard's original code. This fails when there are multiple
% scans within a count
%
% %% find number of nested scans, then loop through and check how many axes
% k=1;
% not_end_of_file=1;
% while not_end_of_file;
%     if k==1
%         loc1(k) = find(open_none_scan_actions(1:end)==1,1);
%     else
%         if ~isempty(find(open_none_scan_actions(loc2(k-1):end)))
%             loc1(k) = -1+loc2(k-1)+find(open_none_scan_actions(loc2(k-1):end)==1,1);
%         else
%             not_end_of_file=0;
%             %break
%         end
%     end
%     loc2(k) = -1+loc1(k)+find(open_none_scan_actions(loc1(k):end)==0,1);
%     % Get the number of times the number of open scans goes up
% %     tmp = open_none_scan_actions(loc1(k):loc2(k)-1) < open_none_scan_actions(loc1(k)+1:loc2(k));
% %     if tmp == 1
%         num_axis(k) = max(open_none_scan_actions(loc1(k):loc2(k)));
% %     else
% %         num_axis(k) = 
%     if loc2(k) == length(open_none_scan_actions)
%         not_end_of_file=0;
%     else
%         k=k+1;
%     end
% end

%%
%now we have scans and axis, we shoudl query each scan action to get the
%scan parameters axis and scan start stop inc


count =1;
for k = 1:length(action_location);
    if any(action_location(k)==(action_scan_location))
        input_text = txt(action_location(k):action_location(k+1)-2);
        switch input_text{+1}
            case {'apt_stage','pi_stage'}
                [tmp,match_axis]=ismember(input_text,{'axis'});
                [tmp_loc] = find(match_axis==1,1);
                axis_value (count)= str2num(input_text{tmp_loc+1});
                [tmp,match_scan]=ismember(input_text,{'scan'});
                [tmp_loc] = find(match_scan==1,1);
                scan_start(count) = str2num(input_text{tmp_loc+1});
                scan_stop(count) = str2num(input_text{tmp_loc+2});
                scan_inc(count) = str2num(input_text{tmp_loc+3});
            case{'count'}
                [tmp,match_scan]=ismember(input_text(2:end),{'count'});
                [tmp_loc] = find(match_scan==1,1);
                axis_value (count)=0;
                scan_start(count) = 1;
                scan_stop(count) = str2num(input_text{1+tmp_loc+1});  %extra +1 as trimmed first count off the input text
                scan_inc(count) = 1;
            case('d2a_phidget')
                 [tmp,match_axis]=ismember(input_text,{'channel'});
                [tmp_loc] = find(match_axis==1,1);
                axis_value (count)= str2num(input_text{tmp_loc+1});
                [tmp,match_scan]=ismember(input_text,{'pbp_scan'});
                [tmp_loc] = find(match_scan==1,1);
                scan_start(count) = str2num(input_text{tmp_loc+1});
                scan_stop(count) = str2num(input_text{tmp_loc+2});
                scan_inc(count) = str2num(input_text{tmp_loc+3});
            otherwise
                fprintf(1,'scan type not found, allowed scan actions are :\n');
                fprintf(1,'\t %s \n',allowed_scan_types{:});
                fprintf(1,'\n');
        end
        count=count+1;
    end
    
end

% check if ADC actions are present
count =1;
for k =1:length(action_list)
    switch action_list{k}
        case 'a2d'
            if k==length(action_list)
                input_text = txt(action_location(k):end);
            else
             input_text = txt(action_location(k):action_location(k+1)-2);    
            end
            [tmp,match_axis]=ismember(input_text,{'channel'});
            [tmp_loc] = find(match_axis==1,1);
            a2d.channel (count)= str2num(input_text{tmp_loc+1});
            [tmp,match_axis]=ismember(input_text,{'n_samples'});
            [tmp_loc] = find(match_axis==1,1);
            a2d.samples (count)= str2num(input_text{tmp_loc+1});
            a2d.bytes (count)=a2d_bytes_per_point;                                                 %hard coded not stored anywhere so i need o make this a fixed varible...
        count = count+1;
        otherwise
    end
end
%% build axis_info for the scans and axes found

% I think we need to rever the order of these as we want fast axis to be
% x,then y, then outermost slowest is z, this is how the data get saved and
% loaded.

ax_count = 0;
axis_info.number_of_scans = length(num_axis);
axis_info.number_of_axes = num_axis;
for k = 1:axis_info.number_of_scans
    % Will's method - calculate number of axes already counted
    % Check how many scans were open before the next one (finds counts
    % containing multiple distinct scans)
    
    % Find word 2 before the name of this scan (i.e. 1 before "action")
    loc = action_scan_location(ax_count+1)-2;
    % If this is a "non-root" scan there is an action open already, so
    % first get the details for the "root" scan
    if open_none_scan_actions(loc) > 0
        j0 = 2;
        j2 = axis_info.number_of_axes(k);
        % Find the "root" scan which is reused
        tmp = loc - find(open_none_scan_actions(loc:-1:1)==0,1,'first') + 3;
        tmp2 = find(tmp == action_scan_location,1,'first');
        
        axis_info.(strcat('scan',num2str(k))).(strcat('axis',num2str(j2))).type =txt{tmp};
        axis_info.(strcat('scan',num2str(k))).(strcat('axis',num2str(j2))).start=scan_start(tmp2);
        axis_info.(strcat('scan',num2str(k))).(strcat('axis',num2str(j2))).stop= scan_stop(tmp2);
        axis_info.(strcat('scan',num2str(k))).(strcat('axis',num2str(j2))).inc= scan_inc(tmp2);
        axis_info.(strcat('scan',num2str(k))).(strcat('axis',num2str(j2))).um = scan_start(tmp2):scan_inc(tmp2):scan_stop(tmp2);
        axis_info.(strcat('scan',num2str(k))).(strcat('axis',num2str(j2))).pts = length(axis_info.(strcat('scan',num2str(k))).(strcat('axis',num2str(j2))).um);
        axis_info.(strcat('scan',num2str(k))).axis_pts(j2) =axis_info.(strcat('scan',num2str(k))).(strcat('axis',num2str(j2))).pts ;
        axis_info.(strcat('scan',num2str(k))).axis_order{j2} =txt{action_scan_location(tmp2)};
    else
        j0 = 1;
    end
%     disp(k);
    for j= j0:axis_info.number_of_axes(k)
        ax_no = j + ax_count - j0 + 1;
%         fprintf('scan %i: \tj = %i\taxis number %i\t ax_count = %i\n',k, j, ax_no, ax_count)
        j2 = axis_info.number_of_axes(k)-(j-1);
        % Will's method
        axis_info.(strcat('scan',num2str(k))).(strcat('axis',num2str(j2))).type =txt{action_scan_location(ax_no)};
        axis_info.(strcat('scan',num2str(k))).(strcat('axis',num2str(j2))).start=scan_start(ax_no);
        axis_info.(strcat('scan',num2str(k))).(strcat('axis',num2str(j2))).stop= scan_stop(ax_no);
        axis_info.(strcat('scan',num2str(k))).(strcat('axis',num2str(j2))).inc= scan_inc(ax_no);
        axis_info.(strcat('scan',num2str(k))).(strcat('axis',num2str(j2))).um = scan_start(ax_no):scan_inc(ax_no):scan_stop(ax_no);
        axis_info.(strcat('scan',num2str(k))).(strcat('axis',num2str(j2))).pts = length(axis_info.(strcat('scan',num2str(k))).(strcat('axis',num2str(j2))).um);
        axis_info.(strcat('scan',num2str(k))).axis_pts(j2) =axis_info.(strcat('scan',num2str(k))).(strcat('axis',num2str(j2))).pts ;
        axis_info.(strcat('scan',num2str(k))).axis_order{j2} =txt{action_scan_location(ax_no)};
        
        % Richard's method - fails when multiple 2D scans are nested in a
        % single count
%         axis_info.(strcat'scan',num2str(k))).(strcat('axis',num2str(j2))).type =txt{action_scan_location(j+(k-1)*axis_info.number_of_scans)};
%         axis_info.(strcat('scan',num2str(k))).(strcat('axis',num2str(j2))).start=scan_start(j+(k-1)*axis_info.number_of_scans);
%         axis_info.(strcat('scan',num2str(k))).(strcat('axis',num2str(j2))).stop= scan_stop(j+(k-1)*axis_info.number_of_scans);
%         axis_info.(strcat('scan',num2str(k))).(strcat('axis',num2str(j2))).inc= scan_inc(j+(k-1)*axis_info.number_of_scans);
%         axis_info.(strcat('scan',num2str(k))).(strcat('axis',num2str(j2))).um = scan_start(j+(k-1)*axis_info.number_of_scans):scan_inc(j+(k-1)*axis_info.number_of_scans):scan_stop(j+(k-1)*axis_info.number_of_scans);
%         axis_info.(strcat('scan',num2str(k))).(strcat('axis',num2str(j2))).pts = length(axis_info.(strcat('scan',num2str(k))).(strcat('axis',num2str(j2))).um);
%         axis_info.(strcat('scan',num2str(k))).axis_pts(j2) =axis_info.(strcat('scan',num2str(k))).(strcat('axis',num2str(j2))).pts ;
%         axis_info.(strcat('scan',num2str(k))).axis_order{j2} =txt{action_scan_location(j+(k-1)*axis_info.number_of_scans)};

    end
    ax_count = ax_count + axis_info.number_of_axes(k)-j0+1;
    
end

%%
%section to check for .m and .dat files and ADC files for DC etc
tmp = dir([filename.base '_*.m']);
dctmp = dir([filename.base '_*.d']);
for k = 1:axis_info.number_of_scans
    % Gotta apply order fix if it's available (d_scan files aren't created
    % alphabetically)
    if isfield(filename,'order_fix')
        filename.(strcat('scan',num2str(k))).metaname = tmp(filename.order_fix(k)).name;
    else 
        filename.(strcat('scan',num2str(k))).metaname = tmp(k).name;
    end
    
    filename.(strcat('scan',num2str(k))).meta = feval(filename.(strcat('scan',num2str(k))).metaname(1:end-2));
    % Number of A2Ds per scan
    if exist('a2d','var')
        tmp2 = length(a2d.channel)/axis_info.number_of_scans;
        % For each A2D
        for j= 1:tmp2
            if (j+(k-1)*tmp2) > length(a2d.channel)
                error('You''re trying to load more A2Ds than there are files');
            end
            if isfield(filename,'order_fix')
                filename.(strcat('scan',num2str(k))).dc{j} = dctmp(j+filename.order_fix(k)*tmp2-1).name;
            else
                filename.(strcat('scan',num2str(k))).dc{j} = dctmp(j+(k-1)*tmp2).name;
            end
            filename.(strcat('scan',num2str(k))).dc_channel(j) = a2d.channel(j+(k-1)*tmp2);
            filename.(strcat('scan',num2str(k))).dc_samples(j) =a2d.samples(j+(k-1)*tmp2);
            filename.(strcat('scan',num2str(k))).dc_bytes(j) = a2d.bytes(j+(k-1)*tmp2);
        end
    end
    filename.(strcat('scan',num2str(k))).ac = filename.(strcat('scan',num2str(k))).meta.dataname;
    axis_info.(strcat('scan',num2str(k))).points_per_trace = filename.(strcat('scan',num2str(k))).meta.points_per_trace;
    axis_info.(strcat('scan',num2str(k))).no_traces=filename.(strcat('scan',num2str(k))).meta.n_traces/filename.(strcat('scan',num2str(k))).meta.n_channels;
    axis_info.(strcat('scan',num2str(k))).no_channels=filename.(strcat('scan',num2str(k))).meta.n_channels;
end
%filesizecheck section to make sure everythign is as expected;
for k = 1:axis_info.number_of_scans
    %check ac files
    fileInfo = dir(filename.(strcat('scan',num2str(k))).ac);
    size_actual = fileInfo.bytes;
    size_expected = prod(axis_info.(strcat('scan',num2str(k))).axis_pts)*filename.(strcat('scan',num2str(k))).meta.format*filename.(strcat('scan',num2str(k))).meta.points_per_trace*filename.(strcat('scan',num2str(k))).meta.n_channels;
    if ~(size_actual==size_expected)
        error('AC filesize not as expected: actual %g vs expected %g for %s',size_actual,size_expected,strcat('scan',num2str(k)));
    end
    %check dc files.
    if exist('a2d', 'var')
        for j = 1:length(filename.(strcat('scan',num2str(k))).dc)
            fileInfo = dir(filename.(strcat('scan',num2str(k))).dc{j});
            size_actual = fileInfo.bytes;
            size_expected = prod(axis_info.(strcat('scan',num2str(k))).axis_pts)*filename.(strcat('scan',num2str(k))).dc_samples(j)*filename.(strcat('scan',num2str(k))).dc_bytes(j);
            if ~(size_actual==size_expected)
                error('DC filesize not as expected: actual %g vs expected %g for %s',size_actual,size_expected,strcat('scan',num2str(k),': dc file :',num2str(j)));
            end
        end
    end
end
