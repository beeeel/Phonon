%function [fh]=func_live_plot_d_scan(data,axis_info,filename,k,exp_params,trace_no,fh,still_live)
%plot function for live data
%very similar to main plotting script but currently has clickable disabled
%to do add clickable option and maybe new panel with previously clicked
%data in.

function [fh]=func_live_plot_d_scan(data,axis_info,filename,k,exp_params,trace_no,fh,still_live,clickable)
for k=1:length(data.pro);
    if isempty(fh)
        fh(k) = figure('position',[25+(k-1)*800 25 800 800]);
    end
    if length(fh)<k
        fh(k) = figure('position',[25+(k-1)*800 25 800 800]);
    end
    
        if clickable==1
       plots_w = 5;
       plot_offset =5;
    else
        plots_w = 3;
        plot_offset = 3;
    end
    
    
    
    if (still_live ~=1)||(clickable==1);
        plotting_vars{1}=data;
        plotting_vars{3}=filename;
        plotting_vars{2}=axis_info;
        plotting_vars{4}=k;
        plotting_vars{5}=exp_params;
        plotting_vars{6}=trace_no;
        plotting_vars{7}=fh;
        plotting_vars{8} = plots_w;
        plotting_vars{9} = plot_offset;
    end
    x_sel = data.X;
    y_sel = data.Y;
    dy = diff(axis_info.y_um([1 2]));
    dx = diff(axis_info.x_um([1 2]));
    f_mask =1;
    a_mask =1;
    if exp_params.enable_mask==1
     %   fprintf(1,'Applying mask to frequency plot:');
        switch exp_params.mask_var
            case 'ac_amp'
              %  fprintf(1,' AC mask applied with %g threshold \n',exp_params.mask_threshold);
                f_mask = data.f_amp{k}>exp_params.mask_threshold;
            case 'dc_amp'
               % fprintf(1,' DC mask applied with %f threshold \n',exp_params.mask_threshold);
                f_mask = data.dc{k}>exp_params.mask_threshold;
                a_mask = f_mask;
                if ~data.dc_count>0
                    error('plot error: asked for DC mask, but no DC data present')
                end
            case 'ac_frq'
                %fprintf(1,' DC mask applied with %f %f threshold \n',exp_params.mask_threshold(1),exp_params.mask_threshold(2));
                f_mask = (data.freq{k}>exp_params.mask_threshold(1)) .* (data.freq{k}<exp_params.mask_threshold(2));
                a_mask = f_mask;
        end
    end
    figure(fh(k));
    
    
    if data.dc_count>0
        dc_flat = data.dc{k}';
        dc_flat = dc_flat(:);
        subplot(3, plots_w,1+0*plot_offset);imagesc(axis_info.x_um,axis_info.y_um,data.dc{k}',[min(dc_flat(1:trace_no)) max((dc_flat(1:trace_no)))]);%axis image;
        a = get(gca,'position');c =colorbar('location','westoutside');set(gca,'position',a);title(c,'V')
    if still_live~=1
        set(gca,'interruptible','off','BusyAction','cancel','ButtonDownFcn', {@func_plot_live_callback,plotting_vars});                 %assign call back function when mouse clicked in figur
        set(get(gca,'Children'),'interruptible','off','BusyAction','cancel','ButtonDownFcn', {@func_plot_live_callback,plotting_vars}); %apply to data in the figure as well
    elseif clickable==1
        set(gca,'interruptible','off','BusyAction','cancel','ButtonDownFcn', {@func_plot_live_callback_running,plotting_vars});                 %assign call back function when mouse clicked in figur
        set(get(gca,'Children'),'interruptible','off','BusyAction','cancel','ButtonDownFcn', {@func_plot_live_callback_running,plotting_vars}); %apply to data in the figure as well
    end
        title(sprintf('DC%d',k));
        hold on;
        hold on;        plot(0.5*dy+axis_info.x_um(x_sel),0.5*dx+axis_info.y_um(y_sel),'wx','markersize',8,'linewidth',2); hold off
    end
    
    f_amp_flat = data.f_amp{k}';
    f_amp_flat = f_amp_flat(:)';
    subplot(3, plots_w,1+1*plot_offset);imagesc(axis_info.x_um,axis_info.y_um,(data.f_amp{k}.*a_mask)',[min(f_amp_flat(1:trace_no)) max(f_amp_flat(1:trace_no))]);%axis image;
    a = get(gca,'position');c=colorbar('location','westoutside');set(gca,'position',a);;
    if still_live~=1
        set(gca,'interruptible','off','BusyAction','cancel','ButtonDownFcn', {@func_plot_live_callback,plotting_vars});                 %assign call back function when mouse clicked in figur
        set(get(gca,'Children'),'interruptible','off','BusyAction','cancel','ButtonDownFcn', {@func_plot_live_callback,plotting_vars}); %apply to data in the figure as well
    elseif clickable==1
        set(gca,'interruptible','off','BusyAction','cancel','ButtonDownFcn', {@func_plot_live_callback_running,plotting_vars});                 %assign call back function when mouse clicked in figur
        set(get(gca,'Children'),'interruptible','off','BusyAction','cancel','ButtonDownFcn', {@func_plot_live_callback_running,plotting_vars}); %apply to data in the figure as well
    end
    if isfield(data,'mod')
        title('Mod depth');
    else
        title('AC amp');title(c,'V');
    end
    hold on;        plot(0.5*dy+axis_info.x_um(x_sel),0.5*dx+axis_info.y_um(y_sel),'wx','markersize',8,'linewidth',2);     hold off
    subplot(3, plots_w,1+2*plot_offset);imagesc(axis_info.x_um,axis_info.y_um,(data.freq{k}.*f_mask)',[exp_params.f_min exp_params.f_max]);%axis image;
    a = get(gca,'position');c=colorbar('location','westoutside');set(gca,'position',a);title(c,'Freq')
    if still_live~=1
        set(gca,'interruptible','off','BusyAction','cancel','ButtonDownFcn', {@func_plot_live_callback,plotting_vars});                 %assign call back function when mouse clicked in figur
        set(get(gca,'Children'),'interruptible','off','BusyAction','cancel','ButtonDownFcn', {@func_plot_live_callback,plotting_vars}); %apply to data in the figure as well
    elseif clickable==1
        set(gca,'interruptible','off','BusyAction','cancel','ButtonDownFcn', {@func_plot_live_callback_running,plotting_vars});                 %assign call back function when mouse clicked in figur
        set(get(gca,'Children'),'interruptible','off','BusyAction','cancel','ButtonDownFcn', {@func_plot_live_callback_running,plotting_vars}); %apply to data in the figure as well
    end
    title('Frequency');title(c,'GHz')
    hold on;        plot(0.5*dy+axis_info.x_um(x_sel),0.5*dx+axis_info.y_um(y_sel),'wx','markersize',8,'linewidth',2);   hold off
    clear c;
    subplot(3,plots_w,[2 3]+0*plot_offset);plot(1e9*data.raw_t,squeeze(data.rawLP{k}(x_sel,y_sel,:)));
    xlabel('ns');title(sprintf('Raw trace:%1.2f,%1.2f',axis_info.x_um(x_sel),axis_info.y_um(y_sel)));
    subplot(3,plots_w,[2 3]+1*plot_offset);plot(1e9*data.t_out,squeeze(data.pro{k}(x_sel,y_sel,:)));
    xlabel('ns');
    subplot(3,plots_w,[2 3]+2*plot_offset);plot(1e-9*data.fx,squeeze(data.fft{k}(x_sel,y_sel,:)));
    xlabel('GHz');title(sprintf('peak:%1.1f',data.freq{k}(x_sel,y_sel)));
end
