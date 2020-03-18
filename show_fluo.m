% Load the images in - this takes the raw files, sorts them into order and
% outputs a tidy struct. The second argin is save (0/1)
im_data = func_tidy_webcams('live_cells1',0,111);
%% Show a nice video of death
figure
for frame = 1:size(im_data.blue_data,3)
    imshowpair(im_data.blue_data(:,:,frame) - im_data.green_data(:,:,frame)...
        , im_data.green_data(:,:,frame),'montage')
    title(num2str(frame))
    pause(0.1)
end
%% Pick the scan cell ROI
%{
figure
imshow(im_data.blue_data(:,:,1))
ROI = drawrectangle;
ROI = ROI.Position;
%}
ROI = [773.000  461.000  152.0000  184.0000];
ROIbg = ROI;
ROIbg(2) = ROI(2)-ROI(4);
%%
% Take the area of the scan cell, and an adjacent background area of the
% same size/shape
liveBg = im_data.blue_data(ROIbg(2):ROIbg(2)+ROIbg(4),ROIbg(1):ROIbg(1)+ROIbg(3),:) ...
    - im_data.green_data(ROIbg(2):ROIbg(2)+ROIbg(4),ROIbg(1):ROIbg(1)+ROIbg(3),:);
liveSignal = im_data.blue_data(ROI(2):ROI(2)+ROI(4),ROI(1):ROI(1)+ROI(3),:) ...
    - im_data.green_data(ROI(2):ROI(2)+ROI(4),ROI(1):ROI(1)+ROI(3),:);
deadSignal = im_data.green_data(ROI(2):ROI(2)+ROI(4),ROI(1):ROI(1)+ROI(3),:);
deadBg = im_data.green_data(ROIbg(2):ROIbg(2)+ROIbg(4),ROIbg(1):ROIbg(1)+ROIbg(3),:);
%% Show how the signal from the ROI changes with time
figure
subplot(2,1,1)
plot(fliplr(24*([im_data.times{:}]-im_data.times{end})),squeeze(sum(liveSignal(:,:,2:end),[1,2])./sum(liveBg(:,:,2:end),[1,2])))
title('Live signal / background')
subplot(2,1,2)
plot(squeeze(sum(deadSignal,[1,2])./sum(deadBg,[1,2])))
title('Dead signal / background')