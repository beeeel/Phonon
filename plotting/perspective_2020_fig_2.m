%% Plots for Fernando
% Need to refactor this to tidy variables/scope
clear 
close all
% I assume you've downloaded it to default location, but you might want to
% change this 

% check hostname and set download location appropriately
Dir = '~/Downloads/';
load([Dir '.mat'])

%% You might want to change these things
% Font size for axis labels and titles
FSize = 16;
% Show error bars on phonon data? Error bars come from standard deviation
% of frequency
ShowErrorBars = false;
% Prefix for legend entries
Leg_str = 'cell ';

%% You probably don't want to change these things
% Time points to display (November 21st dataset has 60 t points)
t_pts = [1, 60];
% Points (along axis of line scan) to use from phonon data
x_pt = 12:18;
% Half-width, in px, of the ROI in fluorescent images
sz = 30;

% Centre co-ordinates for live cells - manually determined
centres = [744, 542; 756, 437; 752,475; 771 430; 767 422; 763 460];
% Background co-ordinates (no cell close to these points)
bgs = [580 331; 287 278; 363 475; 987 597; 662 164; 741 263];
% Determine number of origins
n_or = length(fieldnames(data));

%% This is where the fun begins
% Initialise empty arrays
l_sig = zeros(size(fluo_data.origin1b,3),size(centres,1));
l_bg = l_sig;
d_sig = l_sig;
d_bg = l_sig;

% Fill arrays with fluorescence values
for ori = 1:size(centres,1)
    % Live signal is blue channel - green channel
    l_sig(:,ori) = squeeze(mean(fluo_data.(['origin' num2str(ori) 'b'])...
        (centres(ori,2)-sz:centres(ori,2)+sz, centres(ori,1)-sz:centres(ori,1)+sz,:)...
        - fluo_data.(['origin' num2str(ori) 'g'])...
        (centres(ori,2)-sz:centres(ori,2)+sz, centres(ori,1)-sz:centres(ori,1)+sz,:)...
        , [1 2]));
    % Dead signal is green channel
    d_sig(:,ori) = squeeze(mean(fluo_data.(['origin' num2str(ori) 'g'])...
        (centres(ori,2)-sz:centres(ori,2)+sz, centres(ori,1)-sz:centres(ori,1)+sz,:)...
        , [1 2]));
    % Live background is blue background - green background
    l_bg(:,ori) = squeeze(mean(fluo_data.(['origin' num2str(ori) 'b'])...
        (bgs(ori,2)-sz:bgs(ori,2)+sz, bgs(ori,1)-sz:bgs(ori,1)+sz,:)...
        - fluo_data.(['origin' num2str(ori) 'g'])...
        (bgs(ori,2)-sz:bgs(ori,2)+sz, bgs(ori,1)-sz:bgs(ori,1)+sz,:)...
        , [1 2]));
    % Dead background is green background
    d_bg(:,ori) = squeeze(mean(fluo_data.(['origin' num2str(ori) 'g'])...
        (bgs(ori,2)-sz:bgs(ori,2)+sz, bgs(ori,1)-sz:bgs(ori,1)+sz,:)...
        , [1 2]));
end

% Extract file times from fluorescence data
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

% Make a cell variable with {'cell 1', 'cell 2', etc} inside
Leg = cell(0);
for scan = 1:n_or
    Leg{scan} = [Leg_str num2str(scan)];
end
%% Simple scatter plot - live and dead
Syms = {'o' 'x' '+' 's' 'd' 'v'};

fh = figure(28);
clf
hold on
% For two time points
for T_idx = 1:2
    T_data = T_idx-0.03 + (1:n_or)./100;
    % For each scan origin (each cell scanned)
    for scan = 1:n_or
        % Left axis, plot with or without errorbars
        yyaxis left
        if ShowErrorBars
            errorbar(T_data(scan),...
                mean(data.(['scan' num2str(scan)]).freq{1}(x_pt,t_pts(T_idx))),...
                std(data.(['scan' num2str(scan)]).freq{1}(x_pt,t_pts(T_idx))),...
                Syms{scan}); %#ok<*UNRCH>
        else
            plot(T_data(scan), ...
                mean(data.(['scan' num2str(scan)]).freq{1}(x_pt,t_pts(T_idx))),...
                Syms{scan});
        end
    end
    yyaxis right
    LiveLine = plot(T_data,l_sig(t_pts(T_idx),:)./l_bg(t_pts(T_idx),scan));
    DeadLine = plot(T_data,d_sig(t_pts(T_idx),:)./d_bg(t_pts(T_idx),scan));
    set(LiveLine,{'Marker'},{'x'})
end
xlim([0.9 2.1])
xticklabels({'Before','','','','','After'});
legend(Leg{:})
%% Frequency, live fluo, dead fluo on three axes

figure(29)
clf
subplot(3,1,1)
hold on
for scan = 1:n_or
    if ShowErrorBars
        errorbar(times(:,scan),mean(data.(['scan' num2str(scan)]).freq{1}(x_pt,:)),std(data.(['scan' num2str(scan)]).freq{1}(x_pt,:)));
    else
        plot(times(:,scan),mean(data.(['scan' num2str(scan)]).freq{1}(x_pt,:)));
    end
end
title('Peak frequency','FontSize',FSize)
ylabel('F_b (GHz)','FontSize',FSize-2)
legend(Leg{:})

subplot(3,1,2)
semilogy(times(:,1),l_sig./l_bg)
title('live fluorescent signal','FontSize',FSize)
ylabel('Fluorescent signal (AU)','FontSize',FSize-2)%legend(fieldnames(data))

subplot(3,1,3)
semilogy(times(:,1),d_sig./d_bg)
title('dead fluorescent signal','FontSize',FSize)
xlabel('Scan time (hours)','FontSize',FSize+2), ylabel('Fluorescent signal (AU)','FontSize',FSize-2)