function [handles] = func_basic_plot_multiscan(data,axis_info,exp_params,plot_params,filename);

for k=1:length(data)
    currentscan =strcat('scan',num2str(k));
    switch axis_info.number_of_axes(k)
        case 1
            %1D scan plotting scripts
            filename_str = strcat(strip_suffix(filename.con,'.con'),currentscan);
            [fh]=func_plot_basic_1D_multiscan(data.(currentscan),axis_info.(currentscan),filename_str,exp_params,plot_params);
            %2D scan plotting scripts
            handles = fh;
        case 2
            filename_str = strcat(strip_suffix(filename.con,'.con'),currentscan);
            [fh]=func_plot_basic_multiscan(data.(currentscan),axis_info.(currentscan),filename_str,exp_params,plot_params);
            handles = fh;
        case 3
            %3D scan plotting scripts
            plotting_vars{1}=data;
            plotting_vars{2}=axis_info;
            plotting_vars{3}=exp_params;
            plotting_vars{4}=currentscan;
            [fh,ui,plot_axes] = func_section_plot_multiscan(plotting_vars);
        handles.fh = fh;
        handles.ui = ui;
        handles.plot_axes = plot_axes;

        otherwise
            display('more than 3 dimensions, can not plot this data!')
    end
end