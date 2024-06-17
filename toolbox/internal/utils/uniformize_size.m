function varargout = uniformize_size(varargin)
%UNIFORMIZE_SIZE Uniformize size of input arguments
%   [OUT1, OUT2, ...] = UNIFORMIZE_SIZE(IN1, IN2, ...) expands
%   arguments IN1, IN2, ... to consistent size, using function repmat.
%   All input arguments must be either scalar or of a common size, which
%   will be the size of OUT1, OUT2, ...
%
%   Examples:
%
%   [A,B] = uniformize_size(1,[2 3]) % same as A = [1 1]; B = [2 3]
%

assert(nargin == nargout, ...
    'PBPK:Utils:Uniformize_size:wrongNumberOfInputsOrOutputs', ...
    'Number of inputs and outputs must be the same.')
varargout = varargin;

if nargin == 0
    return
end

sizcl = cellfun(@size,varargin,'UniformOutput',false);
sizarr = vertcat(sizcl{:});

usz = unique(sizarr, 'rows');

switch size(usz,1)
    case 1
        return % nothing to do, dimensions agree 
    case 2
        is11 = all(usz' == 1);

        if any(is11)  % either [1 1; * *] or [* *; 1 1]
        
            sz = usz(~is11,:);
            
            for i = 1:nargin
               if any(sizarr(i,:) ~= sz)
                   varargout{i} = repmat(varargin{i}, sz);
               end            
            end

            return
        end
        
    otherwise
        % pass to error
end

   error('PBPK:Utils:Uniformize_size:wrongInputDimensions', ...
       'All input arguments must either be scalar or have a common size.')
end

