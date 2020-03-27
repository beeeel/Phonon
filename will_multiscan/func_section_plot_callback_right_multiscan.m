function func_section_plot_callback_lower_multiscan(gcbo,eventdata,plotting_vars,plot_axes,ui)
%grab varibles from input structure.
data = plotting_vars{1};
axis_info = plotting_vars{2};
current_scan = plotting_vars{4};
z_um = axis_info.(current_scan).axis3.um; 
f_min =plotting_vars{3}.f_min;
f_max = plotting_vars{3}.f_max;
v_new = data.(current_scan).freq{1};


current_scan = 'scan1';
cP = get(gca,'Currentpoint');

z = cP(1,1);
dz =  axis_info.(current_scan).axis3.um(2)- axis_info.(current_scan).axis3.um(1);
z_sel = find(0.5*dz+axis_info.(current_scan).axis3.um>z,1);
if z>max(axis_info.(current_scan).axis3.um)
    z_sel=axis_info.(current_scan).axis3.pts;
end

if z<min(axis_info.(current_scan).axis3.um)
    z_sel=1;
end
if isempty(z_sel)
    z_sel=axis_info.(current_scan).axis3;
end
new_data_plane =  squeeze(v_new(:,:,z_sel));
h2 = get(plot_axes.axes1,'Children');
set(h2(3),'CData',new_data_plane);