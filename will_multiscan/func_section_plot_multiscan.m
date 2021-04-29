%set up main plot, currently sizes hard coded in here in pixels
%these need to be added as options somewhere
function [fh,ui,plot_axes] = func_section_plot_multiscan(plotting_vars)
% Inputs: {data, axis_info, exp_params, current_scan}

%this needs adding to input vars
current_scan = plotting_vars{4};
%unpack inputs
data = plotting_vars{1};
axis_info = plotting_vars{2};
z_um = axis_info.(current_scan).axis3.um; 
f_min =plotting_vars{3}.f_min;
f_max = plotting_vars{3}.f_max;
v_new = data.(current_scan).freq{1};
fh = figure;
colormap jet
X_sel =1;
Y_sel =1;
pick=1; %initial z
range1 = diff(axis_info.(current_scan).axis1.um([1 end]));

range2 = diff(axis_info.(current_scan).axis2.um([1 end]));
if range1 == 0
    range1 = range2;
elseif range2 == 0
    range2 = range1;
end
aspect_ratio = range2./range1;
h=450;
w=h/aspect_ratio;
% given w calc h for the z plots.
% vert size of figure will then be the sum of the h of main plus lower plot plus the gaps
% width is width of main plot plus widths of the right plot plus the gaps.
% if i set plot window to this size everything should then line up!
fig_w = 800;
mainL = 50;
mainB = 150;
mainh = h;
mainw = w;
gap = 30;
lowerL = mainL;
lowerB = gap;
lowerh = 0.2*h;
lowerw = w;
rightL = mainL+mainw+gap+gap;
rightB = mainB;
righth = mainh;
rightw = lowerh;
Sgap = 30;
SliderL = mainL;
SliderB = (mainB+mainh)+Sgap;
SliderW = mainw;
SliderH = 20;
bgcolor = fh.Color;
figurew = gap+mainw+gap+rightw+gap+gap;
figureh = gap+mainh+gap+lowerh+gap+ Sgap+Sgap;
figure_aspect_ratio = figurew/figureh;
fig_h = fig_w/figure_aspect_ratio;

set(gcf,'position',[50 50 figurew figureh]);
plot_axes.figure_original = get(gcf,'position');
%[mainL mainB mainw mainh]
%[SliderL,SliderB,SliderW,SliderH]

%set up Ui elements
ui.slider_label_min = uicontrol('Parent',fh,'Style','text','Position',[SliderL-Sgap,SliderB,23,23],'String',num2str(z_um(1)),'BackgroundColor',bgcolor);
ui.slider_label_max = uicontrol('Parent',fh,'Style','text','Position',[SliderL+SliderW+Sgap,SliderB,23,23],'String',num2str(z_um(end)),'BackgroundColor',bgcolor);
ui.slider_label = uicontrol('Parent',fh,'Style','text','Position',[SliderL+0.5*SliderW,0.5*Sgap+SliderB,30,23],'String','Z:1','BackgroundColor',bgcolor);
ui.SliderH = uicontrol('Parent',fh,'Style','slider','Tag','slider1','Position',[SliderL,SliderB,SliderW,SliderH],'SliderStep', [(z_um(2)-z_um(1)), (z_um(2)-z_um(1))],'value',z_um(1), 'min',min(z_um), 'max',max(z_um));
ui.SliderH.UserData = 1;
ui.radio_plot = uicontrol('Parent',fh,'Style','radiobutton','String','Full Plots','Tag','radio1','Position',[550 75 100 30]);

%
ui.bg = uibuttongroup('Visible','off','Tag','bg','Units','Pixels','Position',[570 610 70 70]);
% Create three radio buttons in the button group.
r1 = uicontrol(ui.bg,'Style','radiobutton','String','Freq','Position',[10 45 50 10]);
r2 = uicontrol(ui.bg,'Style','radiobutton','String','Amp','Position',[10 30 50 10]);
r3 = uicontrol(ui.bg,'Style','radiobutton','String','DC','Position',[10 15 50 10]);
ui.bg.Visible = 'on';
ui.bg.UserData = 'freq';

% set up axes for mainimages
plot_axes.axes1 = axes('units','pixels','position',[mainL mainB mainw mainh]);
imagesc(axis_info.(current_scan).axis2.um,axis_info.(current_scan).axis1.um,(squeeze(v_new(:,:,pick))),[f_min f_max]);
%axis image
axis1_pos = get(gca,'Position');

plot_axes.axes2 = axes('units','pixels','position',[rightL rightB rightw righth]);
imagesc(axis_info.(current_scan).axis3.um,axis_info.(current_scan).axis2.um,flipud(squeeze(v_new(:,Y_sel,:))),[f_min f_max]);
set(gca,'Xcolor','g','Ycolor','g','ytick',[],'linewidth',2);

plot_axes.axes3 = axes('units','pixels','position',[lowerL lowerB lowerw lowerh]);
imagesc(axis_info.(current_scan).axis1.um,axis_info.(current_scan).axis3.um,squeeze(v_new(X_sel,:,:))',[f_min f_max]);
set(gca,'Xcolor','r','Ycolor','r','xtick',[],'linewidth',2);

%setup axes for extended plots but don't plot aything on them yet.
%hard coded numbers need sorting
plot_axes.ax1 = axes('units','pixels','position',[700 50 800 150],'Visible','off');
plot(0,0);xlabel('Frequency (GHz)');axis off;
plot_axes.ax2 = axes('units','pixels','position',[700 270 800 150],'Visible','off');
plot(0,0);xlabel('Time (ns)');axis off;
plot_axes.ax3 = axes('units','pixels','position',[700 490 800 150],'Visible','off');
plot(0,0);xlabel('Time (ns)');axis off;


% want to pass ui and plot_axes directly so we dont update the strcure -
% important for memory usage with large datasets as plotting_vars passed by
% reference into here.
%plotting_vars{7} = ui;
%plotting_vars{6} = plot_axes;


% add lines to main plot to show current slices
axes(plot_axes.axes1);
set(gca,'Yaxislocation','right');
set(gca,'interruptible','off','BusyAction','cancel','ButtonDownFcn', {@func_section_plot_callback_multiscan,plotting_vars,plot_axes,ui});                 %assign call back function when mouse clicked in figur
set(get(gca,'Children'),'interruptible','off','BusyAction','cancel','ButtonDownFcn', {@func_section_plot_callback_multiscan,plotting_vars,plot_axes,ui}); %apply to data in the figure as well
line(axis_info.(current_scan).axis2.um([1 end]),axis_info.(current_scan).axis1.um([X_sel X_sel]),'linestyle','--','color','r','linewidth',2)
line(axis_info.(current_scan).axis2.um([Y_sel Y_sel]),axis_info.(current_scan).axis1.um([1 end]),'linestyle','--','color','g','linewidth',2)
set(gca,'interruptible','off','BusyAction','cancel','ButtonDownFcn', {@func_section_plot_callback_multiscan,plotting_vars,plot_axes,ui});                 %assign call back function when mouse clicked in figur
set(get(gca,'Children'),'interruptible','off','BusyAction','cancel','ButtonDownFcn', {@func_section_plot_callback_multiscan,plotting_vars,plot_axes,ui}); %apply to data in the figure as well

% setup all call back functions
set(ui.bg,'SelectionChangedFcn',{@func_section_plottype_callback,plotting_vars,plot_axes,ui});
set(ui.radio_plot,'callback',{@func_section_radio_callback,plotting_vars,plot_axes,ui});
set(ui.SliderH,'callback',{@func_section_slider_callback,plotting_vars,plot_axes,ui});