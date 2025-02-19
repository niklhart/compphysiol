classdef PhysiologyDB < handle
    %PHYSIOLOGYDB Singleton class to store the physiological database
    %   An instance of this class is created automatically when physiological
    %   data are retrieved for the first time, e.g. via Physiology(). To
    %   customize which database to load from, use 
    % 
    %   setoptcompphysiol('PhysiologyDB',f)
    %
    %   where f is a function handle to initialize the physiology database,
    %   defaulting to @initphysiologydb.
    %
    %   See also setoptcompphysiol, Physiology

    properties (Constant)
        Instance = evalfhopt('PhysiologyDB');
    end

end