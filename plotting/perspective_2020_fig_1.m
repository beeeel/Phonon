%% Figure 1 histogram data from tubulin disrupted cells
%   Bounds and start points for fitting are in the local function
%   "N_GetFitOpts". 
%   Options for the histogram (number of bins, for example) are stored in
%   local function "N_PlotAndFitHists"
clear
close all
% Load data
[ProcessedData,Masks,FreqVecs] = N_LoadData('');
titles = {'Control', ...
    'Nocodazole 1ng/ml', ...
    'Nocodazole 0.1ng/ml',...
    'Nocodazole 0.01ng/ml', ...
    'Nocodazole 0.001ng/ml'};
%% View the ROIs I've defined
%N_ShowROIs(ProcessedData, Masks, titles);
%% You may wish to change to ROIs I've defined
% figure(81)
% [FreqVecs, Masks] = N_DrawNewROIs(ProcessedData, titles);
%% Do the fit and display it

% Set whether to fit to 2 gaussians ('2GMM'), 3 gaussians ('3GMM'), or
% different models for different sets ('mix'). 
% You can change the bounds and start points within the function
[start, lb, ub, opt] = N_GetFitOpts('mix');

fits = cell(size(titles));
confs = cell(size(titles));
clc
for set = 1:size(titles,2)
    figure(set)
    clf
    ax = gca;
    fprintf('\n%s\n',titles{set})
    [fits{set}, confs{set}] = N_PlotAndFitHists(ax, FreqVecs{set}, start{set}, lb{set}, ub{set}, opt, titles{set}, []);
    
end

%% Local functions definitions
function [ProcessedData,Masks,FreqVecs] = N_LoadData(FernandoDir)
%% Load the data I saved for you


[~, HName] = system('hostname');
HName = strsplit(HName);
if strcmp(HName{1}, 'will-linux')
    Dir = '~/Data/phd/Phonon/processed_data/';
elseif isempty(FernandoDir)
    % I assume you've downloaded it to default location, but you might want
    % to change this
    Dir = '~/Downloads/';
else
    Dir = FernandoDir;
end
load([Dir 'perspective2020_fig_1_data.mat'],'ProcessedData','Masks','FreqVecs')
end

function [start, lb, ub, opt] = N_GetFitOpts(Model)
%% Fitting parameters - each row corresponds to 1 set

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
        %        p      q       mu1     mu2    mu3   sig1   sig2     sig3
        start ={[0.75,  0.5,    5.125,  5.2,   5.4,  0.03,  0.2,     0.2];
                [0.6443 0.5607  5.1944  5.540  5.9   0.020  0.1455   0.140];
                [0.5070 0.95    5.1791  5.59   6     0.023  0.160    0.1402];
                ...
                [0.25   1,      5.19    5.3,   5.8,  0.03,  0.05,    0.2];
                [0.4200 0.7800  5.1450  5.230  5.56  0.0200 0.0700   0.1600]};
        lb =   {[0,     0,      5.1,    5.15,  5.3,  0,     0,       0];  % Control
                [0.1    0.3     5.1     5.25   5.7   0.02   0.01     0.1];
                [0      0.94    5.1     5.3    5.7   0.01   0.1      0.1];
                ...
                [0,     0,      5.1,    5.1    5.1,  0,     0,       0];  % 0.01ng
                [0      0       5.1     5.2    5.4   0.01   0.01     0.07]};
        ub =   {[1,     1,      5.15,   5.5,   6.2,  0.05,  0.5,     0.5];% Control
                [1      1       5.25    5.7    6     0.15   0.4      0.4];
                [1      1       5.25    5.75   6.2   0.05   0.4      0.45];
                ...
                [1,     1,      5.3     5.5    5.9,  0.05,  0.1,     0.5];% 0.01ng
                [1      1       5.17    5.4    6     0.03   0.1      0.6]};
        opt = statset('MaxIter',100000, 'MaxFunEvals', 100000);
    case 'mix'
        % For mix of both
        start ={[0.5745 5.1328  5.385  0.0145  0.103];
                [0.6443 0.5607  5.1944  5.540  5.9   0.020  0.1455   0.140];
                [0.5070 0.95    5.1791  5.59   6     0.023  0.160    0.1402];
                [0.3014 5.1913  5.2602  0.0229  0.0487];
                [0.4200 0.7800  5.1450  5.2300  5.5600  0.0200  0.0700  0.1600]};
        lb =   {[0.2    5.1     5.36    0.01    0.01];
                [0.1    0.3     5.1     5.25   5.7   0.02   0.01     0.1];
                [0      0.94    5.1     5.35   5.9   0.01    0.1    0.1];
                [0      5.18    5.23    0.01    0.02];
                [0.1    0.1     5.1     5.2     5.4     0.01    0.01    0.07]};
        ub =   {[0.7    5.3     5.7     0.05    0.11];
                [1      1       5.25    5.7    6     0.15   0.4      0.4];
                [1      1       5.25    5.75   6.2   0.05    0.4     0.45];
                [1      5.23    5.3     0.04    0.1];
                [0.7    1       5.17    5.4     6       0.03    0.1     0.6]};
        opt = statset('MaxIter',100000, 'MaxFunEvals', 500000);
end
end

function N_ShowROIs(ProcessedData, Masks, titles)
%% Draw each cell's frequency data with ROI overlaid on a new figure
for set = 1:size(titles,2)
    for scan = 1:size(ProcessedData.Freq{set},1)
        figure
        imshowpair(ProcessedData.Freq{set}{scan},Masks{set}{scan})
        title([titles{set} ' ' num2str(scan)])
    end
end
end

