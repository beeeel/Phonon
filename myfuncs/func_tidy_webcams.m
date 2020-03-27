function [fluo_data] = func_tidy_webcams(confile, save_output, varargin)
% [fluo_data] = func_tidy_webcams(confile, save_output, varargin)
% Get a list of all the files and figure out which ones to load
% confile       - filename base for experiment
% save_output   - 1 to save fluo_data as .mat file
% varargin      - cutoff point if there are more fluorescent images than
%   you wish to be loaded into fluo_data. e.g.: There are 100 images but
%   you only want to load 20.

%% Find the files which start with the string in confile
a = dir;
to_load = cell(0);
count = 1;
for idx = 1:length(a)
    name = strsplit(a(idx).name,{'_','.'});
    if length(a(idx).name) > length(confile) % Prevents indexing errors for short names
        if strcmp(a(idx).name(1:length(confile)),confile) && ...
                (strcmp(name{end-2}(1:end-1),'webcam') ||...
                strcmp(name{end-2}(1:end-2),'webcam'))
            % Filenames start with filebase and have webcam near the end
            to_load{count} = a(idx).name;
            count = count + 1;
        end
    end
end
%% Parse the names 
parsed = zeros(length(to_load),2);
for idx = 1:length(to_load)
    name = strsplit(to_load{idx},{'_','.'});
    tmp = 0;
    count = 0;
    % Count from the end of 'webcam##' to determine how many chars are
    % numbers - str2double turnsletters into NaNs.
    % This is overcomplex - but will provide support regardless of d_scan's
    % weird numbering conventions
    while isfinite(tmp)
        tmp = str2double(name{end-2}(end-count));
        if isfinite(tmp)
            count = count + 1;
        end
    end
    % Store the webcam action number and image number
    parsed(idx,:) = [str2double(name{end - 2}(end - count + 1:end)), str2double(name{end-1})];
end
% Count how many times each webcam action comes up - the preliminary
% actions will come up once each, and the actions after the scan come up
% more often
count = zeros(max(parsed(:,1)),1);
for num = 1:max(parsed(:,1))
    count(num) = sum(parsed(:,1) == num);
end
%% Load the data and sort it
% Find the numbers for the preliminary webcam actions
tmp = find(count == 1);

% Load an image to get the resolution, prepare the output struct
imfile = strcat(confile, '_webcam',num2str(tmp(1)),'.0.png');
im = imread(imfile);

% If user supplied a stopping point, use it
if nargin == 3
    n_images = varargin{1};
else
    n_images = max(count);
end

% Create list of field names in cells
fields = cell(0);
values = cell(0);
for origin = 1:5:2.25*sum(count == max(count))
    % For each origin (there are 2 * max(count) images for each origin),
    % we need a field for blue data, a field for green data, and the same
    % for filenames. Each field also needs values.
    str_origin = num2str((origin-1)/5 + 1);
    
    fields{origin} = ['origin' str_origin 'b'];
    values{origin} = zeros([size(im), n_images], 'like', im);
    
    fields{origin + 1} = ['names' str_origin 'b'];
    values{origin + 1} = cell(n_images,1);
    
    fields{origin + 2} = ['origin' str_origin 'g'];
    values{origin + 2} = zeros([size(im), n_images], 'like', im);
    
    fields{origin + 3} = ['names' str_origin 'g'];
    values{origin + 3} = cell(n_images,1);
    
    fields{origin + 4} = ['times' str_origin];
    values{origin + 4} = zeros(n_images,1);
end
% We also need space to store the origin0 data (taken before starting
% scanning)
fields(end+1: end+4) = {'origin0b', 'names0b', 'origin0g', 'names0g'};
values(end+1: end+4) = {zeros([size(im), 2], 'like', im), cell(0), ...
                        zeros([size(im), 2], 'like', im), cell(0)};

% Preallocate struct
fluo_data = cell2struct(values, fields, 2);

% Store the preliminary images, names, and times
fluo_data.origin0b(:,:,1) = im;
fluo_data.names0b{1} = imfile;
meta = dir(imfile);
t_start = meta.datenum;
imfile = strcat(confile, '_webcam',num2str(tmp(2)),'.0.png');
fluo_data.origin0g(:,:,1) = imread(imfile);
fluo_data.names0g{1} = imfile;

% Loop for the number of images found for each channel, loading and storing
% all of one channel, before changing channel and doing it again
chan = {'b','g'};
actions = find(count == max(count));

for origin = 1:2:sum(count == max(count))
    for act = 0:1
        for idx = 1:n_images
            prog = [repmat('=',1,idx) repmat(' ',1,n_images - idx)];
            % Load the images, put them in appropriate places and store times
            imfile = strcat(confile,'_count6_webcam',num2str(actions(origin + act)),...
                '.',num2str(idx-1),'.png');
            im = imread(imfile);
            fluo_data.(['origin' num2str(ceil(origin/2)) chan{act+1}])(:,:,idx) = im;
            fluo_data.(['names' num2str(ceil(origin/2)) chan{act+1}]){idx} = imfile;
            if act == 0
                meta = dir(imfile);
                fluo_data.(['times' num2str(ceil(origin/2))])(idx) = meta.datenum - t_start;
            end
        end
    end
end
% Save them
if save_output
    savename = strcat(confile,'_webcampics.mat');
    save(savename, 'fluo_data');
end
end