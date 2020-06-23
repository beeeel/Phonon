load('~/Downloads/perspective_2020_fluo_images.mat')
%%
figure(11)
clf
Plt = 1;
for Set = {'Live', 'Dead'}
    for T = 1:2
        subplot(2,2,Plt)
        Plt = Plt + 1;
        imagesc(SelectedIms.([Set{:} num2str(T)]))
        hold on
        plot(732, 552,'xr','LineWidth',2);
    end
    
end