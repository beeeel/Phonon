
function func_section_plottype_callback (gcbo,eventdata,plotting_vars,plot_axes,ui)

num = eventdata.NewValue.String;
% current_scan = plotting_vars{4};
% data = plotting_vars{1};
% axis_info = plotting_vars{2};
% z_um = axis_info.(current_scan).axis3.um; 
% f_min =plotting_vars{3}.f_min;
% f_max = plotting_vars{3}.f_max;
%plot_axes = plotting_vars{6};
%uihandle = ui;%plotting_vars{7};

switch num
    case 'Freq'
        plot_type = 'freq'
    case 'Amp'
        plot_type = 'f_amp'
    case 'DC'
        plot_type = 'dc'
    otherwise
        plot_type = 'freq';
end

    gcbo.UserData = plot_type;


