%% For multi origin scans
dataset = 1127;
dir = '/home/will/Documents/data/Phonon/';
if isempty(whos('fluo_data'))
    if dataset == 1121
        load([dir 'nov21st/live_3T31_webcampics.mat'])
        run([dir 'nov21st/test_multiscan.m'])
        centres = [744, 542; 756, 437; 752,475; 771 430; 767 422; 763 460];
        bgs = [580 331; 287 278; 363 475; 987 597; 662 164; 741 263];
    elseif dataset == 1120
        load([dir 'nov20th/live_3T3_noAu1_webcampics.mat'])
        centres = [786, 429];
        bgs = [417 297];
    elseif dataset == 1127
        load([dir 'nov27th/live_3T31_webcampics.mat'])
        run([dir 'nov27th/test_multiscan.m'])
        centres = [748 415 474 175 1341 477 417 801 324 562];
        bgs = [1081 238];
    end
end

n_or = length(fieldnames(data));
sz = 30;
l_sig = zeros(size(fluo_data.origin1b,3),size(centres,1));
l_bg = l_sig;
d_sig = l_sig;
d_bg = l_sig;
for ori = 1:size(centres,1)
    l_sig(:,ori) = squeeze(mean(fluo_data.(['origin' num2str(ori) 'b'])...
        (centres(ori,2)-sz:centres(ori,2)+sz, centres(ori,1)-sz:centres(ori,1)+sz,:)...
        - fluo_data.(['origin' num2str(ori) 'g'])...
        (centres(ori,2)-sz:centres(ori,2)+sz, centres(ori,1)-sz:centres(ori,1)+sz,:)...
        , [1 2]));
    d_sig(:,ori) = squeeze(mean(fluo_data.(['origin' num2str(ori) 'g'])...
        (centres(ori,2)-sz:centres(ori,2)+sz, centres(ori,1)-sz:centres(ori,1)+sz,:)...
        , [1 2]));
    l_bg(:,ori) = squeeze(mean(fluo_data.(['origin' num2str(ori) 'b'])...
        (bgs(ori,2)-sz:bgs(ori,2)+sz, bgs(ori,1)-sz:bgs(ori,1)+sz,:)...
        - fluo_data.(['origin' num2str(ori) 'g'])...
        (bgs(ori,2)-sz:bgs(ori,2)+sz, bgs(ori,1)-sz:bgs(ori,1)+sz,:)...
        , [1 2]));
    d_bg(:,ori) = squeeze(mean(fluo_data.(['origin' num2str(ori) 'g'])...
        (bgs(ori,2)-sz:bgs(ori,2)+sz, bgs(ori,1)-sz:bgs(ori,1)+sz,:)...
        , [1 2]));
end

times = zeros(length(fluo_data.times1),n_or);
if (length(fieldnames(fluo_data)) - 4) / 5 == length(fieldnames(data))
    for scan = 1:n_or
        times(:,scan) = fluo_data.(['times' num2str(scan)])*24;
    end
else
    for scan = 1:n_or
        times(:,scan) = fluo_data.times1*24;
    end
end
    
%% Frequency, live fluo, dead fluo on three axes
x_pt = 12:18;
FSize = 16;


figure(29)
subplot(3,1,1)
for scan = 1:n_or
    plot(times(:,scan),mean(data.(['scan' num2str(scan)]).freq{1}(x_pt,:)));
    if scan == 1
        hold on
    end
end
hold off
title('Peak frequency','FontSize',FSize)
ylabel('F_b (GHz)','FontSize',FSize-2)
legend(fieldnames(data))

subplot(3,1,2)
semilogy(times(:,1),l_sig./l_bg)
title('live fluorescent signal (scan 1 only)','FontSize',FSize)
ylabel('Fluorescent signal (AU)','FontSize',FSize-2)%legend(fieldnames(data))

subplot(3,1,3)
semilogy(times(:,1),d_sig./d_bg)
title('dead fluorescent signal (scan 1 only)','FontSize',FSize)
xlabel('Scan time (hours)','FontSize',FSize+2), ylabel('Fluorescent signal (AU)','FontSize',FSize-2)
%legend(fieldnames(data))

