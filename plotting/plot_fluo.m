%% This has been poorly maintained
% This is a variable I don't know the source of...
c_webcam = [0 0];
%% Measuring cell width using accoustics
scan_line = round([c_webcam(1) + [0, 0]; c_webcam(2) + [-8.4*30, 0]]);

figure(7)
for scan = 1:length(fieldnames(data))
    subplot(3,2,scan)
    hold off
    plot(normalize(data.(['scan' num2str(scan)]).freq{1}(:,1),'range'),'b')
    hold on
    %plot(normalize(data.(['scan' num2str(scan)]).dc{1}(:,1),'range'),'k')
    plot(linspace(1,31,scan_line(4)-scan_line(2)+1),...
        normalize(double(fluo_data.(['origin' num2str(scan) 'b'])...
        (scan_line(2):scan_line(4),scan_line(1))),'range') ,'r')
    title(['Origin ' num2str(scan)])
    if scan == 1
        title(['Normalized cell profiles for origin ' num2str(scan)])
        legend({'freq', 'fluorescent'},'location','south')
    elseif scan > 4
        xlabel('X (\mum)')
    end
    if mod(scan,2) == 1
        ylabel('AU')
    end
end
%% Multi-origin fluorescent plots all in one
tp = 1;
c_webcam = size(fluo_data.blue_data)/2;
scan_line = [c_webcam(1) + [0, 0]; c_webcam(2) + [-8.4*30, 0]];
n_origins = (length(fieldnames(fluo_data)) - 4) / 5; % Exclude origin0, each origin has 5 fields
figure(15)
for or = 1:n_origins
    txt = sprintf(' assay origin %i at time %gmin', or, fluo_data.(['times' num2str(or)])(tp)*24*60);
    subplot(3,4,or * 2 - 1)
    imagesc(fluo_data.(['origin' num2str(or) 'b'])(:,:,tp) - fluo_data.(['origin' num2str(or) 'g'])(:,:,tp))
    hold on
    plot(scan_line(1,:),scan_line(2,:),'k:','LineWidth',2)
    title(['Live' txt]), axis off image
    
    subplot(3,4,or * 2)
    imagesc(fluo_data.(['origin' num2str(or) 'g'])(:,:,tp))
    hold on
    plot(scan_line(1,:),scan_line(2,:),'k:','LineWidth',2)
    title('Dead'), axis off image
end
%% Freq spectrum with fluorescent overlaid
X = 13:17;
figure(53)
for sc = fieldnames(data)'
    idx = str2double(sc{:}(end));
    subplot(3,2,idx)
    imagesc(data.(sc{:}).fx{1}./1e9,24*fluo_data.(['times' sc{:}(end)]),squeeze(mean(data.(sc{:}).fft{1}(X,:,:),1)))
    hold on
    plot(normalize(l_sig(:,idx)./l_bg(:,idx),'range')*4,24*fluo_data.(['times' sc{:}(end)]),'g','LineW',2)
    plot(normalize(d_sig(:,idx)./d_bg(:,idx),'range')*4,24*fluo_data.(['times' sc{:}(end)]),'r','LineW',2)
    hold off
    xlabel('F_b (GHz)'), ylabel('Scan time (hrs)'), title(['Frequency spectrum for origin ' sc{1}(end)])
    legend('Live assay','Dead assay')
    if 0
        try saveas(gcf,sprintf('figs/origin%i_freq_spectrum_fluo.png',idx))
        end
    end
end
try ls('figs')
end
%% DC with fluorescent overlaid
X = 10:20;
figure(51)
for sc = fieldnames(data)'
    idx = str2double(sc{:}(end));
    rn = range(mean(data.(sc{:}).dc{1}(X,:),1));
    mn = min(mean(data.(sc{:}).dc{1}(X,:),1));
    subplot(3,2,idx)
    plot(fluo_data.(['times' num2str(idx)])*24,squeeze(mean(data.(sc{:}).dc{1}(X,:),1)),'LineW',2)
    hold on
    plot(24*fluo_data.(['times' num2str(idx)]),mn+rn*normalize(l_sig(:,idx)./l_bg(:,idx),'range'))
    plot(24*fluo_data.(['times' num2str(idx)]),mn+rn*normalize(d_sig(:,idx)./d_bg(:,idx),'range'))
    hold off
    xlabel('Scan time (hrs)'), ylabel('DC signal (V)')

    if idx == 1
        title(['DC signal with fluorescence overlaid for origin ' sc{:}(end)])
        legend({'DC','Live assay','Dead assay'},'Location','best')
    else 
        title(['Origin ' sc{:}(end)])
    end
end
%%
% run register_lasers

%tp = 1; % timepoint
n_im = size(fluo_data.origin1b,3);
scan_line = [c_webcam(1) + [0, 0]; c_webcam(2) + [-8.4*30, 0]];
fh = figure(13);
plotall(struct('Value',1),1,{fluo_data,scan_line})
sl = uicontrol(fh,'Style','slider','Units','normalized','Position',[0.01 0.01 0.98 0.05],...
    'Callback',{@plotall,fluo_data,scan_line},'Value',1,'Min',1,...
    'Max',n_im,'SliderStep',[1/n_im 10/n_im]);
%%

function plotall(src,~,input)
whos
if isstruct(src)
    tp = ceil(src.Value);
else
    tp = 1;
end
n_origins = (length(fieldnames(input{1})) - 4) / 5; % Exclude origin0, each origin has 4 fields
for or = 1:n_origins
    txt = sprintf(' assay origin %i at time %gmin', or, input{1}.(['times' num2str(or)])(tp)*24*60);
    subplot(3,4,or * 2 - 1)
    imagesc(input{1}.(['origin' num2str(or) 'b'])(:,:,tp) - input{1}.(['origin' num2str(or) 'g'])(:,:,tp))
    hold on
    plot(input{2}(1,:),input{2}(2,:),'k:','LineWidth',2)
    title(['Live' txt]), axis off image
    
    subplot(3,4,or * 2)
    imagesc(input{1}.(['origin' num2str(or) 'g'])(:,:,tp))
    hold on
    plot(input{2}(1,:),input{2}(2,:),'k:','LineWidth',2)
    title('Dead'), axis off image
    drawnow
end
end