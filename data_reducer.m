function [data, old_data, axis_info, old_axis_info, filename, old_filename] = data_reducer(data, axis_info, filename, cutoff, varargin)
%% If data has field called scan1, it's a multiscan data struct
if nargin == 5
    axis = varargin{1};
end
if isfield(data,'scan1')
    disp('Data in multiscan format')
    % Copy old data, then for each scan, cut the data arrays at the correct
    % number of x points.
    old_data = data;
    for sc = fieldnames(data)'
        flds = fieldnames(data.(sc{:}));
        sz_ax = axis_info.(sc{:}).axis_pts(axis);
        
        for idx = 1:size(flds)
            fld = flds{idx};
            if iscell(old_data.(sc{:}).(fld))
                if size(old_data.(sc{:}).(fld){1},2) ~= sz_ax
                    data.(sc{:}).(fld) = old_data.(sc{:}).(fld);
                elseif size(old_data.(sc{:}).(fld){1},3) == 1
                    data.(sc{:}).(fld){1} = old_data.(sc{:}).(fld){1}(:,1:cutoff);
                else
                    data.(sc{:}).(fld){1} = old_data.(sc{:}).(fld){1}(:,1:cutoff,:);
                end
            elseif size(old_data.(sc{:}).(fld),2) ~= sz_ax
                data.(sc{:}).(fld) = old_data.(sc{:}).(fld);
            elseif size(old_data.(sc{:}).(fld),3) == 1
                data.(sc{:}).(fld) = old_data.(sc{:}).(fld)(:,1:cutoff);
            else
                data.(sc{:}).(fld) = old_data.(sc{:}).(fld)(:,1:cutoff,:);
            end
        end
        
        old_filename = filename;
        
        filename.(sc{:}).meta.n_traces = ...
            cutoff/sz_ax*old_filename.(sc{:}).meta.n_traces;
        
        axis_info.(sc{:}).no_traces = ...
            cutoff/sz_ax*old_filename.(sc{:}).meta.n_traces;
        
        old_axis_info = axis_info;
        
        axis_info.(sc{:}).axis_pts(axis) = cutoff;
        
        axis_info.(sc{:}).(['axis' num2str(axis)]).stop = ...
            axis_info.(sc{:}).(['axis' num2str(axis)]).um(cutoff);
        
        axis_info.(sc{:}).(['axis' num2str(axis)]).um ...
            = axis_info.(sc{:}).(['axis' num2str(axis)]).um(1:cutoff);
        
        axis_info.(sc{:}).(['axis' num2str(axis)]).pts = cutoff;
    end
else
    disp('Data in standard processing format')
    flds = fieldnames(data);
    old_data = data;
    sz_ax = axis_info.xpts;
    for idx = 1:size(flds)
        fld = flds{idx};
        if iscell(old_data.(fld))
            if size(old_data.(fld){1},2) ~= sz_ax
                data.(fld) = old_data.(fld);
            elseif size(old_data.(fld){1},3) == 1
                data.(fld){1} = old_data.(fld){1}(:,1:cutoff);
            else
                data.(fld){1} = old_data.(fld){1}(:,1:cutoff,:);
            end
        elseif size(old_data.(fld),2) ~= sz_ax
            data.(fld) = old_data.(fld);
        elseif size(old_data.(fld),3) == 1
            data.(fld) = old_data.(fld)(:,1:cutoff);
        else
            data.(fld) = old_data.(fld)(:,1:cutoff,:);
        end
    end
    old_filename = filename;
    filename.meta.n_traces = cutoff/sz_ax*old_filename.meta.n_traces;
    old_axis_info = axis_info;
    axis_info.x = axis_info.x(1:cutoff);
    axis_info.x_um = axis_info.x_um(1:cutoff);
    axis_info.xpts = cutoff;
end
end
