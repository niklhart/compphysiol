% test DimVar/plot()

% data for plotting
xu = [2 3 4]*u.m;
xd = double(xu);

yu = [3 2 1]*1e6*u.kg;
yd = double(yu);

%% Simple plot with unit

h = figure('Visible','off');
li = plot(xu,yu);

xp = li.XData;
yp = li.YData;

[ux,uy] = getAxesUnits(li.Parent);

assert(isequal(xu, xp*str2u(ux)))
assert(isequal(yu, yp*str2u(uy)))

close(h)

%% Several lines at once

h = figure('Visible','off');
li = plot(xu,yu,2*xu,2*yu);

xpc = {li.XData};
ypc = {li.YData};

[ux,uy] = getAxesUnits(li(1).Parent);

assert(isequal(xu, xpc{1}*str2u(ux)))
assert(isequal(yu, ypc{1}*str2u(uy)))
assert(isequal(2*xu, xpc{2}*str2u(ux)))
assert(isequal(2*yu, ypc{2}*str2u(uy)))

close(h)

%% Overwriting a plot

h = figure('Visible','off');
plot(xu,yu);
li = plot(yu,xu);  % order and units switched

xp = li.XData;
yp = li.YData;

[ux,uy] = getAxesUnits(li.Parent);

assert(numel(li) == 1)
assert(isequal(yu, xp*str2u(ux)))
assert(isequal(xu, yp*str2u(uy)))

close(h)

%% Adding a consistent object to a plot 

h = figure('Visible','off');
li1 = plot(xu,yu);
hold on
li2 = plot(2*xu,2*yu);

li = [li1; li2];
xpc = {li.XData};
ypc = {li.YData};

[ux,uy] = getAxesUnits(li(1).Parent);

assert(isequal(xu, xpc{1}*str2u(ux)))
assert(isequal(yu, ypc{1}*str2u(uy)))
assert(isequal(2*xu, xpc{2}*str2u(ux)))
assert(isequal(2*yu, ypc{2}*str2u(uy)))

close(h)

%% Adding DimVar to double axes

h = figure('Visible','off');
li = plot(xd,yd);
hold on
f = @() plot(xu,yu);

assertError(f)

xp = li.XData;
yp = li.YData;

assert(isequal(xd, xp))
assert(isequal(yd, yp))

close(h)

%% Adding inconsistent DimVar to DimVar axes

h = figure('Visible','off');
li = plot(xu,yu);
hold on
f = @() plot(yu,xu);

assertError(f)

xp = li.XData;
yp = li.YData;

[ux,uy] = getAxesUnits(li.Parent);

assert(isequal(xu, xp*str2u(ux)))
assert(isequal(yu, yp*str2u(uy)))

close(h)

%% Adding double to DimVar axes - FAILS

% I didn't manage to create a warning when plotting double into DimVar
% plots. This test is a reminder that there's still an open issue there.

h = figure('Visible','off');
plot(xu,yu);
hold on
f = @() plot(xd,yd);
assertWarning(f)

close(h)
