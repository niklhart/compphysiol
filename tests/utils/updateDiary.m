%UPDATEDIARY Update content of a diary file
%UPDATEDIARY(FH,REFDIARY) repaces the content of diary file REFDIARY in the
%   diaryPath() by the console output of FH(). If REFDIARY does not exist,
%   it will be created without any user interaction. However, if REFDIARY
%   is already defined, both the current and prospective content of
%   REFDIARY are shown and the update must be confirmed by the user.
function updateDiary(fh, refDiary)

    assert(isa(fh,'function_handle') && nargin(fh) == 0, ...
        'First input must be a zero-argument function handle.')
    output = evalc('fh()');

    refFile = diaryPath(refDiary);

    if isfile(refFile)
        fprintf('\nPrevious content of "%s":\n\n',refDiary)
        disp(fileread(refFile))
        fprintf('\nTentative new content of "%s":\n\n',refDiary)
        disp(output)

        prompt = '\nDo you want to update the diary file? Y/N [N]: ';
        txt = input(prompt,'s');
        if isempty(txt)
            txt = 'N';
        end
    else 
        txt = 'Y';
    end

    % only update the diary file if confirmed at the console
    if strcmp(txt,'Y')
        fid = fopen(refFile,'w');
        fprintf(fid, '%s', output);
        fclose(fid);
    end

end