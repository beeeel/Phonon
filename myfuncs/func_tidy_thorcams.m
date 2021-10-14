function [fluo_data] = func_tidy_thorcams(confile, save_output, varargin)
% [fluo_data] = func_tidy_thorcams(confile, save_output, varargin)
% confile       - filename base for experiment
% save_output   - 1 to save fluo_data as .mat file
% varargin      - cutoff point if there are more fluorescent images than
%   you wish to be loaded into fluo_data. e.g.: There are 100 images but
%   you only want to load the first 20.

%% Get a list of the right files
% Get all the files here which have the right name
[~, to_load] = system(['find . -name "' confile '*.png"']);
to_load = strsplit(to_load, '\n');
if isempty(to_load{1})
    error(['No png files starting with ' confile ' found here'])
end
to_load = to_load(1:end-1);

% Parse the names 
parsed = cell(length(to_load),4);
for idx = 1:length(to_load)
    name = strsplit(to_load{idx},{'_','./','.'});
    meta = dir(to_load{idx});
    % End of the filename is the extension, before that is number, before
    % that is origin number
    parsed(idx,:) = {str2double(name{end - 2}), name{end-1}, 1+strcmp(name{end-3},'green'), meta.datenum};
end
% Count how many times each webcam action comes up
nums = 1:max([parsed{:,1}]);
count = sum([parsed{:,1}]' == nums)/2; % Might cause problems if one image is missing, e.g.: one blue or one green
% Get the first time point
t_start = min([parsed{:,4}]);

% Load the data and sort it
% Load first image to get the resolution, then prepare the output struct
im = imread(to_load{1});

% If user supplied a stopping point, use it
if nargin == 3 
    if isnumeric(varargin{1}) && varargin{1} < max(count)
        n_images = min(count, repmat(varargin{1},1,size(count,2)));
    end
else
    n_images = count;
end

% Create list of field names in cells
fields = cell(0);
values = cell(0);
for origin = 1:size(count,2)
    % For each origin, we need a field for blue data, a field for green
    % data, and the same for filenames. Each field also needs values.
    str_origin = num2str(origin);
    
    fields{origin*5-4} = ['origin' str_origin 'b'];
    values{origin*5-4} = zeros([size(im), n_images(origin)], 'like', im);
    
    fields{origin*5-3} = ['names' str_origin 'b'];
    values{origin*5-3} = cell(n_images(origin),1);
    
    fields{origin*5-2} = ['origin' str_origin 'g'];
    values{origin*5-2} = zeros([size(im), n_images(origin)], 'like', im);
    
    fields{origin*5-1} = ['names' str_origin 'g'];
    values{origin*5-1} = cell(n_images(origin),1);
    
    fields{origin*5} = ['times' str_origin];
    values{origin*5} = zeros(n_images(origin),1);
end

fields{end+1} = 'startTime';
values{end+1} = datevec(t_start);
% Preallocate struct
fluo_data = cell2struct(values, fields, 2);

% Loop over all images, putting them in an appropriate place
chan = {'b','g'};
for idx = 1:length(to_load)
    if str2double(parsed{idx,2}) <= n_images(parsed{idx,1})
        im = imread(to_load{idx});
        tmp = ['origin' num2str(parsed{idx,1}) chan{parsed{idx,3}}];
        fluo_data.(tmp)(:,:,str2double(parsed{idx,2})+1) = im;
        tmp = ['names' num2str(parsed{idx,1}) chan{parsed{idx,3}}];
        fluo_data.(tmp){str2double(parsed{idx,2})+1} = to_load{idx};
        if parsed{idx,3} == 1
            tmp = ['times' num2str(parsed{idx,1})];
            fluo_data.(tmp)(str2double(parsed{idx,2})+1) = parsed{idx,4} - t_start;
        end
    end
end

% Save them
if save_output
    savename = strcat(confile,'_thorcampics.mat');
    save(savename, 'fluo_data');
end
end