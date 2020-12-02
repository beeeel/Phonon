% Compare photobleaching
load Data/phd/Phonon/oct17thFernando/live_cells1_webcampics.mat
%% Get background mean to compensate for auto white-balance on cheap webcam
bgROI = drawpolygon(gca);
bgMask = bgROI.createMask;
bgMean = mean(bgMask .* data,[1,2]);
%%
% ScanCell, and OtherCell1&2 were created similarly to above. 
%%
clf
hold on
plot(24*[fluo_data.times{:}]',squeeze(mean(ScanCell,[1,2])./bgMean))
plot(24*[fluo_data.times{:}]',squeeze(mean(OtherCell1,[1,2])./bgMean))
plot(24*[fluo_data.times{:}]',squeeze(mean(OtherCell2,[1,2])./bgMean))
xlabel('Time (hours)')
ylabel('Fluorescent intensity')
title('Dead fluorescent signal from 3 cells') 
legend('scanned','not scanned','not scanned')
