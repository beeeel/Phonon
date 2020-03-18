%% Co-register laser spots
% Use the saturation to segment the laser spot, and regionprops to find the
% centre.
%% Load data
webcam = rgb2gray(imread('laser_align_above.png'));
andor = loadi('laser_align_andor.dat',[658,496]);
%% Threshold
th_webcam = webcam == max(webcam,[],'all');
th_andor = andor == max(andor,[],'all'); 

pr_webcam = regionprops(bwareaopen(th_webcam,1000),'Centroid');
pr_andor = regionprops(th_andor,'Centroid');

c_webcam = pr_webcam.Centroid;
c_andor = pr_andor.Centroid;
%%
fh = figure(23);
subplot(2,2,1)
imagesc(webcam)
axis image
subplot(2,2,2)
imagesc(andor)
axis image, colormap gray
subplot(2,2,3)
imagesc(th_webcam)
axis image
hold on
plot(c_webcam(1),c_webcam(2),'x')
subplot(2,2,4)
imagesc(th_andor)
axis image, colormap gray
hold on
plot(c_andor(1),c_andor(2),'x')
%%
clear webcam andor th_webcam th_andor pr_webcam pr_andor
close(fh)