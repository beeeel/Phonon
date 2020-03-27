% Axis info needs a scan# field for each scan/origin
% This can basically be copied
% Filename also needs to have the correct number of scan# fields
n_scans = length(filename.scan1.dc);
scanNos = zeros(1,n_scans);
for idx = 1:n_scans
    tmp = strsplit(filename.scan1.dc{idx},'_');
    tmp = tmp{4}(8:end);
    scanNos(idx) = str2double(tmp);
end
[~, scanNos] = sort(scanNos);

tmp = axis_info.scan1.axis1;
axis_info.scan1.axis1 = axis_info.scan1.axis2;
axis_info.scan1.axis2 = axis_info.scan1.axis3;
axis_info.scan1.axis3 = tmp;
axis_info.scan1.axis_pts = axis_info.scan1.axis_pts([2,3,1]);
for idx = 2:n_scans
    scanNo = strcat('scan',num2str(idx));
    filename.(scanNo).metaname = [filename.scan1.dc{scanNos(idx)}(1:end-9) 'scope0.m'];
    filename.(scanNo).meta = feval(filename.(strcat('scan',num2str(idx))).metaname(1:end-2));
    filename.(scanNo).dc = filename.scan1.dc(scanNos(idx));
    filename.(scanNo).dc_channel = filename.scan1.dc_channel(idx);
    filename.(scanNo).dc_samples = filename.scan1.dc_samples(idx);
    filename.(scanNo).dc_bytes = filename.scan1.dc_bytes(idx);
    filename.(scanNo).ac = [filename.scan1.dc{idx}(1:end-9) 'scope0.dat'];
    axis_info.(scanNo).axis1 = axis_info.scan1.axis1;
    axis_info.(scanNo).axis2 = axis_info.scan1.axis2;
    axis_info.(scanNo).axis3 = axis_info.scan1.axis3;
    axis_info.(scanNo).axis_pts = axis_info.scan1.axis_pts;
    axis_info.(scanNo).axis_order = axis_info.scan1.axis_order;
    axis_info.(scanNo).points_per_trace = axis_info.scan1.points_per_trace;
    axis_info.(scanNo).no_traces = axis_info.scan1.no_traces;
    axis_info.(scanNo).no_channels = axis_info.scan1.no_channels;
end
axis_info.number_of_scans = idx;
axis_info.number_of_axes = axis_info.number_of_axes * ones(1,idx);
filename.scan1.dc = filename.scan1.dc(1);
filename.scan1.dc_channel = filename.scan1.dc_channel(1);
filename.scan1.dc_samples = filename.scan1.dc_samples(1);
filename.scan1.dc_bytes = filename.scan1.dc_bytes(1);
clear scanNo idx tmp n_scans scanNos