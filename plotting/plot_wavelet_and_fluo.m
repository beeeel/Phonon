%% Load the phonon data
load /home/fperez/My_scan/October/17th/processed_live_2019-10-18.mat
%% This loads the fluorescence data
load /home/fperez/My_scan/October/17th/live_cells1_webcampics.mat
%% Things you might want to change
flythrough = 0;             % Move through time course without waiting for input
p_time = 0.1;               % Time to pause during flythough
makevid = 0;                % Set to 1 to make animated gif or 2 to make avi
fname = 'wavelet_and_fluo'; % Filename base for saving
% Two example ROIs I've used - these might change
% ROI_fluo = [773.000  398.000  152.0000  184.0000]; 
% ROI_wv = [13 320 16 320];
show_ROIs = 0;
%% This plots stuff
% Not tested the scales for fluo images
h = figure(17);
if makevid == 2
    v = VideoWriter(strcat(fname,'.avi'));
    v.FrameRate = 4;
    open(v);
end
for frame = 2%:30
    subplot(2,1,1)
    a = imagesc(0:0.5:20.5,W_data.t,...
        rot90(squeeze(W_params.Frq(W_data.max_loc{1}(:,frame,:))),-1),...
        [5e9, 6e9]);
    colormap jet; axis image; a.Parent.YAxis.Direction = 'normal'; colorbar
    xlabel('x (\mu m)'); ylabel('time of flight (ns)'); 
    title(num2str(fluo_data.times{frame}));
    if show_ROIs
        hold on
        plot([ROI_wv(1), ROI_wv(1), ROI_wv(1) + ROI_wv(3), ROI_wv(1) + ROI_wv(3), ROI_wv(1)]*0.5,...
            W_data.t([ROI_wv(2), ROI_wv(2) + ROI_wv(4), ROI_wv(2) + ROI_wv(4), ROI_wv(2), ROI_wv(2)])*1.5,'r')
        hold off
    end
    
    subplot(2,2,3)
    imagesc((1:1600)*8.4,(1:1200)*8.4,fluo_data.blue_data(:,:,frame) - fluo_data.green_data(:,:,frame))
    axis image; axis off; 
    title('Live assay')
    if show_ROIs
        hold on
        plot([ROI_fluo(1), ROI_fluo(1), ROI_fluo(1) + ROI_fluo(3), ROI_fluo(1) + ROI_fluo(3), ROI_fluo(1)],...
            [ROI_fluo(2), ROI_fluo(2) + ROI_fluo(4), ROI_fluo(2) + ROI_fluo(4), ROI_fluo(2), ROI_fluo(2)],'r')
        hold off
    end
    
    subplot(2,2,4)
    imagesc((1:1600)*8.4,(1:1200)*8.4,fluo_data.green_data(:,:,frame))
    axis image; axis off;
    title('Dead assay')
    if show_ROIs
        hold on
        plot([ROI_fluo(1), ROI_fluo(1), ROI_fluo(1) + ROI_fluo(3), ROI_fluo(1) + ROI_fluo(3), ROI_fluo(1)],...
            [ROI_fluo(2), ROI_fluo(2) + ROI_fluo(4), ROI_fluo(2) + ROI_fluo(4), ROI_fluo(2), ROI_fluo(2)],'r')
        hold off
    end
    
    if makevid == 0 && flythrough == 0
        input('')
    elseif makevid == 0 && flythrough == 1
        pause(p_time)
    elseif makevid ==1
        drawnow
        fr = getframe(h);
        im = frame2im(fr);
        [imind,cm] = rgb2ind(im,256);
        % Write to the GIF File
        if frame == 1
            imwrite(imind,cm,strcat(fname,'.gif'),'gif', 'Loopcount',inf);
        else
            imwrite(imind,cm,strcat(fname,'.gif'),'gif','WriteMode','append');
        end
    elseif makevid == 2
        drawnow
        fr = getframe(h);
        writeVideo(v, fr);
    end
end
if makevid == 2
    close(v);
    clear fr v
elseif makevid == 1
    clear im cm fr imind
end
%% Scan time vs time of flight
X = 10; % X point to plot scan time vs time of flight
T = 1; % Time (index) to show raw trace
h = figure(7);
subplot(2,1,1)
imagesc(24*[fluo_data.times{:}],...
    W_data.t,...
    fliplr(rot90(squeeze(W_params.Frq(W_data.max_loc{1}(X,:,:))),-1)),...
    [5e9, 6e9])%, colorbar
title(sprintf('X point %d against scan time',X))
xlabel('Scan time (hrs)')
ylabel('Time of flight (ns)')
ax = gca; ax.YDir = 'normal';
hold on
plot(24*[fluo_data.times{[T T]}], W_data.t([1,end]), 'r--');
subplot(212)
plot(data.t_out, squeeze(data.pro{1}(X, T, :)))
title(sprintf('Raw trace at %0.2g hours',fluo_data.times{T}*24))
