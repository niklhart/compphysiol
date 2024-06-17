% test plotting functions

% we first define a simulation result which we want to plot in different
% ways (stratified, grouped, etc.)

indv = Individual('Virtual');
indv.model = test_model();
indv.sampling = Sampling([0 1 2]*u.h, Observable('MultiPK', ...
    {'A','B','A','B'},{'pla','pla','tis','tis'}));

initialize(indv);
simulate(indv);

%% Single plot, ungrouped

h = figure('Visible','off');
longitudinalplot(indv,'tunit','h','yunit','');

li = findobj(h, 'Type', 'Line');

% expected content of plot: the Record object (as double). We have to check
% which units are used for plotting.
xobs = indv.observation.record.Time / u.h;
yobs = indv.observation.record.Value;

xplot = li.XData';
yplot = li.YData';

assert(isequal(xobs,xplot) && isequal(yobs,yplot), ...
    'Unexpected x/y values plotted.')

% here, the plot is empty, although indv.observation is populated.
% Apparently, only indv.sampling and the 'obs' argument to longitudinalplot
% are checked, hence this third possibility is missing.

%% Multiple plots, ungrouped

h = figure('Visible','off');
longitudinalplot(indv,'tunit','h','yunit','','subplot_by','Site');

% plot is expected to have 2 subplots
ax = findobj(get(h,'Children'), '-depth', 1, 'type', 'axes');
assert(length(ax) == 2)

% check titles of subplots
assert(isequal(ax(1).Title.String, 'Site = tis'))
assert(isequal(ax(2).Title.String, 'Site = pla'))

% check plot contents. Two subplots are expected to have different subsets
% of values plotted
li1 = findobj(ax(1), 'Type', 'Line');
li2 = findobj(ax(2), 'Type', 'Line');
xplot1 = li1.XData';
yplot1 = li1.YData';
xplot2 = li2.XData';
yplot2 = li2.YData';

site = expand(indv.observation.record.Observable).Site;
xobs1 = indv.observation.record.Time(ismember(site, 'tis'),:) / u.h;
yobs1 = indv.observation.record.Value(ismember(site, 'tis'),:);
xobs2 = indv.observation.record.Time(ismember(site, 'pla'),:) / u.h;
yobs2 = indv.observation.record.Value(ismember(site, 'pla'),:);

assert(isequal(xobs1,xplot1) && isequal(yobs1,yplot1), ...
    'Unexpected x/y values plotted.')
assert(isequal(xobs2,xplot2) && isequal(yobs2,yplot2), ...
    'Unexpected x/y values plotted.')


%% Single plot, grouped

h = figure('Visible','off');
longitudinalplot(indv,'tunit','h','yunit','g/L','group_by','Site');

% plot is expected to have 1 subplot
ax = findobj(get(h,'Children'), '-depth', 1, 'type', 'axes');
assert(length(ax) == 1)

% check plot contents. The plot is expected to have two lines, plotting two
% different subsets of values of the indiv.observation.record.
li = findobj(ax(1), 'Type', 'Line');
xplot1 = li(1).XData';
yplot1 = li(1).YData';
xplot2 = li(2).XData';
yplot2 = li(2).YData';

site = expand(indv.observation.record.Observable).Site;
xobs1 = indv.observation.record.Time(ismember(site, 'tis'),:) / u.h;
yobs1 = indv.observation.record.Value(ismember(site, 'tis'),:);
xobs2 = indv.observation.record.Time(ismember(site, 'pla'),:) / u.h;
yobs2 = indv.observation.record.Value(ismember(site, 'pla'),:);

assert(isequal(xobs1,xplot1) && isequal(yobs1,yplot1), ...
    'Unexpected x/y values plotted.')
assert(isequal(xobs2,xplot2) && isequal(yobs2,yplot2), ...
    'Unexpected x/y values plotted.')



%% Multiple plots, grouped

h = figure('Visible','off');
longitudinalplot(indv,'tunit','h','yunit','g/L', ...
    'subplot_by','Compound','group_by','Site');

% plot is expected to have 2 subplots
ax = findobj(get(h,'Children'), '-depth', 1, 'type', 'axes');
assert(length(ax) == 2)

% check titles of subplots
assert(isequal(ax(1).Title.String, 'Compound = B'))
assert(isequal(ax(2).Title.String, 'Compound = A'))

% check plot contents. Each subplot is expected to have two lines, plotting
% four different subsets of values of the indiv.observation.record.
li1 = findobj(ax(1), 'Type', 'Line');
li2 = findobj(ax(2), 'Type', 'Line');
xplot11 = li1(1).XData';
yplot11 = li1(1).YData';
xplot12 = li1(2).XData';
yplot12 = li1(2).YData';
xplot21 = li2(1).XData';
yplot21 = li2(1).YData';
xplot22 = li2(2).XData';
yplot22 = li2(2).YData';

site = expand(indv.observation.record.Observable).Site;
compound = expand(indv.observation.record.Observable).Compound;
idx22 = ismember(site, 'pla') & ismember(compound, 'A');
idx21 = ismember(site, 'tis') & ismember(compound, 'A');
idx12 = ismember(site, 'pla') & ismember(compound, 'B');
idx11 = ismember(site, 'tis') & ismember(compound, 'B');
xobs11 = indv.observation.record.Time(idx11,:) / u.h;
yobs11 = indv.observation.record.Value(idx11,:);
xobs12 = indv.observation.record.Time(idx12,:) / u.h;
yobs12 = indv.observation.record.Value(idx12,:);
xobs21 = indv.observation.record.Time(idx21,:) / u.h;
yobs21 = indv.observation.record.Value(idx21,:);
xobs22 = indv.observation.record.Time(idx22,:) / u.h;
yobs22 = indv.observation.record.Value(idx22,:);

assert(isequal(xobs11,xplot11) && isequal(yobs11,yplot11), ...
    'Unexpected x/y values plotted.')
assert(isequal(xobs12,xplot12) && isequal(yobs12,yplot12), ...
    'Unexpected x/y values plotted.')
assert(isequal(xobs21,xplot21) && isequal(yobs21,yplot21), ...
    'Unexpected x/y values plotted.')
assert(isequal(xobs22,xplot22) && isequal(yobs22,yplot22), ...
    'Unexpected x/y values plotted.')

%% Max number of subplots

h = figure('Visible','off');
assertError(@() longitudinalplot(indv,'tunit','h','yunit','g/L', ...
    'subplot_by','Subspace','maxSubplots',1))
assertError(@() longitudinalplot(indv,'tunit','h','yunit','g/L', ...
    'subplot_by','Subspace','maxSubplots',2, ...
    'maxSubplotRows',1,'maxSubplotCols',1))

%% Log scales

h = figure('Visible','off');
longitudinalplot(indv,'tunit','h','yunit','g/L', ...
    'xscalelog',true,'yscalelog',true)

ax = findobj(h,'Type','Axes');
assert(isequal(ax.XScale, 'log'))
assert(isequal(ax.YScale, 'log'))
