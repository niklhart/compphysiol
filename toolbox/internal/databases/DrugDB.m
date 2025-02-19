classdef DrugDB < handle
    %DRUGDB Singleton class to store the drug database
    %   An instance of this class is created automatically when drug data
    %   are retrieved for the first time, e.g. via loaddrugdata(). To
    %   customize which database to load from, use 
    % 
    %   setoptcompphysiol('DrugDB',f)
    %
    %   where f is a function handle to initialize the drug database,
    %   defaulting to @initdrugdb.
    %
    %   See also setoptcompphysiol, loaddrugdata, DrugData

    properties (Constant)
        Instance = evalfhopt('DrugDB');
    end

end