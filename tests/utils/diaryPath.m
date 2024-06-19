%DIARYPATH Full path to diary files
%   PATH = DIARYPATH() returns the main folder in which diary files are
%   stored.
%   PATH = DIARYPATH(DIR1,DIR2,...,FILE) returns the absolute path PATH to 
%   file FILE in subfolder(s) DIR1/DIR2/... within the main diary path
%   returned by DIARYPATH().
function path = diaryPath(varargin)
        wd = pathPBPKtoolbox();
        path = fullfile(wd,'..','tests','diary',varargin{:});
end