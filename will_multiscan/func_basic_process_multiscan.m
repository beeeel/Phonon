%function [data]=func_basic_process(data,exp_params)
% function takes data and params, does LP filter to remove HF components
% then does thermal removal
% then does FFT peak find
% all data is retuened in data struct, FFT datas is trunacvted to 2*f_max
% ranage to save space.


function [data]=func_basic_process_multiscan(data,axis_info,exp_params)
% LP filter for plotting raw signals - removes HF aliased F from traces

if (exp_params.force_process~=1)
    exp_params.force_process
    display('Basic processing skipped as loaded previous data');
else
    display('Basic processing starting.')
    
    
    for s = 1:axis_info.number_of_scans;
        current_scan =(strcat('scan',num2str(s)));
        
        
        for k = 1:axis_info.(current_scan).no_channels
            % LP filter for plotting raw signals - removes HF aliased F from traces,
            % cut off must be high and away from freqs of interest not to influence
            % results.
            
            
            tmp_raw_LP = zeros(size(data.(current_scan).shifted{k},1),length(data.(current_scan).startval-exp_params.plotting_start_offset:data.(current_scan).endval));
            tmp_pro = zeros(size(data.(current_scan).shifted{k},1),length(exp_params.plotting_start_offset:exp_params.plotting_start_offset+exp_params.trace_length));
            tmp_freq = zeros(size(data.(current_scan).shifted{k},1),1);
            tmp_f_amp = zeros(size(data.(current_scan).shifted{k},1),1);
            tmp_fx = [];
            tmp_fft = [];
            tmp_f_pha = zeros(size(data.(current_scan).shifted{k},1),1);
            
            for j = 1:size(data.(current_scan).shifted{k},1);  % for all n traces in current data set
                
                trace_data = data.(current_scan).shifted{k}(j,:); %trace to process.
                
                %filter HF off
                t = data.(current_scan).t_shifted;
                [tmp] =  func_LPfilter_multiscan(t,trace_data,exp_params.LPfilter);
                if data.(current_scan).endval > length(tmp)
                    warning('aaaa')
                end
                tmp_raw_LP(j,:) = tmp(data.(current_scan).startval-exp_params.plotting_start_offset:data.(current_scan).endval);
                tmp_raw_t = data.(current_scan).t_shifted(data.(current_scan).startval-exp_params.plotting_start_offset:data.(current_scan).endval);
                
                %thermal removal on LP data
                [tmp_t_out tmp_pro(j,:)] = func_thermal_rm_multiscan(tmp_raw_t,tmp_raw_LP(j,:),exp_params.fit_order,exp_params.plotting_start_offset,exp_params.plotting_start_offset+exp_params.trace_length);
                %fft and peak find section
                [tmp_freq(j),tmp_f_amp(j),tmp_fx,tmp_fft(j,:),tmp_f_pha(j)]=func_FFT_peak_find_multiscan(tmp_t_out,tmp_pro(j,:),exp_params);
                
                % data.n{k} = ones(size(data.freq{k})) *exp_params.index_media;
                % data.n{k}(data.freq{k}>exp_params.index_sel_freq)=exp_params.index_object;
                % data.vel{k} = data.freq{k}*exp_params.lambda ./(2*data.n{k});
                
            end
            size_is =  data.(current_scan).input_size_is;
            %=reshape(shifted_flat,[size_is(1:end-1) length(select_range)] );
            %not length select range, it's (size of input,2)
            data.(current_scan).raw_t{k}=tmp_raw_t;
            data.(current_scan).raw_LP{k}=reshape(tmp_raw_LP,[size_is(1:end-1) size(tmp_raw_LP,2)] );
            data.(current_scan).t_out{k}=tmp_t_out;
            data.(current_scan).fx{k}=tmp_fx;
            
            data.(current_scan).pro{k}=reshape(tmp_pro,[size_is(1:end-1) size(tmp_pro,2)] );
            data.(current_scan).fft{k}=reshape(tmp_fft,[size_is(1:end-1) size(tmp_fft,2)] );
            
            if size(size_is,2)<3;
            data.(current_scan).freq{k}=tmp_freq;
            data.(current_scan).f_amp{k}=tmp_f_amp;
            data.(current_scan).f_pha{k}=tmp_f_pha;    
            else
            data.(current_scan).freq{k}=reshape(tmp_freq,[size_is(1:end-1)] );
            data.(current_scan).f_amp{k}=reshape(tmp_f_amp,[size_is(1:end-1)] );
            data.(current_scan).f_pha{k}=reshape(tmp_f_pha,[size_is(1:end-1)] );
            end
           
        end
    end
    
    display('Basic processing complete.')
end