%CHECKDEPENDENCIES(FCT) prints a summary of MATLAB toolboxes function FCT 
%   depends on, if any.
function checkDependencies(fct)

    if isa(fct,'function_handle')
        fct = func2str(fct);
    end
    [~, b] = matlab.codetools.requiredFilesAndProducts(fct);
    
    if numel(b) > 1
        tbxstr = strjoin({b(2:end).Name},', ');
        fprintf('Function "%s" depends on: "%s".\n', ...
            fct, tbxstr)
    else
        fprintf('No dependency found.\n')
    end
end