%% Same as previous but normalize death time
x_pt = 12:18;
scans = 2:n_or;
FSize = 16;

Freqs = zeros(axis_info.scan1.axis2.pts, n_or);
for scan = scans
    Freqs(:,scan) = mean(data.(['scan' num2str(scan)]).freq{1}(x_pt,:));
end
% Live signal has a sharp downtick, gives good idea of when cell dies
LiveSigChange = diff(l_sig);
[LiveMax, LiveIdx] = max(abs(LiveSigChange));
LiveIdxs = sub2ind(size(l_sig),LiveIdx,1:6);

Xdata = times(:,scans) - times(LiveIdxs(2:6));

figure(30)
subplot(3,1,1)
cla
hold on
for scan = scans
    plot(times(:,scan) - times(LiveIdx(scan),scan),Freqs(:,scan));
end
hold off
title('Peak frequency','FontSize',FSize)
ylabel('F_b (GHz)','FontSize',FSize-2)
FNames = fieldnames(data);
legend(FNames{scans})

subplot(3,1,2)
semilogy(Xdata,l_sig(:,scans)./l_bg(:,scans))
title('live fluorescent signal','FontSize',FSize)
ylabel('Fluorescent signal (AU)','FontSize',FSize-2)
%legend(fieldnames(data))

subplot(3,1,3)
semilogy(Xdata,d_sig(:,scans)./d_bg(:,scans))
title('dead fluorescent signal','FontSize',FSize)
xlabel('Scan time (hours)','FontSize',FSize+2), ylabel('Fluorescent signal (AU)','FontSize',FSize-2)
%legend(fieldnames(data))


%%
FileName = 'fluo_freq_2cells.png';
Path = '~/Pictures/';
N_lines = 2;
Start = 3;
FSize = 18;
fh = figure(33);
clf
hold on
yyaxis left
LSpec = {'-','--',':'};
LCol = {[0 0 0], [0 0 1], [0.25, 0.75, 0.75]};
LWidth = 2.5;
Range = Start:Start+N_lines-1;
for scan = Range
    Line = plot(times(:,scan),mean(data.(['scan' num2str(scan)]).freq{1}(x_pt,:)),LSpec{1},'Color',LCol{scan-2});
    Line.LineWidth = LWidth;
end
ylabel('F_b (GHz)','FontSize',FSize+2)
yyaxis right
for scan = Range
    Line = semilogy(times(:,scan),normalize(l_sig(:,scan)./l_bg(:,scan),'range'),LSpec{2},'Color',LCol{scan-2});
    Line.LineWidth = LWidth;
end
for scan = Range
    Line = semilogy(times(:,scan),normalize(d_sig(:,scan)./d_bg(:,scan),'range'),LSpec{3},'Color',LCol{scan-2});
    Line.LineWidth = LWidth;
end
ylabel('Fluorescent signal (AU)','FontSize',FSize+2)
xlabel('Scan time (hours)','FontSize',FSize+2)
title('Brillouin Frequency and fluorescent intensities for two cells','FontSize',FSize+2)
legend([strcat(repmat({'Freq '},1,N_lines),string(1:N_lines)), ...
    strcat(repmat({'Live fluo '},1,N_lines),string(1:N_lines)),...
    strcat(repmat({'Dead fluo '},1,N_lines),string(1:N_lines))],'FontSize',FSize)
saveas(fh, [Path FileName])
%% Multi-cell fluorescent dead/alive
dataset = 1127;
if isempty(whos('fluo_data'))
    if dataset == 1121
        load /home/fperez/My_scan/November/21st/live_3T31_webcampics.mat
        centres = [744, 542, 1028 661, 208 266; 756, 437 1079 428, 471 985;...
            752,475 1059, 170, 178 89; 771 430 228 454, 957 990; ...
            767 422 188 282 1140 1092; 763 460 309 818 1200 99];
        bgs = [580 331; 287 278; 363 475; 987 597; 662 164; 741 263];
    elseif dataset == 1120
        load /home/fperez/My_scan/November/20th/live_3T3_noAu1_webcampics.mat
        centres = [786, 429, 927 216 1456 836 255 884];
        bgs = [417 297];
    elseif dataset == 1127
        load /home/fperez/My_scan/November/27th/live_3T31_webcampics.mat
        centres = [748 415 474 175 1341 477 417 801 324 562];
        bgs = [1081 238];
    end
