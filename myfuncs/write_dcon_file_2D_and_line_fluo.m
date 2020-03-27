function [] = write_dcon_file_2D_and_line_fluo(axis0,axis1,origin,count,channel,a2dchannel,confilename,lab)

% Open file for writing and put comment header with scan type
fid = fopen(confilename,'w');
fprintf(fid,'#2D_and_line_fluo\n');

%Two action sets - fluorescent imaging and phonon scanning
act_fluo = ['\taction script \n'...
            '\t\tscript %son\n'...
            '\tend\n'...
            '\taction webcam\n'...
            '\t\tcamera 0\n'...
            '\t\tresolution 1600 1200\n'...
            '\t\tgrab\n'...
            '\tend\n'...
            '\taction script \n'...
            '\t\tscript %soff\n'...
            '\tend\n\n'];

act_scan = ['action apt_stage\n'...
            '\taxis 0\n'...
            '\tscan %g %g %g\n'...
            '\trestore\n\n'...
            '\taction apt_stage\n'...
            '\t\taxis 1\n'...
            '\t\tscan %g %g %g\n'...
            '\t\trestore\n'...
            '\t\tsave\n\n'...
            '\t\taction scope\n'...
            '\t\t\tchannels %s\n'...
            '\t\t\tip %s\n'...
            '\t\tend\n\n'...
            '\t\taction a2d\n'...
            '\t\t\tchannel %g\n'...
            '\t\t\trange 1\n'...
            '\t\t\tsample_rate 10000\n'...
            '\t\t\tn_samples 1000\n'...
            '\t\tend\n\n'...
            '\tend\n'...
            'end\n'];

if strcmp(lab,'ASOPS')==1
    ip = '192.168.74.15';
elseif strcmp(lab,'PLU')==1
    ip = '128.243.74.74';
end
        
%% Take two fluorescent images
for colour = {'blue','green'}
    fprintf(fid,act_fluo,colour{:},colour{:});
end
%% Do a 2D scan
fprintf(fid,act_scan,origin(1,1)+axis0(1,1)/1000,...
        origin(1,1)+axis0(1,2)/1000,axis0(1,3)/1000,...
        origin(1,2)+axis1(1,1)/1000,...
        origin(1,2)+axis1(1,2)/1000,axis1(1,3)/1000,...
        channel,ip, num2str(a2dchannel));
%% Another 2 fluorescent images
for colour = {'blue','green'}
    fprintf(fid,act_fluo,colour{:},colour{:});
end
%% Repeat a line scan
fprintf(fid,['action count\n'...
             '\tcount %i\n'],count);
fprintf(fid,act_scan,origin(2,1)+axis0(2,1)/1000,...
        origin(2,1)+axis0(2,2)/1000,axis0(2,3)/1000,...
        origin(2,2)+axis1(2,1)/1000,...
        origin(2,2)+axis1(2,2)/1000,axis1(2,3)/1000,...
        channel,ip, num2str(a2dchannel));
fprintf(fid,'end\n');
%% Another 2 fluorescent images
for colour = {'blue','green'}
    fprintf(fid,act_fluo,colour{:},colour{:});
end
%% Final 2D scan
fprintf(fid,act_scan,origin(3,1)+axis0(3,1)/1000,...
        origin(3,1)+axis0(3,2)/1000,axis0(3,3)/1000,...
        origin(3,2)+axis1(3,1)/1000,...
        origin(3,2)+axis1(3,2)/1000,axis1(3,3)/1000,...
        channel,ip, num2str(a2dchannel));
%% Another 2 fluorescent images
for colour = {'blue','green'}
    fprintf(fid,act_fluo,colour{:},colour{:});
end

fclose(fid);



end
