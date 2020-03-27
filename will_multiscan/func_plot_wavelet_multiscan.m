%function [handle] = func_plot_wavelet(w_data,axis_info,filename,W_params);
function [handle] = func_plot_wavelet_multiscan(W_data,data,axis_info,filename,exp_params,W_params)
display('Wavelet plotting starting.');
figure
for scan = fieldnames(data)'
    for L=1:length(W_data.(scan{:}).max_loc)
        
        poly_lev = W_data.(scan{:}).tracked_lev{L}(:,:,2,:);
        poly_lev2 =( poly_lev ./ max(poly_lev(:)));
        poly_trn = zeros(axis_info.(scan{:}).axis_pts(1:2));
        for k=1:axis_info.(scan{:}).axis_pts(1)
            for j=1:axis_info.(scan{:}).axis_pts(2)
                tmp = squeeze(poly_lev2(k,j,1,1:end));
                if ~isempty(find(tmp<W_params.thresh,1))
                    poly_trn(k,j) = find(tmp<W_params.thresh,1);
                else
                    poly_trn(k,j)=1;
                end
            end
        end
        handle(1)=figure;
        imagesc(axis_info.(scan{:}).axis1.um,axis_info.(scan{:}).axis2.um,1e9*(W_data.(scan{:}).t(poly_trn)).*W_params.object_vel/1000)
        axis image
        h=colorbar;ylabel(h,'\mum');
        xlabel('\mum');ylabel('\mum');
        
        wave_freq = W_params.(scan{:}).Frq(W_data.(scan{:}).max_loc{L});
        avg = W_params.slice_avg;%=20;
        b3 = wave_freq(:,:,W_params.select);
        b4 = reshape(b3(:,:,1:avg*floor(length(W_params.select)/avg)),...
            axis_info.(scan{:}).axis_pts(1),axis_info.(scan{:}).axis_pts(2),...
            avg,floor(length(W_params.select)/avg));
        b5 = squeeze(mean(b4,3));
        tnew = mean(reshape(W_data.(scan{:}).t(W_params.select),avg,floor(length(W_params.select)/avg)),1);
        if 0 %exp_params.figure_save ==1
            fig_name = strcat(strip_suffix(filename.con,'.con'),'_WAM_plot_',num2str(k),'_1');
            set(gcf,'paperpositionmode','auto');
            print('-dpng',strcat(fig_name,'.png'));
            print('-depsc',strcat(fig_name,'.eps'));
        end
        handle(2) = figure;
        set(gcf,'renderer','opengl');
        [x,y,z]=meshgrid(axis_info.(scan{:}).axis2.um,-1*axis_info.(scan{:}).axis1.um,(tnew)*W_params.object_vel);
        v3=1e-9*(b5);
        v = smooth3(v3,'gaussian',5,0.65);
        p = patch(isosurface(x,y,z,v,W_params.freq_sel_cut,z));
        isonormals(x,y,z,v,p)
        set(p,'FaceColor','interp','EdgeColor','interp');
        daspect([1,1,0.5])
        view(5,60);
        lighting phong
        colormap jet
        xlabel('\mum');ylabel('\mum'); zlabel('\mum');
        if 0 %exp_params.figure_save ==1
            fig_name = strcat(strip_suffix(filename.con,'.con'),'_WAM_plot_',num2str(k),'_2');
            set(gcf,'paperpositionmode','auto');
            print('-dpng',strcat(fig_name,'.png'));
            print('-depsc',strcat(fig_name,'.eps'));
        end
        
        
    end
end
display('Wavelet plotting complete.');

