% main call back function for plot, updates xz yz slices depending where
% clicked and pdates line, plots extra plots if selected for pixel selected
% currently shift clicking is broken!


function func_section_plot_callback_multiscan(gcbo,eventdata,plotting_vars,plot_axes,ui)
modifiers = get(gcf,'CurrentModifier');             % grab info about calling conditions
wasShiftPressed = ismember('shift',   modifiers);  % true/false if shift pressed
%grab varibles from input structure.
current_scan = plotting_vars{4};

data = plotting_vars{1};
axis_info = plotting_vars{2};
z_um = axis_info.(current_scan).axis3.um; 
f_min =plotting_vars{3}.f_min;
f_max = plotting_vars{3}.f_max;
%plot_axes = plotting_vars{6};
h = findobj('Tag','bg');
plot_type = h.UserData;
h = findobj('Tag','slider1');
z_sel = h.UserData;
h = findobj('Tag','radio1');
extra_plots = h.UserData;
v_new = data.(current_scan).(plot_type){1};
switch plot_type
    case 'freq'
f_min =plotting_vars{3}.f_min;
f_max = plotting_vars{3}.f_max;
    case 'dc'
       f_min =min(v_new(:));
f_max = max(v_new(:));
    case 'f_amp'
       f_min =min(v_new(:));
f_max = max(v_new(:));
 
end

cP = get(gca,'Currentpoint');
setappdata(gcbo.Parent,'clicked_point',cP)

