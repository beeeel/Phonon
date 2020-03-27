function [allFreq, fit, conf] = show_hist(ax, dir, base, start, lb, ub, options, exclude)
%% [allFreq, fit, conf] = show_hist(ax, dir, base, start, lb, ub, options, exclude)
% Run the standard processing code to load all files in dir that start with
%    base, fit a model using conditions specified in start, lb, ub and options,
%    and plot it to the axis specified in ax. Run numbers included in the
%    string exclude will be excluded from analysis (only works for single
%    digits)
% Returns the frequency data, fit numbers and confidence interval.
% Alternative use:
%% [allFreq, fit, conf] = show_hist(ax, allFreq, title, start, lb, ub, options, exclude)
% Take preloaded data and fit it to model using specified conditions and
%    plot it to specified axis. Third argument must be 0 for this.
%
% Model to fit is decided by length of start input:
%   2: Fit a simple Gaussian
%   5: Fit a two Gaussian-mix model (2GMM)
%   8: Fit a three Gaussian-mix model (3GMM)
% Note: Fitting can be quite sensitive to start conditions and bounds. This
% is more true for the 3GMM and datasets which are inbalanced.

% Parameters
Nbins = 60; % Number of bins for data
Npoints = 200; % Number of points to calculate pdf at
LineW = 2; % Width of lines on plots
interpreter = 'Tex'; % For titles - either Tex or None

% Check start
if size(start,2) ~= size(lb, 2) || size(start,2) ~= size(ub, 2)
    fprintf('Size of start: %d \n Size of lb: %d \n Size of ub: %d \n', ...
        size(start,2), size(lb,2), size(ub,2));
    error('Start, upper bound, and lower bound must all be the same size')
end

% If the third input argument is a string (base), process and load the data
if ischar(dir)
    % Get all the files in target directory and find the .con files with
    % matching base
    cd(dir);
    fileList = strsplit(ls(dir));
    nFiles = 0;
    for fileName = fileList
        ext = strsplit(fileName{:}, '.');
        % If the start of the file name is the same as base, and the last bit
        % after a '.' is 'con', we want to load it
        if size(fileName{:},2) >= size(base,2)
            if strcmp(fileName{:}(1:size(base,2)), base) && strcmp(ext{end},'con')
                if sum(ext{1}(end) == exclude) == 0
                    nFiles = nFiles + 1;
                    loadList{nFiles} = ext{1}; %#ok<AGROW>
                end
            end
        end
    end
    
    % Load the data with modified standard processing code
    datas = cell(nFiles,1);
    for fileNo = 1:nFiles
        datas{fileNo} = batch_processing_v_1_6(loadList{fileNo}, '');
    end
    
    % Preallocate zeros array and put all frequency data into it
    allFreq = zeros([size(datas{1}.freq{:}), size(datas,1)]);
    for idx = 1:nFiles
        allFreq(:,:,idx) = datas{idx}.freq{:};
    end
    % Turn the 3D array into a vector and clear the datas from memory (they are
    % big!)
    allFreq = reshape(allFreq,1, []);
    clear datas
% Otherwise the second argument is not a character
elseif isnumeric(dir)
    allFreq = dir;
else
    error('If second input argument is not a string, it must be allFreq vector (type: numeric)');
end

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
% Fit the model using maximum liklehood estimation
[fit, conf] = mle(allFreq, 'pdf', pdf, 'start', start, ...
    'lower', lb, 'upper', ub, 'options', options);

% Calculate data to plot
xgrid = linspace(0.95 * min(allFreq), 1.05 * max(allFreq), Npoints);
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
title(ax, base,'Interpreter',interpreter)

end

