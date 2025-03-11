% POLISH Improve figure readability 
%   Polishes a figure by increasing line width, font size and marker size
%   in all graphical elements. 
%   
%   [] = POLISH() polishes the currently active figure
%   
%   [] = POLISH(FIGNR) polishes figure FIGNR 
%   
%   [] = POLISH(OPTS) polishes the currently active figure using custom
%        sizes defined by OPTS
%   
%   [] = POLISH(FIGNR,OPTS) polishes figure FIGNR using custom sizes OPTS
%   
%   Input:
%   - FIGNR can be a positive integer or a figure handle.
%   - OPTS is a struct with (some of the) fields 
%       .lw (line width;  default = 2)
%       .ms (marker size; default = 10)
%       .fs (font size;   default = 18)
%   
function [] = polish(varargin)

    narginchk(0,2)
    figNr = [];
    opts = struct;
    
    if nargin == 1
        if isstruct(varargin{1})   % polish(opts)
            opts  = varargin{1};            
        else                       % polish(figNr)
            figNr = varargin{1};
        end        
    elseif nargin == 2             % polish(figNr, opts)
        figNr = varargin{1};
        opts  = varargin{2};
    end
        
    if ~isempty(figNr) 
        if ishandle(figNr)
            h = figNr;
        else
            h = figure(figNr);
        end
    elseif isempty(get(groot,'CurrentFigure'))
        return
    else
        h = gcf;
    end
        
    lw = getfld(opts, 'lw',  2);  % line width
    ms = getfld(opts, 'ms', 10);  % marker size
    fs = getfld(opts, 'fs', 18);  % font size
    
    li = findobj(h, 'Type', 'Line');
    set(li,'LineWidth',lw);
    set(li,'MarkerSize',ms);

    eb = findobj(h, 'Type', 'ErrorBar');
    set(eb,'LineWidth',lw);

    tx = findall(h,'Type','Text');
    set(tx,'FontSize',fs);
    
    isplotgrid = all(isa(h.Children,'matlab.graphics.layout.TiledChartLayout'));
    if isplotgrid
        ttl =  h.Children.Title;
        labs = [h.Children.XLabel h.Children.YLabel];

        set(ttl,'FontSize',fs+1);
        set(labs,'FontSize',fs);
        set(ttl,'FontWeight','bold');
    end
    
    ax = findobj(h, 'Type', 'Axes');
    set(ax,'FontSize',fs);
    set(ax,'LineWidth',lw);
    
    for i = 1:numel(ax)
        ttl_i = get(ax(i),'title');
        set(ttl_i,'Fontsize',fs);
        if isplotgrid
            set(ttl_i,'FontWeight','normal')
        end
    end
    
    leg = findobj(h,'Type','Legend');
    if ~isempty(leg)
        set(leg,'Fontsize',fs); 
    end
end

function val = getfld(opt, field, default)
    assert(isstruct(opt))
    
    if isfield(opt,field) && ~isempty(opt.(field))
        val = opt.(field);
    else
        val = default;
    end

end
