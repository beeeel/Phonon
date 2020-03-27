%function [w_data] = func_wavelet_processing(data,axis_info,w_params)
function [W_data,W_params] = func_wavelet_processing_multiscan(data,axis_info,W_params)
display('Wavelet processing started');
for scan = fieldnames(data)'
    fprintf('Processing %s\n',scan{:})
    W_data.(scan{:}).t = data.(scan{:}).t_out{1}(1:end)*1e9;
    delta = (W_data.(scan{:}).t(2)-W_data.(scan{:}).t(1))*1e-9;
    
    scalerange = round(centfrq(W_params.wavelet_nm)./([W_params.f_min W_params.f_max].*delta));
    scales = scalerange(end):0.25:scalerange(1);
    W_params.(scan{:}).Frq = scal2frq(scales,W_params.wavelet_nm,delta);
    
    for H=1:length(W_params.freq_to_track)
        [W_params.(scan{:}).track_loc(H)] = find(W_params.(scan{:}).Frq<W_params.freq_to_track(H),1);
    end
    
    for L = 1:length(data.(scan{:}).pro);
        for k=1:axis_info.(scan{:}).axis_pts(1);
            if (k==1)||(rem(k,10)==0)
                disp(strcat(num2str(k),'/',num2str(axis_info.(scan{:}).axis_pts(1))))
            end
            for j=1:axis_info.(scan{:}).axis_pts(2);
                x = squeeze(data.(scan{:}).pro{L}(k,j,1:end));
                Coeffs = cwt(x,scales,W_params.wavelet_nm);
                
                if rem(j,10)==0
                    imagesc(data.(scan{:}).t_out{1},scales,abs(Coeffs))
                    drawnow;
                end
                
                [a b]=max(abs(Coeffs));
                W_data.(scan{:}).max_loc{L}(k,j,:)=b;
                W_data.(scan{:}).tracked_lev{L}(k,j,:,:) = abs(Coeffs(W_params.track_loc,:));
            end
        end
    end
end
display('Wavelet processing complete.');