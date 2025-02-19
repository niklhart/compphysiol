%% correct usage

[o1,o2] = uniformize_size(1,[2 3]);
assert(isequal(o1, [1 1]))
assert(isequal(o2, [2 3]))

[o3,o4] = uniformize_size([1,2],[3,4]);
assert(isequal(o3, [1 2]))
assert(isequal(o4, [3 4]))

[o5,o6] = uniformize_size([1,2],3);
assert(isequal(o5,[1 2]))
assert(isequal(o6,[3 3]))

%% Wrong number of inputs

assertError(@() err_wrongInputNumber(1,[2,3]), ...
    'compphysiol:Utils:Uniformize_size:wrongNumberOfInputsOrOutputs')


%% Wrong input dimensions

assertError(@() err_wrongInputDimensions2([1,2,3],[4,5]), ...
    'compphysiol:Utils:Uniformize_size:wrongInputDimensions')

assertError(@() err_wrongInputDimensions2([1,2],[3,4,5,6]), ...
    'compphysiol:Utils:Uniformize_size:wrongInputDimensions')

assertError(@() err_wrongInputDimensions3(1,[2,3],[4,5,6]), ...
    'compphysiol:Utils:Uniformize_size:wrongInputDimensions')

function err_wrongInputDimensions2(varargin)
    [~,~] = uniformize_size(varargin{:});
end

function err_wrongInputDimensions3(varargin)
    [~,~,~] = uniformize_size(varargin{:});
end

function err_wrongInputNumber(varargin)
    [~,~,~] = uniformize_size(varargin{:});
end