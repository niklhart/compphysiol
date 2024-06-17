function str = table2char(T)
%TABLE2CHAR Convert a table into a character array
%   STR = TABLE2CHAR(T), with a table T, produces a character array STR
%   representing the table, which can be processed further. The output is
%   similar to STR = evalc('disp(T)'), but more compact.
%
%   If T contains User Data "VariableSubtitles", a 1-by-width(T) cell array
%   of cellstr, these are displayed directly below the headers, in
%   parentheses.
%   
%   Example:
%   
%   Time = (0:10)'*u.h;
%   Name = [{'Species'};repmat({'Conc'},10,1)];
%   T = table(Time,Name)
%   table2char(T)
%
%   T.Properties.UserData.VariableSubtitles = {{}, {'Sub1','Sub2'}};
%   table2char(T)


% Idea is from in the following code:
%
% https://stackoverflow.com/questions/30243879/display-cell-array-without-quotes-matlab
%
% G = {};
% for k=1:size(outstr, 2)
%     G{k} = char(strcat(outstr(:,k), {'   '}));
% end
% 
% result = cat(2, G{:});

assert(istable(T))

ncol = width(T);
colnames = T.Properties.VariableNames;

if isfield(T.Properties.UserData,'VariableSubtitles')
    subtitles = T.Properties.UserData.VariableSubtitles;
    if ~isempty(subtitles)
        validateattributes(subtitles,'cell',{'size',size(colnames)})
        subtitles = cellfun(@(x)strjoin(x,','),subtitles,'UniformOutput',false);
        has_sb = ~cellfun(@isempty,subtitles);
        subtitles(has_sb) = strcat('(',subtitles(has_sb),')');
        colnames = vertcat(colnames, subtitles);
    end
end
    
C = cell(1,ncol);
for i = 1:ncol    
    if isnumeric(T.(i)) || islogical(T.(i))
        C{i} = num2str(T.(i));
    else
        C{i} = char(T.(i));
    end
    nhdrchr = max(cellfun(@numel,colnames(:,i)));
    nbdychr = size(C{i},2);
    ndash = max(nhdrchr,nbdychr);

    C{i} = vertcat(colnames(:,i),...
                   {repmat('-',1,ndash)},...
                   cellstr(C{i}));
    C{i} = char(strcat(C{i},{'   '}));

end

str = deblank([C{:}]);

end