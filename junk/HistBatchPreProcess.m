function [allFreq, allIms] = HistBatchPreProcess(dir, fileBase, exclude)
%% [allFreq, fit, conf] = show_hist(ax, dir, fileBase, exclude)
% Run the standard processing code to load all files in dir that start with
%    base. Run numbers included in the string exclude will be excluded from
%    analysis (only works for single digits)
% Returns the frequency data

% Get all the files in target directory and find the .con files with
% matching base
if exist(dir,'dir') == 7
    cd(dir);
    fileList = strsplit(ls(dir));
else
    error(['Directory ' dir ' could not be found']);
end

nFiles = 0;
for fileName = fileList
    ext = strsplit(fileName{:}, '.');
    % If the start of the file name is the same as base, and the last bit
    % after a '.' is 'con', we want to load it
    if size(fileName{:},2) >= size(fileBase,2)
        if strcmp(fileName{:}(1:size(fileBase,2)), fileBase) && strcmp(ext{end},'con')
            if sum(ext{1}(end) == exclude) == 0
                nFiles = nFiles + 1;
                loadList{nFiles} = ext{1};  %#ok<AGROW>
            end
        end
    end
end

% Load the data with modified standard processing code
datas = cell(nFiles,1);
for fileNo = 1:nFiles
    datas{fileNo} = batch_processing_v_1_6(loadList{fileNo}, '');
end

% Preallocate cell arrays
allFreq = cell(size(datas,1),1);
allIms = cell(size(datas,1),2);
% Populate with frequency and image data
for idx = 1:nFiles
    allFreq(idx) = datas{idx}.freq;
    allIms{idx,1} = datas{idx}.before;
    allIms{idx,2} = datas{idx}.after;
end

end