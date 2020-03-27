function func_plot_basic_callback_multiscan(gcbo,eventdata,plotting_vars)




%plotting_vars = {data,axis_info,filename,k};

data= plotting_vars{1};
filename= plotting_vars{3};
axis_info= plotting_vars{2};
k= plotting_vars{4};
exp_params = plotting_vars{5};
plot_params = plotting_vars{6};
figure_handles = plotting_vars{7};

cP = get(gca,'Currentpoint');
y = cP(1,1);
x = cP(1,2);

if axis_info.axis2.pts>1
dx = axis_info.axis1.um(2)-axis_info.axis1.um(1);
else
    dx=0;
end

if axis_info.axis2.pts>1
dy = axis_info.axis2.um(2)-axis_info.axis2.um(1);
else
    dy=0;
end
x_sel = find(0.5*dx+axis_info.axis1.um>x,1);
y_sel = find(0.5*dy+axis_info.axis2.um>y,1);
[ x x_sel y y_sel];
if x>max(axis_info.axis1.um)
    x_sel=axis_info.axis2.pts;
end
if y>max(axis_info.axis2.um)
    y_sel=axis_info.axis2.pts;
end
if x<min(axis_info.axis1.um)
    x_sel=1;
end
if y<min(axis_info.axis2.um)
    y_sel=1;
end
if isempty(x_sel)
    x_sel=axis_info.axis2.pts;
end
if isempty(y_sel)
    y_sel=axis_info.axis2.pts;
end
[ x x_sel y y_sel]

%  figure_handles(k) = figure('position',[25+(k-1)*800 25 800 800]);

for k=1:length(figure_handles)
    figure(figure_handles(k))
    %figure_handles(k)
    
    if data.dc_count>0
        subplot(3,3,1);
        h2=get(gca,'Children');
        set(h2(1),'Xdata',axis_info.axis2.um(y_sel),'YData',axis_info.axis1.um(x_sel));
        %    h2(1).XData = axis_info.axis1.um(x_sel);
        %   h2(1).YData = axis_info.axis2.um(y_sel);
    end
    subplot(3,3,4);
    h2=get(gca,'Children');
    set(h2(1),'Xdata',axis_info.axis2.um(y_sel),'YData',axis_info.axis1.um(x_sel));
    %h2(1).XData = axis_info.axis1.um(x_sel);
    %h2(1).YData = axis_info.axis2.um(y_sel);
    
    subplot(3,3,7);
    h2=get(gca,'Children');
    set(h2(1),'Xdata',axis_info.axis2.um(y_sel),'YData',axis_info.axis1.um(x_sel));
    %h2(1).XData = axis_info.axis1.um(x_sel);
    %h2(1).YData = axis_info.axis2.um(y_sel);
    
    
    subplot(3,3,2:3);plot(1e9*data.raw_t{k},squeeze(data.raw_LP{k}(x_sel,y_sel,:)));
    xlabel('ns');title(sprintf('Raw trace:%1.1f,%1.2f',axis_info.axis1.um(x_sel),axis_info.axis2.um(y_sel)));
    subplot(3,3,5:6);plot(1e9*data.t_out{k},squeeze(data.pro{k}(x_sel,y_sel,:)));
    xlabel('ns');
    subplot(3,3,8:9);plot(1e-9*data.fx{k},squeeze(data.fft{k}(x_sel,y_sel,:)));
    xlabel('GHz');title(sprintf('peak:%1.2f',data.freq{k}(x_sel,y_sel)));
    drawnow
   % display('drawing')
%pause(0.1);
    if plot_params.figure_save ==1
        fig_name = strcat(filename,'_basic_plot_',num2str(k));
        set(gcf,'paperpositionmode','auto');
        print('-dpng',strcat(fig_name,'.png'));
        print('-depsc',strcat(fig_name,'.eps'));
    end
    
end