if wasShiftPressed %this is currently broken!
    %display('Shift pressed')
    previous_point = getappdata(gcbo.Parent,'clicked_point')
    current_point = cP;
    
    % x1y1x2y2 assign
    % get slices
    if axis_info.(current_scan).axis1.pts>1
        dx = axis_info.(current_scan).axis1.um(2)-axis_info.(current_scan).axis1.um(1);
    else
        dx=0;
    end
    
    if axis_info.(current_scan).axis2.pts>1
        dy = axis_info.(current_scan).axis2.um(2)-axis_info.(current_scan).axis2.um(1);
    else
        dy=0;
    end
    % convert to pixel location
    x1 = find(0.5*dx+axis_info.(current_scan).axis1.um>previous_point(1,1),1);
    y1 = find(0.5*dy+axis_info.(current_scan).axis2.um>previous_point(1,2),1);
    x2 =find(0.5*dx+axis_info.(current_scan).axis1.um>current_point(1,1),1);
    y2 = find(0.5*dy+axis_info.(current_scan).axis2.um>current_point(1,2),1);
    % make lines and bound by allowed axis ranges
    m = (y2-y1)/(x2-x1);
    c = y1-(m*x1);
    x=1:axis_info.(current_scan).axis1.pts;
    y = round( m*x+c);
    ycut = find(round(y)>0&(round(y)<axis_info.(current_scan).axis2.pts));
    x = x(ycut);
    y=y(ycut);
    for k=1:length(x)
        Xslice(k,:) = squeeze(v_new(y(k),x(k),:));
    end
    % now same for Y slice
    m2 = (x2-x1)/(y2-y1);
    c2 = x1-(m2*y1);
    yy=1:axis_info.(current_scan).axis2.pts;
    xx = round( m2*yy+c2);
    xcut = find(round(xx)>0&(round(xx)<axis_info.(current_scan).axis1.pts));
    xx=xx(xcut);
    yy=yy(xcut);
    for k=1:length(yy)
        Yslice(k,:) = squeeze(v_new(yy(k),xx(k),:));
    end
    %then all update plots
    
    h2=get(plot_axes.axes1,'Children');
    set(h2(2),'Xdata',axis_info.(current_scan).axis1.um(x),'YData',axis_info.(current_scan).axis2.um(y));
    set(h2(1),'Xdata',[],'Ydata',[])
    
    axes(plot_axes.axes2);
   imagesc(axis_info.(current_scan).axis3.um,axis_info.(current_scan).axis2.um(yy),(Yslice),[f_min f_max]);
    axis([min(axis_info.(current_scan).axis3.um) max(axis_info.(current_scan).axis3.um) min(axis_info.(current_scan).axis2.um) max(axis_info.(current_scan).axis2.um)])
    set(gca,'Xcolor','g','Ycolor','g','ytick',[],'linewidth',2);
    
    
    axes(plot_axes.axes3);
    imagesc(axis_info.(current_scan).axis1.um(xx),axis_info.(current_scan).axis3.um,(Xslice'),[f_min f_max]);
    axis([min(axis_info.(current_scan).axis1.um) max(axis_info.(current_scan).axis1.um) min(axis_info.(current_scan).axis3.um) max(axis_info.(current_scan).axis3.um)])
    set(gca,'Xcolor','r','Ycolor','r','xtick',[],'linewidth',2);
else  %do usual plotting for single click, no shift modifier
    %use mouse point and find out which pixels it is
    x = cP(1,2);
    y = cP(1,1);
    if axis_info.(current_scan).axis1.pts>1
        dx =  axis_info.(current_scan).axis1.um(2)- axis_info.(current_scan).axis1.um(1);
    else
        dx=0;
    end
    
    if  axis_info.(current_scan).axis2.pts>1
        dy = axis_info.(current_scan).axis2.um(2)-axis_info.(current_scan).axis2.um(1);
    else
        dy=0;
    end
    x_sel = find(0.5*dx+axis_info.(current_scan).axis1.um>x,1);
    y_sel = find(0.5*dy+axis_info.(current_scan).axis2.um>y,1);
    [ x x_sel y y_sel];
    if x>max(axis_info.(current_scan).axis1.um)
        x_sel=axis_info.(current_scan).axis1.pts;
    end
    if y>max(axis_info.(current_scan).axis2.um)
        y_sel=axis_info.(current_scan).axis2.pts;
    end
    if x<min(axis_info.(current_scan).axis1.um)
        x_sel=1;
    end
    if y<min(axis_info.(current_scan).axis2.um)
        y_sel=1;
    end
    if isempty(x_sel)
        x_sel=axis_info.(current_scan).axis1;
    end
    if isempty(y_sel)
        y_sel=axis_info.(current_scan).axis2;
    end
    [ dx x x_sel dy y y_sel];
    h2=get(plot_axes.axes1,'Children')
    set(h2(1),'Xdata',axis_info.(current_scan).axis2.um([1 end]),'Ydata',axis_info.(current_scan).axis1.um([x_sel x_sel]));
    set(h2(2),'Xdata',axis_info.(current_scan).axis2.um([y_sel y_sel]),'Ydata',axis_info.(current_scan).axis1.um([1 end]))
    h2(3).CData =squeeze(v_new(:,:,z_sel));
    plot_axes.axes1.CLim = [f_min f_max];
    axes(plot_axes.axes2);
    imagesc(axis_info.(current_scan).axis3.um,axis_info.(current_scan).axis2.um,(squeeze(v_new(:,y_sel,:))),[f_min f_max]);
    set(gca,'Xcolor','g','Ycolor','g','ytick',[],'linewidth',2);
 %   set(gca,'interruptible','off','BusyAction','cancel','ButtonDownFcn', {@func_section_plot_callback_right_multiscan,plotting_vars});                 %assign call back function when mouse clicked in figur
 %   set(get(gca,'Children'),'interruptible','off','BusyAction','cancel','ButtonDownFcn', {@func_section_plot_callback_right_multiscan,plotting_vars}); %apply to data in the figure as well

    axes(plot_axes.axes3);
    imagesc(axis_info.(current_scan).axis1.um,axis_info.(current_scan).axis3.um,squeeze(v_new(x_sel,:,:))',[f_min f_max]);
    set(gca,'Xcolor','r','Ycolor','r','xtick',[],'linewidth',2);
%    set(gca,'interruptible','off','BusyAction','cancel','ButtonDownFcn', {@func_section_plot_callback_lower_multiscan,plotting_vars});                 %assign call back function when mouse clicked in figur
%    set(get(gca,'Children'),'interruptible','off','BusyAction','cancel','ButtonDownFcn', {@func_section_plot_callback_lower_multiscan,plotting_vars}); %apply to data in the figure as well

end


if extra_plots
  plot_axes.ax1.Visible='on';
  axes(plot_axes.ax1);
  h1=get(plot_axes.ax1,'Children');
  h1.XData = 1e-9*data.(current_scan).fx{1};
  h1.YData = squeeze(data.(current_scan).fft{1}(x_sel,y_sel,z_sel,:));
  plot_axes.ax1.Title.String = 'Spectrum';
  
  plot_axes.ax2.Visible='on';
  axes(plot_axes.ax2);
  h2=get(plot_axes.ax2,'Children');
  h2.XData = 1e9*data.(current_scan).t_out{1};
  h2.YData = squeeze(data.(current_scan).pro{1}(x_sel,y_sel,z_sel,:));
  plot_axes.ax2.Title.String = 'Processed data';
  
  plot_axes.ax3.Visible='on';
  axes(plot_axes.ax3);
  h3=get(plot_axes.ax3,'Children');
  h3.XData = 1e9*data.(current_scan).raw_t{1};
  h3.YData = squeeze(data.(current_scan).raw_LP{1}(x_sel,y_sel,z_sel,:));
plot_axes.ax3.Title.String = strcat('Raw data:','x:',num2str(x_sel),' y:',num2str(y_sel),' z:',num2str(z_sel));
else %turn off un needed axes
    plot_axes.ax1.Visible='off';
    plot_axes.ax2.Visible='off';
    plot_axes.ax3.Visible='off';
end