function [FreqVecs, Masks] = N_DrawNewROIs(ProcessedData, titles)
%% Define your own ROIs using MATLAB's ROI creation tool
% Preallocate cells for frequency data and mask data
FreqVecs = cell(size(titles)); 
Masks = cell(size(titles));
% For each set, go through all the datasets asking user to draw ROI. Save a
% mask from that ROI and extract the frequency data into a vector of all
% frequency data for that set.
for set = 1:size(titles,2)
    disp(titles{set})
    Masks{set} = cell(size(ProcessedData.Freq{set}));
    for scan = 1:size(ProcessedData.Freq{set},1)
        im = imagesc(ProcessedData.Freq{set}{scan},[5.1 5.7]);
        ThisROI = drawpolygon(im.Parent);
        Masks{set}{scan} = ThisROI.createMask;
        FreqVecs{set} = [FreqVecs{set}; ProcessedData.Freq{set}{scan}(ThisROI.createMask)];
    end
end
end

function [fit, conf] = N_PlotAndFitHists(ax, allFreq, fitStartVal, fitLb, fitUb, fitOpts, figTitle, fit)
%% This does what it says: Fits data to histograms and plots result
% Parameters
Nbins = 60; % Number of bins for data
Npoints = 200; % Number of points to calculate pdf at
LineW = 2; % Width of lines on plots
interpreter = 'Tex'; % For titles - either Tex or None

pdf = GetModel(fitStartVal);
if isempty(fit)
    [fit, conf] = FitModel(allFreq, pdf, fitStartVal, fitLb, fitUb, fitOpts);
end
DrawHists(ax, allFreq, Npoints, Nbins, fitStartVal, pdf, fit, LineW, interpreter, figTitle);

    function pdf = GetModel(start)
        % Define 3 models
        switch size(start,2)
            case 5
                % 2GMM (water, and cell)
                pdf = @(x,p,mu1,mu2,sigma1,sigma2) ...
                    p*normpdf(x,mu1,sigma1) + (1-p)*normpdf(x,mu2,sigma2);
            case 2
                % Simple Gaussian (water)
                pdf = @(x, mu, sigma) normpdf(x, mu, sigma);
            case 8
                % 3GMM (water, cytoplasm, and nucleus)
                pdf = @(x, p, q, mu1, mu2, mu3, sig1, sig2, sig3) ...
                    p * normpdf(x, mu1, sig1) + ...
                    (1-p) * ( q * normpdf(x, mu2, sig2) + ...
                    (1-q) * normpdf(x, mu3, sig3));
            otherwise
                warning('Model is chosen from length of start parameter')
                warning('A length of 2 is simple Gaussian, length of 5 is 2GMM, and length of 8 is 3GMM')
                error('Model not recognised')
        end
    end

    function [fit, conf] = FitModel(allFreq, pdf, start, lb, ub, options)
        
        % Fit the model using maximum liklehood estimation
        [fit, conf] = mle(allFreq, 'pdf', pdf, 'start', start, ...
            'lower', lb, 'upper', ub, 'options', options);
    end

    function DrawHists(ax, allFreq, Npoints, Nbins, start, pdf, fit, LineW, interpreter, figTitle)
        
        % Calculate data to plot
        xgrid = linspace(0.95 * min(allFreq), 1.05 * max(allFreq), Npoints);
        cellgrid2 = []; % Initialise an empty matrix to prevent undefined variable being returned
        switch size(start,2)
            case 5
                pdfgrid = pdf(xgrid, fit(1), fit(2), fit(3), fit(4), fit(5));
                watergrid = fit(1) * normpdf(xgrid, fit(2), fit(4));
                cellgrid = (1 - fit(1)) * normpdf(xgrid, fit(3), fit(5));
                fprintf('p %d,\n f(1) %d,\t f(2) %d,\n sig(1) %d,\t sig(2) %d\n',fit)
            case 8
                pdfgrid = pdf(xgrid, fit(1), fit(2), fit(3), ...
                    fit(4), fit(5), fit(6), fit(7), fit(8));
                watergrid = fit(1) * normpdf(xgrid, fit(3), fit(6));
                cellgrid = (1 - fit(1)) * fit(2) * normpdf(xgrid, fit(4), fit(7));
                cellgrid2 = (1 - fit(1)) * (1 - fit(2)) * normpdf(xgrid, fit(5), fit(8));
                fprintf('p %d, q %d,\n f(1) %d,\t f(2) %d,\t f(3) %d,\n sig(1) %d,\t sig(2) %d,\t sig(3) %d\n',fit)
            case 2
                pdfgrid = pdf(xgrid, fit(1), fit(2));
                watergrid = fit(1) * normpdf(xgrid, fit(1), fit(2));
                fprintf('f(1) %d,\n sig(1) %d\n',fit)
        end
        
        % Draw a bar chart
        [N, E] = histcounts(allFreq, Nbins);
        h = bar(ax, E(1:end-1), N./max(N), 'histc');
        h.FaceColor = [.8 .8 .8];
        h.EdgeColor = [.3 .3 .3];
        
        % Plot the other data
        hold on
        plot(ax, xgrid,pdfgrid./max(pdfgrid),'-', 'LineWidth', LineW)           % Fitted PDF
        plot(ax, xgrid, watergrid./max(pdfgrid), 'r--', 'LineWidth', LineW)     % Water peak
        if size(start,2) > 2
            plot(ax, xgrid, cellgrid./max(pdfgrid), 'b--', 'LineWidth', LineW)  % Cytoplasm peak
        end
        if size(start,2) > 5
            plot(ax, xgrid, cellgrid2./max(pdfgrid), 'g--', 'LineWidth', LineW) % Nucleus peak (probably)
        end
        hold off
        xlabel(ax, 'Brillouin frequency (GHz)')
        ylabel(ax, 'Normalised')
        title(ax, figTitle,'Interpreter',interpreter)
    end

end