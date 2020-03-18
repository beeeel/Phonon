sc = 'scan5';
subplot(2,1,1)
% Between the indexing, squeezing and the rotation, the horizontal axis
% becomes flipped, and this can be verified by indexing and comparing the
% two images.
a = imagesc(1:1:31, W_data.(sc).t, ...
    fliplr(rot90(squeeze(W_params.(sc).Frq(W_data.(sc).max_loc{1}(:,2,:))),-1)),...
    [5e9 6e9]); 
axis image
a.Parent.YAxis.Direction='normal';
ylabel('time of flight (ns)'), xlabel('x (\mum)')
subplot(2,1,2)
a = imagesc(fluo_data.times1*24*60, W_data.(sc).t, ...
    fliplr(rot90(squeeze(W_params.(sc).Frq(W_data.(sc).max_loc{1}(15,:,:))),-1)),...
    [5e9 6e9]); 
%axis image
a.Parent.YAxis.Direction='normal';
ylabel('time of flight (ns)'), xlabel('scan time (minutes)')

%%
figure(9)
plot(W_data.(sc).t, fliplr(rot90(squeeze(W_params.(sc).Frq(W_data.(sc).max_loc{1}(15,2,:))),-1)))
ylim([5 6]*1e9), xlabel('Time of flight (ns)'), ylabel('F_b (GHz)')