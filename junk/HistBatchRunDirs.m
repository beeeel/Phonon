%% Compare Nocodazole datasets

% All my phonon data exists in here. If yours is nice and tidy, change the
% string here. If it's in multiple directories, you'll need to update the
% dirs variable at the bottom of this file.
RootDir = '~/Data/phd/Phonon/';

% Get some hardcoded values
[dirs, roots, titles, savedir, savenames] = N_GetNameCells();

%% Load and process, fit and plot
% Preallocate cells for frequency data, fits, and confidence intervals 
ProcessedData.Freq = cell(size(dirs, 2),1);
ProcessedData.Andor = cell(size(dirs, 2),1);
% Set current figure, create and get an axis, then use show_hist to load
% data, fit and plot
for set = 1:size(dirs,2)
    disp(titles{set})
    [ProcessedData.Freq{set}, ProcessedData.Andor{set}] = HistBatchPreProcess([RootDir dirs{set}], ...
        roots{set}, '4');
end
%%
load('~/Data/phd/Phonon/processed_data/perspective2020_fig_1_data')
%% Draw ROIs
figure(81)
FreqVecs = cell(size(dirs)); % vector for frequency info from inside ROI
Masks = cell(size(dirs));
for set = 1:size(dirs,2)
    disp(titles{set})
    Masks{set} = cell(size(ProcessedData.Freq{set}));
    for scan = 1:size(ProcessedData.Freq{set},1)
        im = imagesc(ProcessedData.Freq{set}{scan},[5.1 5.7]);
        ThisROI = drawpolygon(im.Parent);
        Masks{set}{scan} = ThisROI.createMask;
        FreqVecs{set} = [FreqVecs{set}; ProcessedData.Freq{set}{scan}(ThisROI.createMask)];
    end
end
save('~/Data/phd/Phonon/processed_data/perspective2020_fig_1_data','ProcessedData', 'Masks','FreqVecs')

%% fit 
% For a 2 gaussian mix model (two peaks), use '2GMM'. For 3, use '3GMM'.
% To have some fits with 3 peaks and some with 2, use 'mix'. Start values
% can by changed at the bottom of this file.
[start, lb, ub, opt] = N_GetFitOpts('mix');

f_no = 5;
fits = cell(size(dirs));
confs = cell(size(dirs));

for set = 1:size(dirs,2)
    figure(f_no + set)
    clf
    ax = gca;
    [fits{set}, confs{set}] = PlotAndFitHists(ax, FreqVecs{set}, start{set}, lb{set}, ub{set}, opt, titles{set}, []);
    
end

%% Just fit and plot
save = 1;
for set = 1:size(dirs,2)
    figure(f_no + set)
    %subplot(round(size(dirs,2)/2),2,set);
    ax = gca;
    % Start fitting using the previous fitting values
    disp(titles{set})
    [ProcessedData.Freq{set}, fits{set}, confs{set}] = show_hist(ax, ProcessedData.Freq{set}, ...
        titles{set}, fits{set}, lb{set,:}, ub{set,:}, opt);
    pause(0.05); % Allow the plot to draw
    if save == 1
        title('')
        savename = strcat(savedir,'histfit_',savenames{set},'.png');
        saveas(gcf, savename)
    end 
end
%% Make some pictures
saveDir = '/home/ppxwh2/Documents/onbi-rotation-report/';
fig_names = {'ctrl','noco1','noco01','noco001','noco0001'};
for set = 1%:size(dirs,2)
    figure(f_no + size(dirs,2) + set)
    switch set
        case 1
            im = 3;
            frq = reshape(ProcessedData.Freq{set}((im-1)*61^2 + 1:im * 61^2), 61, 61);
        case 2
            im = 3;
            frq = reshape(ProcessedData.Freq{set}((im-1)*6561 + 1:im*6561), 81, 81);
        case 3
            im = 5;
            frq = reshape(ProcessedData.Freq{set}((im-1)*6561 + 1:im*6561), 81, 81);
        case 4
            im = 5;
            frq = reshape(ProcessedData.Freq{set}((im-1)*6561 + 1:im*6561), 81, 81);
        case 5
            im = 4;
            frq = reshape(ProcessedData.Freq{set}((im-1)*6561 + 1:im*6561), 81, 81);
    end
    Cmin = 5.1;
    Cmax = 6.2;
    imagesc(frq, [Cmin, Cmax])
    axis image off
    colorbar
    title('');%title(titles{set})
    saveas(gcf,strcat(saveDir, fig_names{set},'_',num2str(im),'_sc_frq.png'))
end

function [dirs, roots, titles, savedir, savenames] = N_GetNameCells()
% Each directory to look in, the root for that directory and title for that
% set
dirs  = {'may7th',...Control
    ...'/home/scan/2019/may/ASOPS/15th',...    Cytochalasin D
    'may28th',...    Nocodazole 1ng/ml
    'jun11th',...          Nocodazole 0.1ng/ml
    'jun12th', ...           Nocodazole 0.01ng/ml
    'jun14th'}; %            Nocodazole 0.001ng/ml
