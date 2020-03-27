
function func_section_slider_callback (gcbo,eventdata,plotting_vars,plot_axes,ui)


current_scan = plotting_vars{4};
data = plotting_vars{1};
axis_info = plotting_vars{2};
z_um = axis_info.(current_scan).axis3.um; 
f_min =plotting_vars{3}.f_min;
f_max = plotting_vars{3}.f_max;
%plot_axes = plotting_vars{6};
uihandle = ui;%plotting_vars{7};

num = (get(gcbo, 'Value'));
pick = find(axis_info.(current_scan).axis3.um>=num,1);



axes(plot_axes.axes1);

v_new = data.(current_scan).freq{1};
h2=get(plot_axes.axes1,'Children');
h2(3).CData = squeeze(v_new(:,:,pick));
uihandle.slider_label.String = strcat('Z:',num2str(pick));

gcbo.UserData = pick;
