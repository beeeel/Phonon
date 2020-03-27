cd Documents/data/Phonon/oct17th/

%% load some data
% Load the phonon data
load processed_live_2019-10-18.mat
% Load the fluorescence data
load live_cells1_webcampics.mat
%% Slideshow of cross-section with fluorescent data
flythrough = 1;             % Move through time course without waiting for input
p_time = 0.1;               % Time to pause during flythough
makevid = 3;                % Set to 1 to make animated gif or 2 to make avi or 3 to save pngs
fname = 'wavelet_and_fluo'; % Filename base for saving

% Two example ROIs I've used - these might change
ROI_fluo = [773.000  398.000  152.0000  184.0000]; 
ROI_wv = [13 320 16 320];
show_ROIs = 0;
% This plots stuff
% Not tested the scales for fluo images
h = figure(17);
if makevid == 2
    v = VideoWriter(strcat(fname,'.avi'));
    v.FrameRate = 4;
    open(v);
end
for frame = 2%:30
    % Wavelet processed cross section with corrected axis
    subplot(2,1,1)
    a = imagesc(0:0.5:20.5,W_data.t*1.5,...
        rot90(squeeze(W_params.Frq(W_data.max_loc{1}(:,frame,:))),-1),...
        [5e9, 6e9]);
    colormap jet; axis image; a.Parent.YAxis.Direction = 'normal'; colorbar
    xlabel('x (\mu m)'); ylabel('z (\mu m)'); 
    title(cellstr(fluo_data.times{frame}));
    % Show ROI used for later processing
    if show_ROIs
        hold on
        plot([ROI_wv(1), ROI_wv(1), ROI_wv(1) + ROI_wv(3), ROI_wv(1) + ROI_wv(3), ROI_wv(1)]*0.5,...
            W_data.t([ROI_wv(2), ROI_wv(2) + ROI_wv(4), ROI_wv(2) + ROI_wv(4), ROI_wv(2), ROI_wv(2)])*1.5,'r')
        hold off
    end
    % Live assay fluorescent image with corrected axis
    subplot(2,2,3)
    imagesc((1:1600)./8.4,(1:1200)./8.4,fluo_data.blue_data(:,:,frame) - fluo_data.green_data(:,:,frame))
    axis image; axis off; 
    title('Live assay')
    % Guess what this does
    if show_ROIs
        hold on
        plot([ROI_fluo(1), ROI_fluo(1), ROI_fluo(1) + ROI_fluo(3), ROI_fluo(1) + ROI_fluo(3), ROI_fluo(1)],...
            [ROI_fluo(2), ROI_fluo(2) + ROI_fluo(4), ROI_fluo(2) + ROI_fluo(4), ROI_fluo(2), ROI_fluo(2)],'r')
        hold off
    end
    % Dead assay fluorescent image with corrected axis
    subplot(2,2,4)
    imagesc((1:1600)./8.4,(1:1200)./8.4,fluo_data.green_data(:,:,frame))
    axis image; axis off;
    title('Dead assay')
    % This doesn't do what you think
    if show_ROIs
        hold on
        plot([ROI_fluo(1), ROI_fluo(1), ROI_fluo(1) + ROI_fluo(3), ROI_fluo(1) + ROI_fluo(3), ROI_fluo(1)],...
            [ROI_fluo(2), ROI_fluo(2) + ROI_fluo(4), ROI_fluo(2) + ROI_fluo(4), ROI_fluo(2), ROI_fluo(2)],'r')
        hold off
        % Okay, that was a lie
    end
    % Either wait for user input, pause before next frame, or put frames
    % into a file for saving
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
    elseif makevid == 3
        drawnow
        saveas(gcf, strcat(fname,'.png'))
    end
end
% Tidy file stuff
if makevid == 2
    close(v);
    clear fr v
elseif makevid == 1
    clear im cm fr imind
end
%% Time of flight vs scan time colormap plot with raw trace
%
X = 10; % X point to plot scan time vs time of flight
T = 1; % Time (index) to show raw trace
h = figure(7);
% Plot a point's data with scan time on X and time of flight (z) on Y
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
%% ROI average values against scan time plots
% Pick some ROIs and extract the data for plotting
%{
figure
imshow(im_data.blue_data(:,:,1))
ROI = drawrectangle;
ROI = ROI.Position;
%}
ROI_fluo = [773.000  398.000  152.0000  184.0000];
ROI_fluobg = ROI_fluo;
ROI_fluobg(2) = ROI_fluo(2)-ROI_fluo(4);
% Take the area of the scan cell, and an adjacent background area of the
% same size/shape
liveBg = fluo_data.blue_data(ROI_fluobg(2):ROI_fluobg(2)+ROI_fluobg(4),ROI_fluobg(1):ROI_fluobg(1)+ROI_fluobg(3),:) ...
    - fluo_data.green_data(ROI_fluobg(2):ROI_fluobg(2)+ROI_fluobg(4),ROI_fluobg(1):ROI_fluobg(1)+ROI_fluobg(3),:);
liveSignal = fluo_data.blue_data(ROI_fluo(2):ROI_fluo(2)+ROI_fluo(4),ROI_fluo(1):ROI_fluo(1)+ROI_fluo(3),:) ...
    - fluo_data.green_data(ROI_fluo(2):ROI_fluo(2)+ROI_fluo(4),ROI_fluo(1):ROI_fluo(1)+ROI_fluo(3),:);
deadSignal = fluo_data.green_data(ROI_fluo(2):ROI_fluo(2)+ROI_fluo(4),ROI_fluo(1):ROI_fluo(1)+ROI_fluo(3),:);
deadBg = fluo_data.green_data(ROI_fluobg(2):ROI_fluobg(2)+ROI_fluobg(4),ROI_fluobg(1):ROI_fluobg(1)+ROI_fluobg(3),:);
% Take a ROI and sum it along the length of the slice and up the depth of
% the cell
ROI_wav = sum(W_params.Frq(W_data.max_loc{1}(13:29,:,320:640)),[1,3])...
    ./(length(13:29) * length(320:640));
%% Do the plotting
% Plot the ROI mean frequency against scan time
figure(19)
subplot(3,1,1)
plot(24*[fluo_data.times{:}],ROI_wav)
xlabel('Time (hrs)'), ylabel('F (Hz)'), ylim([5.1e9, 5.6e9])
title('Brillouin frequency')
% Live fluorescent ROI mean against scan time
subplot(3,1,2)
semilogy(24*[fluo_data.times{:}],squeeze(sum(liveSignal,[1,2])./sum(liveBg,[1,2])))
xlabel('Time (hrs)'), ylabel('A.U.'), ylim([0.9, 5.5])
title('Live signal / background')
% Dead florescent ROI mean against scan time
subplot(3,1,3)
semilogy(24*[fluo_data.times{:}],squeeze(sum(deadSignal,[1,2]) ./ sum(deadBg,[1,2])))
title('Dead signal / background')
xlabel('Time (hrs)'), ylabel('A.U.')