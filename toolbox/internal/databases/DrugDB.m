classdef DrugDB < handle
    %DRUGDB Singleton class to store the drug database

    properties (Constant)
        Instance = initdrugdb();
    end

end