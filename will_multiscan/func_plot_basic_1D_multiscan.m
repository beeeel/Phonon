function [figure_handles]=func_plot_basic_1D_multiscan(data,axis_info,filename,exp_params,plot_params)
display('Basic plotting starting');
x_sel =1;
y_sel =1;

    for k=1:length(data.shifted);
        figure_handles(k) = figure('position',[25+(k-1)*900 25 900 800]);
    end
    
    for k=1:length(data.shifted);
        plotting_vars = {data,axis_info,filename,k,exp_params,plot_params,figure_handles};
        
        f_mask =1;
        a_mask =1;
        if plot_params.enable_mask==1
            fprintf(1,'Applying mask to frequency plot:');
            switch plot_params.mask_var
                case 'ac_amp'
                    fprintf(1,' AC mask applied with %g threshold \n',plot_params.mask_threshold);
                    f_mask = data.f_amp{k}>plot_params.mask_threshold;
                case 'dc_amp'
                    fprintf(1,' DC mask applied with %f threshold \n',plot_params.mask_threshold);
                    f_mask = data.dc{k}>plot_params.mask_threshold;
                    a_mask = f_mask;
                    if ~data.dc_count>0
                        error('plot error: asked for DC mask, but no DC data present')
                    end
                case 'ac_frq'
                    fprintf(1,' DC mask applied with %f %f threshold \n',plot_params.mask_threshold(1),plot_params.mask_threshold(2));
                    f_mask = (data.freq{k}>plot_params.mask_threshold(1)) .* (data.freq{k}<plot_params.mask_threshold(2));
                    %f_mask = (data.freq{k}<plot_params.mask_threshold(2));
                    a_mask = f_mask;
                    figure
                    imagesc(f_mask)
            end
        end
        
        figure(figure_handles(k));
        if data.dc_count>0
            subplot(3,3,1);plot(axis_info.axis1.um,data.dc{k});
             set(gca,'interruptible','off','BusyAction','cancel','ButtonDownFcn', {@func_plot_basic_1D_callback_multiscan,plotting_vars});                 %assign call back function when mouse clicked in figur
            set(get(gca,'Children'),'interruptible','off','BusyAction','cancel','ButtonDownFcn', {@func_plot_basic_1D_callback_multiscan,plotting_vars}); %apply to data in the figure as well
            
            title(sprintf('DC%d',k));
            ylabel('volts')
            xlabel(axis_info.axis1.type)
            hold on;plot(axis_info.axis1.um(x_sel),data.dc{k}(x_sel),'kx','markersize',8,'linewidth',2);hold off
        end
        
        subplot(3,3,4);plot(axis_info.axis1.um,data.f_amp{k}.*a_mask);
        set(gca,'interruptible','off','BusyAction','cancel','ButtonDownFcn', {@func_plot_basic_1D_callback_multiscan,plotting_vars});                 %assign call back function when mouse clicked in figur
        set(get(gca,'Children'),'interruptible','off','BusyAction','cancel','ButtonDownFcn', {@func_plot_basic_1D_callback_multiscan,plotting_vars}); %apply to data in the figure as well
        
        if isfield(data,'mod')
            title('Mod depth');
            ylabel('\deltaR/R')
        else
            title('AC amp');
            ylabel('\deltaR (volts)')
        end
        hold on;plot(axis_info.axis1.um(x_sel),data.f_amp{k}(x_sel),'kx','markersize',8,'linewidth',2);hold off
         ylabel('volts')
         xlabel(axis_info.axis1.type)
        
        subplot(3,3,7);plot(axis_info.axis1.um,data.freq{k}.*f_mask);
        set(gca,'interruptible','off','BusyAction','cancel','ButtonDownFcn', {@func_plot_basic_1D_callback_multiscan,plotting_vars});                 %assign call back function when mouse clicked in figur
        set(get(gca,'Children'),'interruptible','off','BusyAction','cancel','ButtonDownFcn', {@func_plot_basic_1D_callback_multiscan,plotting_vars}); %apply to data in the figure as well
        title('Frequency');
        hold on;plot(axis_info.axis1.um(x_sel),data.freq{k}(x_sel),'kx','markersize',8,'linewidth',2);hold off
        ylabel('GHz')
        xlabel(axis_info.axis1.type)
        
        subplot(3,3,2:3);plot(1e9*data.raw_t{k},squeeze(data.raw_LP{k}(x_sel,:)));
        xlabel('ns');title(sprintf('Raw trace:%1.2f',axis_info.axis1.um(x_sel)));
        subplot(3,3,5:6);plot(1e9*data.t_out{k},squeeze(data.pro{k}(x_sel,:)));
        xlabel('ns');
        subplot(3,3,8:9);plot(1e-9*data.fx{k},squeeze(data.fft{k}(x_sel,:)));
        xlabel('GHz');title(sprintf('peak:%1.2f',data.freq{k}(x_sel)));
        
        if plot_params.figure_save ==1
            fig_name = strcat(filename,'_basic_plot_',num2str(k));
            set(gcf,'paperpositionmode','auto');
            print('-dpng',strcat(fig_name,'.png'));
            print('-depsc',strcat(fig_name,'.eps'));
        end
        
    end

display('Basic plotting complete');