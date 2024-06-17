function out = str2u(inStr)
% STR2U  Convert a string representing physical units to DimVar by evaluating
% the input after prepending 'u.' to valid substrings.
% 
%   If the input is a cellstr or string array, STR2U returns an HDV array  
%   of the same size.
% 
%   Compound units are allowed with operators * and - for multiplication and /
%   for division. The characters ² and ³ are also interpreted as ^2 and ^3,
%   respectively. Other operators will be passed to the eval function.
% 
%   Grouping with parentheses for clarity is advisable. Note that
%   str2u('km/h-s') does not return the same result as str2u('km/h*s') because
%   in the former case, the hyphenated h-s is grouped in the denominator.
% 
%   The returned variable will have the unit portion of the input string as its
%   custom display unit.
% 
%   str2u returns a cell array for string array inputs. 
%   
%   Examples: 
%     str2u('kg-m²/s^3') % returns a DimVar with units of watts (u.W).
% 
%     str2u('-5km/s') % or str2u('-5 km / s'); the same as calling -5*u.km/u.s.
%       
%     str2u('1e-5 M') % exponential scientific notation.
% 
%   See also u, eval.

%   Copyright Sky Sartorius 
%   www.mathworks.com/matlabcentral/fileexchange/authors/101715
%
%   Changes (Niklas Hartung): 
%   - For cellstr input, output is now HDV instead of a DimVar cell array

% This first try is a shortcut as well as covers some plain number inputs.
out = str2double(inStr);
if ~isnan(out)
    return 
end

%% Parse inputs.
if isstring(inStr) && ~isscalar(inStr)
    inStr = cellstr(inStr);
end
if iscellstr(inStr)
    
    [number, unitStr] = regexp(inStr,'^[-+.0-9eE]+','match','split');
        
    % distinguish scientific notation 'e' from unit 'e' (elementary charge)
    for i = 1:numel(inStr)
        if endsWith(number{i},{'e'})
            number{i}{1}(end) = [];
            unitStr{i}{end} = ['e' unitStr{i}{end}];
        end
    end

    number(cellfun(@isempty,number)) = {{'1'}};
    number(cellfun(@(x) isempty(x{1}), number)) = {{'1'}};
    number = cellfun(@(x) x{1}, number, 'UniformOutput', false);
    number = str2double(number);

    unitStr = cellfun(@(x) x{end}, unitStr, 'UniformOutput', false);
    unitStr = strtrim(unitStr);

    [uniqueUnitStr, ~, loc] = unique(unitStr);

    uniqueUnits = cellfun(@str2u,uniqueUnitStr,'UniformOutput',false);
    uniqueUnits = [uniqueUnits{:}];
    out = number .* reshape(uniqueUnits(loc),size(number));

    return
end

if isempty(inStr)
    out = [];
    return
end

validateattributes(inStr,{'char' 'string'},{'row'},'str2u');
inStr = strtrim(inStr);

%% First separate out the leading number.
[number, unitStr] = regexp(inStr,'^[-+.0-9eE]+','match','split');

% distinguish scientific notation 'e' from unit 'e' (elementary charge)
if endsWith(number,'e')
    number{1}(end) = [];
    unitStr{end} = ['e' unitStr{end}];
end

if ~isempty(number) && ~isempty(number{1})
    number = number{1};
else
    number = '1';
end
unitStr = strtrim(unitStr{end});
if isempty(unitStr)
    out = eval(number);
    return
end

%% Build the more complex expressions.

normalExpo = '(\^-?[.0-9]+)'; % Numeric exponent.
parenExpo = '(\^\(-?[.0-9]+(/[.0-9]+)?\))'; % Exponent with parens.
validUnitStr = '([A-Za-z]+\w*)'; % Valid field names, essentially.

unitWithExponent = sprintf('(%s(%s|%s)?)',validUnitStr,normalExpo,parenExpo);
hypenated = sprintf('%s(-%s)+',unitWithExponent,unitWithExponent);

%% Regexp and eval.

exp = {
    '²'                 % 1 Squared character.
    '³'                 % 2 Cubed character.
    '(^per |^per-|^/)'  % 3 Leading 'per' special case.
    '( per |-per-)'     % 4 Replace per with /
    hypenated           % 5 Group hyphen units with parens.
    ')('                % 6 Multiply back-2-back parens.
    ']['                % 7 Multiply back-2-back brackets.
    validUnitStr        % 8 Precede alphanumeric unit w/ u.
    '-u\.'              % 9 - leading unit is *.
    };
rep = {
    '^2'                % 1
    '^3'                % 2
    '1/'                % 3
    '/'                 % 4
    '($0)'              % 5
    ')*('               % 6
    ']*['               % 7
    'u.$0'              % 8
    '*u.'               % 9
    };                

evalStr = regexprep(unitStr,exp,rep);
out = eval([number '*' evalStr]);

if isa(out,'DimVar')
    out = scd(out,strtrim(unitStr),'no-check');
end