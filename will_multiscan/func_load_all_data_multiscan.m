%function [data] = func_load_all_data(filename,axis,exp_params)
% function to load all the data, looks for ac and dc in filename to work
% out what's what. if have equal numbers of ac and dc data it makes
% modulation depth.
% code can use forced default co peak location, or find it. it uses the
% first set of ac data to do this and then uses same locations for all
% other ac data sets.

% 26/04/16 Commented line 77 because it make error when no DC -Fernando


function [data] = func_load_all_data_multiscan(filename,axis_info,exp_params)

filename_save = strcat(strip_suffix(filename.con,'.con'),'_','data.mat');

if (exist(filename_save,'file')==2)&&(exp_params.force_process~=1);
    display(sprintf('Previously saved data loaded from %s',filename_save));
    load(filename_save);
    data.loadedsave=1;
else
    %open ac data
    for s = 1:axis_info.number_of_scans;
        
        current_scan =(strcat('scan',num2str(s)));
        fi=fopen(filename.(current_scan).meta.dataname,'r');
        switch filename.(current_scan).meta.format
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
        fi=fopen(filename.(current_scan).meta.dataname,'r');
        
        disp('loading all traces');
        traces=[1:filename.(current_scan).meta.n_traces];
        data_tmp=zeros(length(traces),filename.(current_scan).meta.points_per_trace);
        for i=1:length(traces)
            %fprintf(1,'loading trace %d \n',i);
            fseek(fi,(traces(i)-1)*filename.(current_scan).meta.points_per_trace*bytes_per_point,'bof');
            data_tmp(i,:)=fread(fi,filename.(current_scan).meta.points_per_trace,fmt);
        end;
        % reshape data into channels
        data_tmp2 = reshape(data_tmp,length(filename.(current_scan).meta.channels),filename.(current_scan).meta.n_traces/filename.(current_scan).meta.n_channels,filename.(current_scan).meta.points_per_trace);
        for k=1:filename.(current_scan).meta.n_channels
            data_tmp3 =squeeze(data_tmp2(k,:,:)*filename.(current_scan).meta.vgain(k)+filename.(current_scan).meta.voff(k));
            %not sure axis order is correct for order in save file, testing
            %with (end:-1:1) to reverse axis order.
            array_size = [axis_info.(current_scan).axis_pts axis_info.(current_scan).points_per_trace];
            tmp =  double(reshape(data_tmp3,array_size))./exp_params.ac_gain;
            %tmp = permute(tmp,[(ndims(tmp)-1:-1:1) ndims(tmp)]);
            data.(current_scan).ac{k} = squeeze(tmp);%
        end
        
        t=[0:(filename.(current_scan).meta.points_per_trace-1)]*filename.(current_scan).meta.hint+filename.(current_scan).meta.hoff;
        data.(current_scan).t = double(t/(exp_params.laser_freq/exp_params.delay_freq));;
        
        
        
        
        if isfield(filename.(current_scan),'dc')
            for k = 1:length(filename.(current_scan).dc)
                fileID = fopen(filename.(current_scan).dc{k},'r');
                [tmp points] = fread(fileID,'float32');
                fclose(fileID);
                
                dc_array_size = [filename.(current_scan).dc_samples(k) axis_info.(current_scan).axis_pts ];
                
                axis_info.(current_scan).dc_samples = points ./prod(axis_info.(current_scan).axis_pts);
                data.(current_scan).dc{k} = squeeze(mean(reshape(tmp,dc_array_size),1));
                data.(current_scan).dc_count =length(data.(current_scan).dc);
            end
            
        else
            data.(current_scan).dc_count =0;
        end
        data.(current_scan).ac_count =length(data.(current_scan).ac);
                        
        %% section to change array order if scan types not sensble
        if (isfield(exp_params,'swap_stage_order'))
        for k=1:length(data.(current_scan).ac)
            tmp = data.(current_scan).ac{k};
            size(tmp)
        data.(current_scan).ac{k}=permute(tmp,[exp_params.swap_stage_order 4]);
        end
        if isfield(filename.(current_scan),'dc')
        for k=1:length(data.(current_scan).dc)
          tmp =  data.(current_scan).dc{k};
        data.(current_scan).dc{k}=permute(tmp,exp_params.swap_stage_order);
        end
        clear tmp;
        end
        end
        %%
        %size(data.dc{1});   %%%  26/04/16 commented this line because it breaks when there is no DC - Fernando
        
        display(sprintf('Found %d DC files and %d AC files',data.(current_scan).dc_count,data.(current_scan).ac_count))
        %     % make mod data
        if data.(current_scan).dc_count ==data.(current_scan).ac_count
            display('Matching AC and DC data found: using modulation depth')
            for k=1:data.(current_scan).ac_count
                copy_size = [ones(1,ndims(data.scan1.dc{1})) axis_info.(current_scan).points_per_trace];
                dc_tmp = squeeze( repmat(data.(current_scan).dc{k},copy_size));
                tmp = data.(current_scan).ac{k}./dc_tmp;
                data.(current_scan).mod{k} = double(tmp);
            end
        end
        
        %co_peak location and shifting of data if required
        %this needs to be done for mod data or ac data.
        %add check to see how many are above threshold and plot an example with
        %highlighted range and threshold...
        for j=1:data.(current_scan).ac_count
            if isfield(data.(current_scan),'mod')
                tmp_data = data.(current_scan).mod{j};
            else
                tmp_data = data.(current_scan).ac{j};
                display('No modulation depth data found so using ac data')
            end
            if j==1 %for first run, work out loc and then use same for all other sets of data
                if strcmp(exp_params.forced_co_peak,'yes');
                    loc = ones(axis_info.(current_scan).axis_pts).*exp_params.default_loc;
                    copeak_lev=0;
                    copeak_pos_err=0;
                    copeak_found=0;
                else
                    % mke an index varible to access the data, this is
                    % number of dimensions independant as it could be
                    % 1d,2d,3d scan...
                    data_index = repmat({':'},1,ndims(tmp_data));
                    data_index(end)={exp_params.co_peak_range};
                    tmp = tmp_data(data_index{:});
                    data_index2 = repmat({':'},1,ndims(tmp_data));
                    data_index2(end)={1};
                    copy_size = [ones(1,ndims(tmp)-1) size(tmp,ndims(tmp))];
                    tmp2 = abs(tmp)-repmat(tmp(data_index2{:}),copy_size);
                    [a,b]=max(tmp2,[],ndims(tmp));
                    loc = b+exp_params.co_peak_range(1);
                    copeak_lev = a;
                    loc(copeak_lev<exp_params.co_peak_thresh)=exp_params.default_loc;
                    
                    
                    copeak_found = prod(axis_info.(current_scan).axis_pts) - sum(copeak_lev(:)<exp_params.co_peak_thresh);
                    copeak_pos_err = mean(loc(:))-exp_params.default_loc;
                end
                N = length(t);
                select_range = (1-min(loc(:)):N-max(loc(:)))';
            end
       
            %convert to n by t where n = product of all non time dims, then
            %convert back afterwards, this will only need 1 for loop for
            %all dimnension cases,
            size_is = size(tmp_data);
            loc2 =reshape(loc,prod(size_is(1:end-1)),1);
            tmp_data_flat =  reshape(tmp_data,prod(size_is(1:end-1)),size_is(end));
            shifted_flat=zeros(length(loc2),length(select_range));
            for k = 1:length(loc2);
                select_range_2 = select_range + loc2(k);
                shifted_flat(k,:) = tmp_data_flat(k,select_range_2);
            end
            
           % [size_is(1:end-1) length(select_range)]
           %keep data in nxt array so easier to process, after processing
           %reshape into the corrent shape based on size_is;
           % data_shift = reshape(shifted_flat,[size_is(1:end-1) length(select_range)] );
            data_shift = shifted_flat;
            data.(current_scan).input_size_is=size_is;
            t_new = data.(current_scan).t(min(loc(:))+select_range) - data.(current_scan).t(min(loc(:))-1);
            data.(current_scan).shifted{j} = data_shift;
            data.(current_scan).t_shifted = t_new;
            clear data_shift
        end
        data.(current_scan).startval = min(loc(:))+exp_params.start_offset;
        data.(current_scan).endval = data.(current_scan).startval+exp_params.trace_length;
        data.(current_scan).copeak_lev=copeak_lev;
        data.(current_scan).loc = loc;
        
        % check that at least 10 co peaks have been found and the average co peak
        % location is within 100 points of default.
        % if not plot graph showing example. currently using biggest found co peak level
        if (abs(copeak_pos_err)<100) && (copeak_found>10)
            display(sprintf('Co peak settings OK. %d co peaks found average of %1.1f within default location.',copeak_found,copeak_pos_err))
        else
            %fixed this for 3D might have brken for others - needs checking
            display(sprintf('Check Co peak settings %d co peaks found average of %1.1f within default location.',copeak_found,copeak_pos_err))
            [I,J,K] = ind2sub(size(copeak_lev),find(copeak_lev==max(copeak_lev(:))));
            figure
            plot(data.(current_scan).t,abs(squeeze(tmp_data(I,J,K,:))-tmp_data(I,J,K,1)));%,squeeze(data.(current_scan).t(exp_params.co_peak_range)),-1e-4.*ones(size(squeeze(data.(current_scan).t(exp_params.co_peak_range)))),data.(current_scan).t,exp_params.co_peak_thresh*ones(size(squeeze(data.(current_scan).t))));
            legend('example trace','selection range','selection threshold')
            xlabel('time')
            ylabel('signal level')
            title('abs(data-data first point), co_peak is max')
        end
   disp ''      
    end
end
