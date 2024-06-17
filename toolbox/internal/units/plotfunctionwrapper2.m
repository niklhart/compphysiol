function varargout = plotfunctionwrapper2(plotFunction,varargin)
% plotfunctionwrapper2(plotFunction,varargin)  Converts all inputs in varargin
% using displayingvalue and passes to plotFunction using feval. If plotFunction
% is a plotting function (i.e., not something like histcounts or contourc),
% plotfunctionwrapper will also add appropriate unit labels to the axes returned
% by gca.
% 
%   See also displayingvalue, feval, 
%     AddSecondAxis - http://www.mathworks.com/matlabcentral/fileexchange/38852,
%     addaxis_unit  - http://www.mathworks.com/matlabcentral/fileexchange/26928.

% by Niklas Hartung (2022)

%% Retrieve axes units, if plot is non-empty
args = varargin;

arg1ax = (isscalar(args{1}) && isgraphics(args{1},'axes')) ...
        || isa(args{1},'matlab.graphics.axis.AbstractAxes') ...
        || isa(args{1},'matlab.ui.control.UIAxes');
if arg1ax
    ax = args{1};
else
    ax = gca;
end

% If adding to an existing plot, keep axes properties and check unit
% compatibility. Otherwise, no unit checking and axes are reset.
isHold = ishold(ax);
addToExistingPlot = ~isempty(get(ax,'Children')) && isHold;

if addToExistingPlot
    % guess units from axes tick labels
    oldunitstr = {
        ax.XRuler.SecondaryLabel.String
        ax.YRuler.SecondaryLabel.String
    };
    for i = 1:2
        if startsWith(oldunitstr{i},'\times')
            oldunitstr{i} = extractAfter(oldunitstr{i},' ');
        end
        if isempty(oldunitstr{i})
            oldunitstr{i} = 'double';
        end
    end

end

%% Check DimVar input arguments for consistency and uniformize them.

args2 = parseplotparams(args);
plottableArgInd = cellfun(@isplottable,args2);
plottableArgs = args2(plottableArgInd);
switch char(plotFunction)
    case {'plot','fill','loglog','semilogx','semilogy'}
        assert(iscompatible(plottableArgs{1:2:end}) && ...
                iscompatible(plottableArgs{2:2:end}), ...
                'Incompatible units of input arguments.')
        for i = 1:2
            if addToExistingPlot
                typecheck(plottableArgs{i},oldunitstr{i})
                if isa(plottableArgs{i},'DimVar')
                    plottableArgs(i:2:end) = cellfun(@(arg) scd(arg,oldunitstr{i}), plottableArgs(i:2:end), 'UniformOutput', false);
                end
            elseif isa(plottableArgs{i},'DimVar')
                [~,~,unitstr] = displayparser(plottableArgs{i});
                plottableArgs(i:2:end) = cellfun(@(arg) scd(arg,unitstr), plottableArgs(i:2:end), 'UniformOutput', false);
            end
            
        end

        args2(plottableArgInd) = plottableArgs;
        args(1:numel(args2)) = args2;
        
    otherwise
        error('Plot function "%s" not implemented yet.',char(plotFunction))
end

%% Execute function.
% Convert all DimVar arguments to regular variables.

cleanedArgs = cellfun(@displayingvalue,args,'UniformOutput',false);

if ~addToExistingPlot

    % add a listener to the axes to detect 
%    ax.UserData = listener(ax,'ChildAdded',@axesUpdateCallback);

    % reset rulers to default
    ax.XRuler = matlab.graphics.axis.decorator.NumericRuler;
    ax.YRuler = matlab.graphics.axis.decorator.NumericRuler;
    ax.ZRuler = matlab.graphics.axis.decorator.NumericRuler;
end

% execute plotting function with temporarily disabled listener
%ax.UserData.Enabled = false;
%hold(ax,'on')
[varargout{1:nargout}] = feval(plotFunction,cleanedArgs{:});%,'UserData','with units');
%if ~isHold
%    hold(ax,'off')
%end
%ax.UserData.Enabled = true;


%% Determine if first input is axes.
if numel(args) && ...
        ((isscalar(args{1}) && isgraphics(args{1},'axes')) ...
        || isa(args{1},'matlab.graphics.axis.AbstractAxes') ...
        || isa(args{1},'matlab.ui.control.UIAxes'))
    
    args = varargin(2:end);
    
else
    args = varargin;
    
end

%% Easy scheme.
[X,Y,Z] = deal([]);
if ischar(args{1}) || isstruct(args{1})
    S = struct(args{:}); % Also works with single input struct.
    % struct input scheme.
    
    if isfield(S,'Vertices') 
        % Order is important. Patch will use XData, etc. instead of Vertices if
        % both are present.
        [X,Y,Z] = deal(S.Vertices);
        if size(S.Vertices,2) < 3
            Z = [];
        end
    end
    
    if isfield(S,'XData')
        X = S.XData;
    end
    if isfield(S,'YData')
        Y = S.YData;
    end
    if isfield(S,'ZData')
        Z = S.ZData;
    end
    
    labelaxes(gca,X,Y,Z)
    return
