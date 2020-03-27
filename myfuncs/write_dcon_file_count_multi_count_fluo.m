function [] = write_dcon_file_count_multi_count_fluo(~,~,origin,count,channel,a2dchannel,confilename,lab)
% Experimental design: Fluo image, then 1 point count, then another fluo
% image, at each origin given, repeated for a number of reps
% action count (n_reps)
%     for each origin:
%         action move to origin
%         action fluo
%         action laserson
%         action count (n_count)
%         action scope etc
%         action lasersoff
%         action fluo
%
% count  inputs as [n_count, n_reps]
% origin inputs as [X1, Y1; X2, Y2;...]
% axis   not needed



%Three action sets - fluorescent imaging, move to a point, and data
%collection
act_fluo = ['\t' 'action script \n'...
            '\t\t' 'script %son\n'... %s
            '\t' 'end\n'...
            '\t' 'action webcam\n'...
            '\t\t' 'camera 0\n'...
            '\t\t' 'resolution 1600 1200\n'...
            '\t\t' 'grab\n'...
            '\t' 'end\n'...
            '\t' 'action script \n'...
            '\t\t' 'script %soff\n'... %s
            '\t' 'end\n\n'];

act_move = ['\t' 'action apt_stage\n'...
            '\t\t' 'axis0\n'...
            '\t\t' 'scan %g %g %g\n'... %g %g %g
            '\t' 'end\n'...
            '\t' 'action apt_stage\n'...
            '\t\t' 'axis 1\n'...
            '\t\t' 'scan %g %g %g\n'...%g %g %g
            '\t' 'end\n\n'];
        
act_data = ['\t' 'action script\n'...
            '\t\t' 'scripts laserson\n'...
            '\t' 'end\n'...
            '\t' 'action count\n'...
            '\t\t' 'count %i\n'...      %i
            '\t\t' 'action scope\n'...
            '\t\t\t' 'channels %s\n'... %s
            '\t\t\t' 'ip %s\n'...       %s
            '\t\t' 'end\n\n'...
            '\t\t' 'action a2d\n'...
            '\t\t\t' 'channel %g\n'...  %g
            '\t\t\t' 'range 1\n'...
            '\t\t\t' 'sample_rate 10000\n'...
            '\t\t\t' 'n_samples 1000\n'...
            '\t\t' 'end\n'...
            '\t' 'end\n'...
            '\t' 'action script\n'...
            '\t\t' 'scripts lasersoff\n'...
            '\t' 'end\n\n'];
            
if strcmp(lab,'ASOPS')==1
    ip = '192.168.74.15';
elseif strcmp(lab,'PLU')==1
    ip = '128.243.74.74';
end

% Open file for writing and put comment header with scan type
fid = fopen(confilename,'w');
fprintf(fid,'#2D_fluo\n');

% Count action contains all the other actions - scans and pictures
fprintf(fid,'action count\n\tcount %i\n\n', count(2));

for loc = 1:size(origin,1)
    % Move to cell
    fprintf(fid, act_move, ...
        origin(loc, 1), origin(loc, 1), 0, origin(loc, 1), origin(loc, 1), 0);
    % Take two fluorescent images
    for colour = {'blue','green'}
        fprintf(fid,act_fluo,colour{:},colour{:});
    end
    % Turn on lasers, take data, turn off lasers
    fprintf(fid, act_data, count(1), channel, ip, a2dchannel);
    % Take two more fluorescent images
    for colour = {'blue','green'}
        fprintf(fid,act_fluo,colour{:},colour{:});
    end
end

fprintf(fid,'end\n');


fclose(fid);



end
