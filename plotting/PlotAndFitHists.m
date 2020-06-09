function [fit, conf] = PlotAndFitHists(ax, allFreq, fitStartVal, fitLb, fitUb, fitOpts, figTitle, fit)

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