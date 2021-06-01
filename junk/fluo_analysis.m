%% Analyse fluo live/dead data from C37
% Load it
matName = 'hela_live_imaging1_webcampics';
load([matName '.mat']);

if exist([matName '_segmented.mat'],'file')
    load([matName '_segmented.mat'])
    originList = 2:6;
    nCellsTot = 0;
    for or = 1:length(cellData); nCellsTot = nCellsTot + size(cellData{or},2); end
end

saveData = false;

timeOffset = 1.25; % Time in hours between receiving cells and first fluorescent picture

%    TO DO:
% Display segmented data with cell numbers
% Cell numbers on signal graphs
%% View some data
origin = '5'; % Origin as char pls

chans = {'b', 'g'};
fh = figure(1);

for tIdx = 1:length(fluo_data.(['times' origin]))
    for cIdx = 1:length(chans)
        subplot(length(chans),1,cIdx)
        imagesc(fluo_data.(['origin' origin chans{cIdx}])(:,:,tIdx), [0 255])
        axis image
        title(sprintf('Origin %s, %0.1f hours',origin,fluo_data.(['times' origin])(tIdx)*24))
    end
    pause(0.25)
end
%% Pick cells by drawing rectangles
% Start with the easy ones (no registration)
originList = 2:6;
% Prepare output cell arrays
polyMasks = cell(size(originList));
cellMasks = cell(size(originList));
bgMasks = cell(size(originList));
cellData = cell(size(originList));
% Count the number of cells
nCellsTot = 0;

% Loop over the listed origins
for orIdx = 1:length(originList)
    or = originList(orIdx);
    % Put the first image up (assume images are always the same position)
    fh = figure(2);
    clf
    imagesc(fluo_data.(['origin' num2str(or) 'b'])(:,:,1))
    
    % Prepare an array for the cell data 
    %  (could be more efficient - currently allocates space for doubles,
    %  then stores logical, then overwrites with doubles)
    title('Waiting for input')
    n_cells = input('How many cells? ');
    nCellsTot = nCellsTot + n_cells;
    imSz = size(fluo_data.(['origin' num2str(or) 'b']));
    cellMasks{or} = zeros([imSz n_cells]);
    polyMasks{or} = zeros([imSz(1:2) 1 n_cells]);
    % Draw around the cells
    for N = 1:n_cells
        title(sprintf('Origin %i: Draw cell %i of %i', or, N, n_cells))
        poly = drawpolygon;
        polyMasks{orIdx}(:,:,1,N) = poly.createMask;
    end
    % Draw a background area
    title(sprintf('Origin %i: Draw background', or))
    poly = drawpolygon;
    bgMasks{orIdx} = poly.createMask;
    title('Calculating...')
    drawnow
    % Apply masks
    cellMasks{orIdx} = polyMasks{orIdx} .* double(fluo_data.(['origin' num2str(or) 'b']));
    bgMasks{orIdx} = bgMasks{orIdx} .* double(fluo_data.(['origin' num2str(or) 'b']));
    % Summation - signal:background for [time, cell]
    cellData{orIdx} = squeeze(sum(cellMasks{orIdx}, [1 2]) ./ mean(bgMasks{orIdx}, [1 2]));
%     % Alternative: signal - background for [time, cell]
%     cellData{orIdx} = squeeze(sum(cellMasks{orIdx}, [1 2]) - sum(cellMasks{orIdx} ~= 0, [1 2]) .* mean(bgMasks{orIdx}, [1 2]));
end
if saveData
    save([matName '_segmented.mat'],'cellData') %#ok<UNRCH>
end
title('Done!')
%% Look at the results
% Just plot the data on individual axis
fh = figure(3);
for orIdx = 1:length(originList)
    or = originList(orIdx);
    ax = subplot(length(originList),1,orIdx);
    % Normalize to first time point
    semilogy(24*fluo_data.(['times' num2str(or)]), cellData{orIdx}./cellData{orIdx}(1,:),'--')
    % semilogy(24*fluo_data.(['times' num2str(or)]), cellData{orIdx}./squeeze(sum(cellMasks{orIdx} ~= 0, [1 2])))
    ax.Children(end).LineWidth = 2;
    ax.Children(end).LineStyle = '-';
    title(sprintf('Origin %i',or))
end
% Plot the change in data
figure(4)
for orIdx = 1:length(originList)
    or = originList(orIdx);
    ax = subplot(length(originList),1,orIdx);
%     plot(24*fluo_data.(['times' num2str(or)])(2:end), diff(cellData{orIdx}./squeeze(sum(cellMasks{orIdx} ~= 0, [1 2]))))
%         plot(24*fluo_data.(['times' num2str(or)])(2:end), diff(cellData{orIdx}))
%     semilogy(24*fluo_data.(['times' num2str(or)])(2:end), diff(cellData{orIdx}./cellData{orIdx}(1,:)))    
    % Normalize change to first time point
    plot(24*fluo_data.(['times' num2str(or)])(2:end), diff(cellData{orIdx}./cellData{orIdx}(1,:)))
    ax.Children(end).LineWidth = 2;
    ax.Children(end).LineStyle = '-';
    title(sprintf('Origin %i',or))
end
%% death time histogram
% Determine cell death as when live signal drops by more than x percent or
% original
deltaThresh = 0.05;
deathTimes = zeros(nCellsTot,1);
cellN = 1;

for orIdx = 1:length(originList)
    or = originList(orIdx);
    for cellIdx = 1:size(cellData{orIdx},2)
%         meanDiff = mean(diff(cellData{1}(:,cellIdx)./cellData{orIdx}(1,cellIdx)));
        diffs = diff(cellData{orIdx}(:,cellIdx)./cellData{orIdx}(1,cellIdx));
        greatestDrop = min(diffs);
        if abs(greatestDrop) > deltaThresh
            dropIdx = find(diffs == greatestDrop, 1, 'first');
            deathTimes(cellN) = 24*fluo_data.(['times' num2str(or)])(dropIdx);
        else
            deathTimes(cellN) = 24*fluo_data.(['times' num2str(or)])(end)+1.4;
        end
        cellN = cellN + 1;
    end
end
deathTimes = deathTimes + timeOffset;

figure(5)
% histogram(deathTimes, 'NumBins', 10)
histogram(deathTimes, 'BinEdges',0.125:0.25:6.5)
xlim([0 6.5])
ylabel('Count')
xlabel('Time (hrs)')
title('Death time distribution')
ax = gca;
ax.XTickLabel{end} = 'Did not die';
ax.XTick(end-1) = 4.6;%fluo_data.times6(end)*24+timeOffset;
ax.XTickLabel{end-1} = 'Scan end';