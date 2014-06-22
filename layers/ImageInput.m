classdef ImageInput < Input
    properties
        file_pattern
        train
        test
        val
        training
        output_size
    end
    methods
        function obj = ImageInput(json)
            obj@Input(FillDefault(json));
            obj.file_pattern = json.file_pattern;
            obj.training = 1;
            obj.Finalize();
        end       
        
        function [X, Y, batches] = LoadData(obj, file_pattern, batch_size)
            try 
                load(sprintf('%s%d', file_pattern, batch_size), 'X', 'Y', 'batches');
                return;
            catch
            end
            if (strcmp(file_pattern(1:4), 'http'))                
                idxs = strfind(file_pattern, '/');
                target = sprintf('data%s', file_pattern(idxs(end - 1):end));
                if ~exist(sprintf('%s.mat', target), 'file')
                    fprintf('Downloading %s.mat to %s.mat\n', file_pattern, target);
                    urlwrite(sprintf('%s.mat', file_pattern), sprintf('%s.mat', target));
                    fprintf('File downloaded successfully.\n');
                end
            else
                target = file_pattern;
            end
            tmp = load(target);
            data = tmp.data;
            obj.output_size = size(data{1}.Y);
            batches = floor(length(data) / batch_size);
            real_input_dim = size(data{1}.X);
            X = cell(batches, 1);
            Y = cell(batches, 1);
            for step = 1:batches
                X_tmp = zeros([batch_size, real_input_dim], class(data{1}.X));
                Y_tmp = zeros([batch_size, obj.output_size], class(data{1}.Y));
                for j = 1:batch_size
                    datapoint = data{(step - 1) * batch_size + j};
                    X_tmp(j, :) = datapoint.X(:);
                    Y_tmp(j, :) = datapoint.Y(:);
                end
                X{step} = single(X_tmp);
                Y{step} = single(Y_tmp);
            end            
            prefix = '';
            save(sprintf('%s%s%d', prefix, target, batch_size), 'X', 'Y', 'batches');            
        end
        
        function [X, Y, step] = GetImage_(obj, step, train)
            X = [];
            Y = [];
            if (train == 2)
                if (isempty(obj.val))
                    [obj.val.X, obj.val.Y, obj.val.batches] = ...
                    obj.LoadData([obj.file_pattern, 'val'], obj.batch_size);
                    obj.val.maxbatches = Inf;
                end
                source = obj.val;            
            elseif (train == 1)
                if (isempty(obj.train))
                    [obj.train.X, obj.train.Y, obj.train.batches] = ...
                    obj.LoadData([obj.file_pattern, 'train'], obj.batch_size);
                    obj.train.maxbatches = Inf;
                end
                source = obj.train;
            elseif (train == 0) 
                if (isempty(obj.test))
                    [obj.test.X, obj.test.Y, obj.test.batches] = ...
                    obj.LoadData([obj.file_pattern, 'test'], obj.batch_size);
                    obj.test.maxbatches = Inf;
                end
                source = obj.test;
            end
            if (step > min(source.batches, source.maxbatches))
                step = -1;
                return;
            end
            X = source.X{step};
            Y = source.Y{step};            
            X = permute(X, [1, 3, 2, 4]);
            step = step + 1;
        end               
    end
end

function json = FillDefault(json)
json.type = 'ImageInput';
end