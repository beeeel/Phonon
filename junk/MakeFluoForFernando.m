Origins = 1:6;
figure(9)
clf
for or = Origins
    subplot(3,2,or)
    plot(squeeze(sum(fluo_data.(['origin' num2str(or) 'b']),[1,2])) ,'b')
    hold on
    plot(squeeze(sum(fluo_data.(['origin' num2str(or) 'g']),[1,2])),'g') 
end

%%
figure(10)
clf
subplot(2,2,1)
imagesc(fluo_data.origin1b(:,:,20))
title('live 20')
subplot(2,2,2)
imagesc(fluo_data.origin1b(:,:,1))
title('live 1')
subplot(2,2,3)
imagesc(fluo_data.origin1g(:,:,20))
subplot(2,2,4)
imagesc(fluo_data.origin1g(:,:,1))
%%
SelOr = 4;
SelFrs = [1, 60];

SelectedIms.Live1 = zeros(1200,1600,3,'uint8');
SelectedIms.Dead1 = zeros(1200,1600,3,'uint8');
SelectedIms.Live2 = zeros(1200,1600,3,'uint8');
SelectedIms.Dead2 = zeros(1200,1600,3,'uint8');
SelectedIms.Laser = imread('~/Data/phd/Phonon/nov21st/laser_align_above.png');


for T = 1:2
    SelectedIms.(['Live' num2str(T)])(:,:,2) = ...
        fluo_data.(['origin' num2str(SelOr) 'b'])(:,:,SelFrs(T)) - ...
        fluo_data.(['origin' num2str(SelOr) 'g'])(:,:,SelFrs(T));
    SelectedIms.(['Dead' num2str(T)])(:,:,1) = ...
        fluo_data.(['origin' num2str(SelOr) 'g'])(:,:,SelFrs(T));
    
end
figure(11)
clf
Plt = 1;
for Set = {'Live', 'Dead'}
    for T = 1:2
        subplot(2,2,Plt)
        Plt = Plt + 1;
        imagesc(SelectedIms.([Set{:} num2str(T)]))
        hold on
        plot(732, 552,'xk','LineWidth',2);
    end
    
end
%%
save('~/Data/phd/Phonon/processed_data/perspective_2020_fluo_images.mat','SelectedIms')