roots = {'HeLa_control_day2',...
    ...'hela_cytd',...
    'hela_noco_day2', ...
    'hela_noco01', ...
    'hela_noco001', ...
    'hela_noco0001'};
titles = {'Control', ...
    ...'Cytochalasin D 1\muM', ...
    'Nocodazole 1ng/ml', ...
    'Nocodazole 0.1ng/ml',...
    'Nocodazole 0.01ng/ml', ...
    'Nocodazole 0.001ng/ml'};
savedir = '/home/ppxwh2/Documents/onbi-rotation-report/';
savenames = {'ctrl',...
    ...'cytd1uM',...
    'noco1',...
    'noco01',...
    'noco001',...
    'noco0001'};
end

function [start, lb, ub, opt] = N_GetFitOpts(Model)
% Fitting parameters - each row corresponds to 1 set

switch Model
    case '2GMM'
        % For 2GMM
        
        %        p      mu1     mu2     sig1   sig2
        start ={[0.57   5.13    5.36    0.014  0.1603];
                [0.64   5.2     5.87    0.022  0.3552];
                [0.56   5.18    5.46    0.025  0.1943];
                [0.65   5.2     5.20    0.055  0.0268];
                [0.79   5.2     5.5     0.056  0.2386]};
        lb =    {[0,    5.1,    5.2,    0,     0];
                [0,     5.1,    5.2,    0,     0];
                [0,     5.1,    5.2,    0,     0];
                [0,     5.1,    5.2,    0,     0];
                [0,     5.1,    5.2,    0,     0];};
        ub =    {[1,    5.25,   5.9,    1,     1];
                [1,     5.25,   5.9,    1,     1]
                [1,     5.25,   5.9,    1,     1]
                [1,     5.25,   5.9,    1,     1]
                [1,     5.25,   5.9,    1,     1]};
        opt = statset('MaxIter',3000, 'MaxFunEvals', 10000);
    case '3GMM'
        % For 3GMM
        %        p      q       mu1     mu2    mu3  sig1   sig2     sig3
        start ={[0.75,  1,      5.125,  5.4,   5.8, 0.03,  0.2,     0.2];
            [0.5,   0.5,    5.15,   5.4,   6,   0.05,  0.2,     0.2];
            [0.75,  1,      5.21,   5.52,  5.8, 0.03,  0.1,     0.2];
            [0.5,   1,      5.2,    5.3,   5.8, 0.03,  0.05,    0.2];
            [0.5,   0.75,    5.15,   5.4,   5.8, 0.05,  0.2,     0.2]};
        lb =   {[0.75,  1,      5.1,    5.2,   5.5, 0,     0,       0];  % Control
            [0,     0.1,    5.1,    5.2,   5.95,0,     0,       0];  % 1ng
            [0,     1,      5.2,    5.2,   5.5, 0,     0,       0];  % 0.1ng
            [0,     1,      5.2,    5.28   5.5, 0,     0,       0];  % 0.01ng
            [0,     0.1,    5.1,    5.2,   5.5, 0,     0,       0]}; % 0.001ng
        ub =   {[1,     1,      5.15,   5.5,   5.9, 0.05,  0.5,     0.5];% Control
            [1,     1,      5.2,    5.5,   6.1, 0.05,  0.5,     0.5];% 1ng
            [1,     1,      5.23,   5.6,   5.9, 0.05,  0.5,     0.5];% 0.1ng
            [1,     1,      5.22,   5.35,  5.9, 0.05,  0.1,     0.5];% 0.01ng
            [1,     1,      5.2,    5.5,   5.9, 0.05,  0.5,     0.5]};%0.001ng
        opt = statset('MaxIter',100000, 'MaxFunEvals', 100000);
    case 'mix'
        % For mix of both
        start ={[0.5745 5.1328  5.3585  0.0145  0.1603];
            ...[0.5    5.1     5.4     0.03    0.1];
            [0.6443 0.5607  5.1944  5.5400  6.1376  0.0209  0.1455  0.140];
            [0.5070 0.200   5.1791  5.2594  5.5350  0.0233  0.0560  0.1402];
            [0.3014 5.1913  5.2602  0.0229  0.0487];
            [0.4200 0.7800  5.1450  5.2300  5.5600  0.0200  0.0700  0.1600]};
        lb =   {[0.2    5.1     5.2     0.01    0.15];
            ...[0      5.1     5.2     0.01    0.1];
            [0.1    0.3     5.1     5.3     5.7    0.01    0.1     0.1];
            [0.4    0       5.1     5.25    5.53    0.01    0.05    0.1];
            [0      5.18    5.23    0.01    0.02];
            [0.2    0.5     5.1     5.2     5.4     0.01    0.01    0.07]};
        ub =   {[0.7    5.3     5.7     0.05    0.3];
            ...[1      5.2     6       0.1     0.5];
            [0.9    0.7     5.2     5.7     6.14    0.05    0.4     0.16];
            [0.54   0.3     5.2     5.4     5.6     0.05    0.4     0.145];
            [1      5.23    5.3     0.04    0.1];
            [0.7    1       5.17    5.25    5.7     0.03    0.1     0.6]};
        opt = statset('MaxIter',100000, 'MaxFunEvals', 500000);
end
end
