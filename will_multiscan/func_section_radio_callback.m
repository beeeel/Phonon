
function func_section_radio_callback (gcbo,eventdata,plotting_vars,plot_axes,ui)

num = round(get(gcbo, 'Value'));
current_scan = plotting_vars{4};
data = plotting_vars{1};
axis_info = plotting_vars{2};
z_um = axis_info.(current_scan).axis3.um; 
f_min =plotting_vars{3}.f_min;
f_max = plotting_vars{3}.f_max;
%plot_axes = plotting_vars{6};
uihandle = ui;%plotting_vars{7};

if num
    %resize the window to make room for new plots. 
    %get all the axes positionin pixels so i can set them back if them change
    tmp = plot_axes.figure_original;
    tmp(3) = 1600;
    set(gcf,'position',tmp);
    %these number sneed to be options
    gcbo.UserData = 1;
else
    set(gcf,'position',plot_axes.figure_original);
    gcbo.UserData = 0;
end