end

%% Find just the arguments preceding param/value pairs.
args = parseplotparams(args);

%% Get just the plottable arguments.
plottableArgInd = cellfun(@isplottable,args);
plottableArgs = args(plottableArgInd);
nPlottableArgs = nnz(plottableArgInd);

%% Parse out the intent of the plotting; check compatibility if it's easy.
warnFlag = false;    
%TODO: move the warnFlag part to the switch above that does the actual 
%      plotting, and throw an error instead.

switch char(plotFunction)
    case {'hist','histogram'}
        dimVarArgs = varargin(cellfun('isclass',args,'DimVar'));
        if ~iscompatible(dimVarArgs{:})
            % All DimVar inputs should be compatible.
            warnFlag = true;
        end
        labelaxes(gca,plottableArgs{1},[],[]);
        
    case {'histogram2'}
        labelaxes(gca,plottableArgs{1:2},[])
        
    case {'contour','contourf'}
        if nPlottableArgs >= 3
            labelaxes(gca,plottableArgs{1:2},[])
        end
    
    case {'surf','surface','contour3'}
        if nPlottableArgs <= 2
            % surf(z,c,...); surf(z)
            labelaxes(gca,[],[],plottableArgs{1})
            
        else
            % surf(x,y,z); surf(x,y,z,c)
            labelaxes(gca,plottableArgs{1:3})
            
        end
        
    case {'patch'}
        if nPlottableArgs <= 3
            % patch(x,y,c)
            labelaxes(gca,plottableArgs{1:2},[])
            
        else
            % patch(x,y,z,c)
            labelaxes(gca,plottableArgs{1:3})
            
        end
        
    case {'line','text'}
        if nPlottableArgs <= 2
            labelaxes(gca,plottableArgs{1:2},[])
        else
            labelaxes(gca,plottableArgs{1:3})
        end
        
    case {'plot','fill','loglog','semilogx','semilogy'}

        if ~addToExistingPlot
            if nPlottableArgs == 1
                labelaxes(gca,[],plottableArgs{1},[])
            else
                labelaxes(gca,plottableArgs{1:2},[])
            end
        end        
    case {'plot3','fill3'}
        % Check compatibility.
        if      ~iscompatible(plottableArgs{1:3:end}) || ...
                ~iscompatible(plottableArgs{2:3:end}) || ...
                ~iscompatible(plottableArgs{3:3:end})
            warnFlag = true;
        end
        
        labelaxes(gca,plottableArgs{1:3})
        
end

%% Send out warning if units might not match.
if warnFlag
    warning('DimVar:plotunitscompatibility',...
        ['Potentially incompatible units in inputs for ' plotFunction '.'])    
end
end

function labelaxes(ax,X,Y,Z)
if isa(X,'DimVar')
    [~,~,~,~,~,xs] = displayparser(X);
    lab = ax.XRuler.SecondaryLabel;
    pause(0.001)         % give the plot time to update the XRuler property
    if ~isempty(lab.String)
        xs = [lab.String ' ' xs];
    end
    set(lab,'Visible','on','String',xs)
%    ax.XAxis.TickLabelFormat = ['%g ' xs]; % R2015b+
end
if isa(Y,'DimVar')
    [~,~,~,~,~,ys] = displayparser(Y);
    lab = ax.YRuler.SecondaryLabel;
    pause(0.001)         % give the plot time to update the YRuler property
    if ~isempty(lab.String)        
        ys = [lab.String ' ' ys];
    end
    set(lab,'Visible','on','String',ys)
%    ax.YAxis.TickLabelFormat = ['%g ' ys]; % R2015b+
end
if isa(Z,'DimVar')
    [~,~,~,~,~,zs] = displayparser(Z);
    lab = ax.ZRuler.SecondaryLabel;
    pause(0.001)         % give the plot time to update the ZRuler property
    if ~isempty(lab.String)
        zs = [lab.String ' ' zs];
    end
    set(lab,'Visible','on','String',zs)
%    ax.ZAxis.TickLabelFormat = ['%g ' zs]; % R2015b+
end

end

function [args,props] = parseplotparams(args)
% Ignore all arguments from the last char preceded by multiple numerics. See
% also parseparams.
props = {};
for i = numel(args):-1:3
    if ischar(args{i}) && isnumeric(args{i-1}) && isnumeric(args{i-2})
        props = args(i:end);
        args = args(1:i-1);
        break
    end
end
end

function out = isplottable(x)
out = (isnumeric(x) && ~isrgbtriple(x)) || isa(x,'datetime') || ...
    isa(x,'duration') || isa(x,'categorical');
end

function tf = isrgbtriple(x)
    tf = isa(x,'double') && isrow(x) && length(x) == 3 && all(x >= 0 & x <= 1);
end
