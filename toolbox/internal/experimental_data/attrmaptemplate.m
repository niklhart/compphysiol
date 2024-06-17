%ATTRMAPTEMPLATE Default mappings of event attributes to data columns 
%   ATTRMAPTEMPLATE is a customizable template to define mappings between
%   event attributes (see below) and columns in a .csv file containing 
%   experimental data. 
%
%   DEFAMAPS = ATTRMAPTEMPLATE() returns a N-by-2 cell array DEFAMAPS.  
%   Every row links an event attribute (1st column) to a data pattern (2nd
%   column). The actual matching against a column name is done in function
%   'locatecolumn'. Patterns can be specified as character array or
%   cellstr.
%
%   See also ImportableData/locatecolumn

function defmaps = attrmaptemplate()

    %  Attribute      Column         
    defmaps = {
        'ID'          {'ID'}
        'Name'        {'Name', 'YTYPE', 'DVID'}
        'Value'       {'Value','DV'}
        'Dose'        {'Dose','AMT','Value'}
        'Time'        {'Time'}
        'Tstart'      {'Tstart','Time'}
    };

end