end

sz = 30;

n_t = size(fluo_data.origin1b,3);
n_pt = size(centres,2)/2;
n_or = (length(fieldnames(fluo_data)) - 4) / 5;

times = zeros(length(fluo_data.times1),n_or);
for scan = 1:n_or
    times(:,scan) = fluo_data.(['times' num2str(scan)])*24;
end

l_sig = zeros(n_t,n_or,n_pt);
d_sig = l_sig;
l_bg = zeros(n_t,n_or);
d_bg = l_bg;
for pt = 0:2:2*n_pt-1
    for ori = 1:n_or
        pti = pt/2 + 1;
        l_sig(:,ori,pti) = squeeze(mean(fluo_data.(['origin' num2str(ori) 'b'])...
            (centres(ori,2+pt)-sz:centres(ori,2+pt)+sz, centres(ori,1+pt)-sz:centres(ori,1+pt)+sz,:)...
            - fluo_data.(['origin' num2str(ori) 'g'])...
            (centres(ori,2+pt)-sz:centres(ori,2+pt)+sz, centres(ori,1+pt)-sz:centres(ori,1+pt)+sz,:)...
            , [1 2]));
        d_sig(:,ori,pti) = squeeze(mean(fluo_data.(['origin' num2str(ori) 'g'])...
            (centres(ori,2+pt)-sz:centres(ori,2+pt)+sz, centres(ori,1+pt)-sz:centres(ori,1+pt)+sz,:)...
            , [1 2]));
        l_bg(:,ori) = squeeze(mean(fluo_data.(['origin' num2str(ori) 'b'])...
            (bgs(ori,2)-sz:bgs(ori,2)+sz, bgs(ori,1)-sz:bgs(ori,1)+sz,:)...
            - fluo_data.(['origin' num2str(ori) 'g'])...
            (bgs(ori,2)-sz:bgs(ori,2)+sz, bgs(ori,1)-sz:bgs(ori,1)+sz,:)...
            , [1 2]));
        d_bg(:,ori) = squeeze(mean(fluo_data.(['origin' num2str(ori) 'g'])...
            (bgs(ori,2)-sz:bgs(ori,2)+sz, bgs(ori,1)-sz:bgs(ori,1)+sz,:)...
            , [1 2]));
    end
end
%%
figure(31)
for ori = 1:n_or
    for pt=1:n_pt
        if n_or > 1
            subplot(3,4,ori*2-1)
        else
            subplot(1,2,ori*2-1)
        end
        a = semilogy(times(:,ori),l_sig(:,ori,pt)./l_bg(:,ori));
        hold on
        if n_or > 1
            subplot(3,4,ori*2)
        else
            subplot(1,2,ori*2)
        end
        b = semilogy(times(:,ori),d_sig(:,ori,pt)./d_bg(:,ori));
        hold on
        if pt == 1
            a.LineWidth=2;
            b.LineWidth=2;
        end
    end
    if n_or > 1
        subplot(3,4,ori*2-1)
    else
        subplot(1,2,ori*2-1)
    end
    hold off
    title(sprintf('Live assay origin %i',ori))
    if (n_or - ori ) < 3
        xlabel('Time (hours)')
    end
    if mod(ori,2) == 1
        ylabel('Fluorescent signal (AU)')
    end
    
    if n_or > 1
        subplot(3,4,ori*2)
    else
        subplot(1,2,ori*2)
    end
    hold off
    title(sprintf('Dead assay origin %i',ori))
    if (n_or - ori ) < 3
        xlabel('Time (hours)')
    end
    
end
    