classdef u < handle
% u  Physical units.
%
%   If the Physical Units Toolbox is on your MATLAB path, there is nothing to
%   initialize, add to your workspace, or pass to functions - simply
%   multiply/divide by u.(unitName) to attach physical units to a variable. For
%   example, to define a speed using a supported unit: carSpeed = 100 * u.kph.
%   Or, define a speed with an unsupported unit as a combination of supported
%   units: snailSpeed = 20 * u.m/u.week.
%
%   Calling u by itself will display all available units in u.
%
%   Variables with physical units attached are of the class DimVar
%   ("dimenensioned variable"). Math operations performed on dimensioned
%   variables will automatically perform dimensional analysis and can create new
%   units or cancel units and return a normal variable.
%
%   When displaying variables with units or using them in plot, etc., the units
%   used for display will be, in order if available and valid: 1) per-variable
%   preferred display units, 2) units listed in displayUnits, 3) a combination
%   of fundamental base units (mass, length, time, temperature, ...). To set (or
%   clear) custom display units for a given variable, see the scd function. To
%   customize the displayUnits list, see displayUnits. For more advanced
%   customization of the base units themselves, see baseUnitSystem.
%
%   Display customization is set by calls to displayUnits and/or baseUnitSystem
%   (either function files or variables in the base workspace). Tailor
%   preferences for a specific project by defining these variables at the top of
%   a script (before any units are called) or placing unique versions of the
%   files in a project's directory. Be sure to clear the class when changing
%   projects or else the old customizations will remain in effect.
%
%   Some MATLAB functions won't accept variables with physical units (DimVars).
%   Most of the time displayingvalue, which returns value in terms of preferred
%   display units, will be the appropriate tool, but there is also double, which
%   returns the value in terms of base units, and u2num.
%
%   Example 1: Shaft power.
%       rotationSpeed = 2500 * u.rpm;
%       torque = 95 * str2u('ft-lbf');  % Use alternate string-based definition.
%       power = rotationSpeed * torque; % Returns variable with units of power.
%       horsePower = power / u.hp;      % Convert/cancel units.
%
%   Example 2: Unit conversion.
%       100 * u.acre/u.ha;  % Convert 100 acres to hectares.
%       u.st/u.kg;          % Return conversion factor for stone to kilos.
% 
%   Example 3: Custom display.
%       fieldSize = 3*u.sqkm
%       % Muliplies and divides remove any per-variable custom display units.
%       % It's nice to display in the units that make sense for that variable.
%       rate = 3.7*u.acre/u.day
%       rate = scd(rate,'sqm/hr')
%       timeNeeded = fieldSize/rate
%       timeNeeded = scd(timeNeeded,'month')
% 
%   See also displayUnits, baseUnitSystem, scd, clear, displayingvalue,
%   DimVar.double, u2num, str2u, symunit,
%     dispdisp - http://www.mathworks.com/matlabcentral/fileexchange/48637.

%   Copyright Sky Sartorius
%   www.mathworks.com/matlabcentral/fileexchange/authors/101715
%   github.com/sky-s/physical-units-for-matlab

properties (Hidden, Constant = true)
    %% User-defined base and display:
    % Establishes base unit system and preferences based on baseUnitSystem and
    % displayUnits.
    
    baseUnitSystem =    evalin('base','baseUnitSystem')
    dispUnits =         evalin('base','displayUnits')     % NH unused.

    coreUnits = buildCoreUnits(u.baseUnitSystem);
end
properties (Constant = true)

    %% Core units:
    baseNames = u.baseUnitSystem(:,1)'

    m           = setcustomdisplay(u.coreUnits.m,'m') % meter
    kg          = setcustomdisplay(u.coreUnits.kg,'kg') % kilogram
    s           = setcustomdisplay(u.coreUnits.s,'s') % second
    A           = setcustomdisplay(u.coreUnits.A,'A') % ampere
    K           = setcustomdisplay(u.coreUnits.K,'K') % kelvin (°C = °K-273.15)
    mol         = setcustomdisplay(u.coreUnits.mol,'mol') % mole
    cd          = setcustomdisplay(u.coreUnits.cd,'cd') % candela
    bit         = setcustomdisplay(u.coreUnits.bit,'bit') % bit
    currency    = setcustomdisplay(u.coreUnits.currency,'currency') % currency

    %% Derived units list:
    % References:
    % http://physics.nist.gov/cuu/Constants/index.html
    % http://www.translatorscafe.com/unit-converter
    % http://en.wikipedia.org
    % http://www.efunda.com/units/index.cfm
    
    %---- length ----

    meter = setcustomdisplay(u.m,'meter') 
    km = setcustomdisplay(1e3*u.m,'km') % kilometer
    kilometer = setcustomdisplay(u.km,'kilometer') 
    dm = setcustomdisplay(1e-1*u.m,'dm') % decimeter
    decimeter = setcustomdisplay(u.dm,'decimeter') 
    cm = setcustomdisplay(1e-2*u.m,'cm') % centimeter
    centimeter = setcustomdisplay(u.cm,'centimeter') 
    mm = setcustomdisplay(1e-3*u.m,'mm') % millimeter
    millimeter = setcustomdisplay(u.mm,'millimeter') 
    um = setcustomdisplay(1e-6*u.m,'um') % micrometer
    micrometer = setcustomdisplay(u.um,'micrometer') 
    micron = setcustomdisplay(u.um,'micron') % micron
    nm = setcustomdisplay(1e-9*u.m,'nm') % nanometer
    nanometer = setcustomdisplay(u.nm,'nanometer') 
    pm = setcustomdisplay(1e-12*u.m,'pm') % picometer
    picometer = setcustomdisplay(u.pm,'picometer') 
    fm = setcustomdisplay(1e-15*u.m,'fm') % femtometer
    femtometer = setcustomdisplay(u.fm,'femtometer') 
    fermi = setcustomdisplay(u.fm,'fermi') % fermi
    Ao = setcustomdisplay(1e-10*u.m,'Ao') % ångström
    ang = setcustomdisplay(u.Ao,'ang') % ångström
    angstrom = setcustomdisplay(u.ang,'angstrom') 
    angstroem = setcustomdisplay(u.ang,'angstroem') 
    a0 = setcustomdisplay(0.52917721067e-10*u.m,'a0') % Bohr radius
    a_0 = setcustomdisplay(u.a0,'a_0') % Bohr radius
    BohrRadius = setcustomdisplay(u.a0,'BohrRadius') 
    lP = setcustomdisplay(1.616229e-35*u.m,'lP') % Planck length
    PlanckLength = setcustomdisplay(u.lP,'PlanckLength') 
    xu = setcustomdisplay(1.0021e-13*u.m,'xu') % x unit
    xUnit = setcustomdisplay(u.xu,'xUnit') 
    xu_Cu = setcustomdisplay(1.00207697e-13*u.m,'xu_Cu') % x unit (copper)
    xUnit_copper = setcustomdisplay(u.xu_Cu,'xUnit_copper') 
    xu_Mo = setcustomdisplay(1.00209952e-13*u.m,'xu_Mo') % x unit (molybdenum)
    xUnit_molybdenum = setcustomdisplay(u.xu_Mo,'xUnit_molybdenum') 
    in = setcustomdisplay(2.54*u.cm,'in') % inch
    inch = setcustomdisplay(u.in,'inch') 
    mil = setcustomdisplay(1e-3*u.in,'mil') % mil
    line = setcustomdisplay(u.in/10,'line') % line
    hand = setcustomdisplay(4*u.in,'hand') % hand
    span = setcustomdisplay(9*u.in,'span') % span
    smoot = setcustomdisplay(67*u.in,'smoot') % smoot
    ft = setcustomdisplay(12*u.in,'ft') % foot
    foot = setcustomdisplay(u.ft,'foot') 
    ft_US = setcustomdisplay(1200/3937*u.m,'ft_US') % US survey foot
    foot_US = setcustomdisplay(u.ft_US,'foot_US') % US survey foot
    kft = setcustomdisplay(1e3*u.ft,'kft') % kilofoot
    kilofoot = setcustomdisplay(u.kft,'kilofoot') 
    FL = setcustomdisplay(100*u.ft,'FL') % flight level
    flightLevel = setcustomdisplay(u.FL,'flightLevel') 
    yd = setcustomdisplay(3*u.ft,'yd') % yard
    yard = setcustomdisplay(u.yd,'yard') 
    ftm = setcustomdisplay(6*u.ft,'ftm') % fathom
    fathom = setcustomdisplay(u.ftm,'fathom') 
    li = setcustomdisplay(0.66*u.ft,'li') % link
    link = setcustomdisplay(u.li,'link') 
    rod = setcustomdisplay(5.5*u.yd,'rod') % rod
    ch = setcustomdisplay(66*u.ft,'ch') % chain
    chain = setcustomdisplay(u.ch,'chain') 
    fur = setcustomdisplay(220*u.yd,'fur') % furlong
    furlong = setcustomdisplay(u.fur,'furlong') 
    mi = setcustomdisplay(5280*u.ft,'mi') % mile
    mile = setcustomdisplay(u.mi,'mile') 
    mi_US = setcustomdisplay(6336/3937*u.km,'mi_US') % US survey mile
    mile_US = setcustomdisplay(u.mi_US,'mile_US') % US survey mile
    nmi = setcustomdisplay(1852*u.m,'nmi') % nautical mile
    NM = setcustomdisplay(u.nmi,'NM') % nautical mile
    inm = setcustomdisplay(u.nmi,'inm') % nautical mile
    nauticalMile = setcustomdisplay(u.nmi,'nauticalMile') 
    nm_UK = setcustomdisplay(6080*u.ft,'nm_UK') % Imperial nautical mile
    nmile = setcustomdisplay(u.nm_UK,'nmile') % Imperial nautical mile
    dataMile = setcustomdisplay(6000*u.ft,'dataMile') 
    au = setcustomdisplay(149597870.7*u.km,'au') % astronomical unit
    astronomicalUnit = setcustomdisplay(u.au,'astronomicalUnit') 
    pc = setcustomdisplay(648000/pi*u.au,'pc') % parsec
    parsec = setcustomdisplay(u.pc,'parsec') 

    %---- reciprocal length ----

    dpt = setcustomdisplay(1/u.m,'dpt') % diopter
    diopter = setcustomdisplay(u.dpt,'diopter') 
    R_inf = setcustomdisplay(1.0973731568508e7/u.m,'R_inf') % Rydberg constant
    RydbergConstant = setcustomdisplay(u.R_inf,'RydbergConstant') 

    %---- area ----

    sqft = setcustomdisplay(u.ft^2,'sqft') % square foot
    square = setcustomdisplay(100*u.sqft,'square') % square
    ha = setcustomdisplay(10000*u.m^2,'ha') % hectare
    hectare = setcustomdisplay(u.ha,'hectare') 
    a = setcustomdisplay(100*u.m^2,'a') % are
    are = setcustomdisplay(u.a,'are') 
    ac = setcustomdisplay(43560*u.sqft,'ac') % acre
    acre = setcustomdisplay(u.ac,'acre') 
    ro = setcustomdisplay(1/4*u.acre,'ro') % rood
    rood = setcustomdisplay(u.ro,'rood') 
    twp = setcustomdisplay(36*u.mi^2,'twp') % township
    township = setcustomdisplay(u.twp,'township') 
    circ_mil = setcustomdisplay(pi/4*u.mil^2,'circ_mil') % circular mil
    circularMil = setcustomdisplay(u.circ_mil,'circularMil') 
    circ_inch = setcustomdisplay(pi/4*u.in^2,'circ_inch') % circular inch
    circularInch = setcustomdisplay(u.circ_inch,'circularInch') 
    b = setcustomdisplay(100*u.fm^2,'b') % barn
    barn = setcustomdisplay(u.b,'barn') 
    sqin = setcustomdisplay(u.in^2,'sqin') % square inch
    squareInch = setcustomdisplay(u.sqin,'squareInch')
    sqmil = setcustomdisplay(u.mil^2,'sqmil') % square mil
    squareMil = setcustomdisplay(u.sqmil,'squareMil')
    sqmi = setcustomdisplay(u.mi^2,'sqmi') % square mile
    squareMile = setcustomdisplay(u.sqmi,'squareMile')
    sqnmi = setcustomdisplay(u.nmi^2,'sqnmi') % square nautical mile
    squareNauticalMile = setcustomdisplay(u.sqnmi,'squareNauticalMile')
    sqm = setcustomdisplay(u.m^2,'sqm') % square meter
    squareMeter = setcustomdisplay(u.sqm,'squareMeter')
    sqkm = setcustomdisplay(u.km^2,'sqkm') % square kilometer
    squareKilometer = setcustomdisplay(u.sqkm,'squareKilometer')
    sqcm = setcustomdisplay(u.cm^2,'sqcm') % square centimeter
    squareCentimeter = setcustomdisplay(u.sqcm,'squareCentimeter')
    sqmm = setcustomdisplay(u.mm^2,'sqmm') % square millimeter
    squareMillimeter = setcustomdisplay(u.sqmm,'squareMillimeter')
    sqdm = setcustomdisplay(u.dm^2,'sqdm') % square decimeter
    squareDecimeter = setcustomdisplay(u.sqdm,'squareDecimeter')

    %---- volume ----

    cc = setcustomdisplay(u.cm^3,'cc') % cubic centimeter
    cubicCentimeter = setcustomdisplay(u.cc,'cubicCentimeter') 
    L = setcustomdisplay(1000*u.cc,'L') % liter
    l = setcustomdisplay(u.L,'l') % liter
    liter = setcustomdisplay(u.L,'liter') 
    dL = setcustomdisplay(100*u.cc,'dL') % deciliter
    dl = setcustomdisplay(u.dL,'dl') % deciliter
    deciliter = setcustomdisplay(u.dl,'deciliter') 
    cL = setcustomdisplay(10*u.cc,'cL') % centiliter
    cl = setcustomdisplay(u.cL,'cl') % centiliter
    centiliter = setcustomdisplay(u.cl,'centiliter') 
    mL = setcustomdisplay(u.cc,'mL') % milliliter
    ml = setcustomdisplay(u.mL,'ml') % milliliter
    milliliter = setcustomdisplay(u.ml,'milliliter') 
    uL = setcustomdisplay(u.mm^3,'uL') % microliter
    ul = setcustomdisplay(u.uL,'ul') % microliter
    microliter = setcustomdisplay(u.ul,'microliter') 
    kL = setcustomdisplay(u.m^3,'kL') % kiloliter
    kl = setcustomdisplay(u.kL,'kl') % kiloliter
    kiloliter = setcustomdisplay(u.kl,'kiloliter') 
    cuin = setcustomdisplay(16.387064*u.mL,'cuin') % cubic inch
    cubicInch = setcustomdisplay(u.cuin,'cubicInch') 
    FBM = setcustomdisplay(u.sqft*u.in,'FBM') % board foot
    boardFoot = setcustomdisplay(u.FBM,'boardFoot') 
    gal = setcustomdisplay(231*u.cuin,'gal') % gallon (US)
    gallon = setcustomdisplay(u.gal,'gallon') 
    gal_UK = setcustomdisplay(4.54609*u.l,'gal_UK') % UK imperial gallon
    igal = setcustomdisplay(u.gal_UK,'igal') % UK imperial gallon
    quart = setcustomdisplay(u.gal/4,'quart') % US quart
    qt_UK = setcustomdisplay(u.gal_UK/4,'qt_UK') % British imperial quart
    liq_qt = setcustomdisplay(u.quart,'liq_qt') % US quart
    pint = setcustomdisplay(u.quart/2,'pint') % US pint
    pint_UK = setcustomdisplay(u.qt_UK/2,'pint_UK') % British imperial pint
    liq_pt = setcustomdisplay(u.pint,'liq_pt') % US pint
    cup = setcustomdisplay(u.pint/2,'cup') % US cup
    floz = setcustomdisplay(u.cup/8,'floz') % US fluid ounce
    fluidOunce = setcustomdisplay(u.floz,'fluidOunce') % US fluid ounce
    floz_UK = setcustomdisplay(u.gal_UK/160,'floz_UK') % British imperial fluid ounce
    Tbls = setcustomdisplay(u.floz/2,'Tbls') % US tablespoon
    tablespoon = setcustomdisplay(u.Tbls,'tablespoon') % US tablespoon
    tsp = setcustomdisplay(u.Tbls/3,'tsp') % US teaspoon
    teaspoon = setcustomdisplay(u.tsp,'teaspoon') % US teaspoon
    acft = setcustomdisplay(u.acre*u.ft,'acft') % acre-foot
    acre_foot = setcustomdisplay(u.acft,'acre_foot') 
    acin = setcustomdisplay(u.acre*u.in,'acin') % acre-inch
    acre_inch = setcustomdisplay(u.acin,'acre_inch') 
    bbl = setcustomdisplay(7056*u.in^3,'bbl') % US customary dry barrel
    barrel = setcustomdisplay(u.bbl,'barrel') 
    fldr = setcustomdisplay(u.floz/8,'fldr') % US customary fluid dram
    fluidDram = setcustomdisplay(u.fldr,'fluidDram') 
    fldr_UK = setcustomdisplay(u.floz_UK/8,'fldr_UK') % British imperial fluid drachm (dram)
    minim = setcustomdisplay(u.fldr/60,'minim') % US customary minim
    minim_UK = setcustomdisplay(u.fldr_UK/60,'minim_UK') % British imperial minim
    gill = setcustomdisplay(4*u.floz,'gill') % US customary fluid gill
    gill_UK = setcustomdisplay(u.gal_UK/32,'gill_UK') % British imperial gill

    %---- acceleration ----

    g0 = setcustomdisplay(9.80665*u.m/u.s^2,'g0') % standard gravity
    g_0 = setcustomdisplay(u.g0,'g_0') % standard gravity
    gn = setcustomdisplay(u.g0,'gn') % standard gravity
    g_n = setcustomdisplay(u.g0,'g_n') % standard gravity
    gee = setcustomdisplay(u.g0,'gee') % standard gravity
    standardGravity = setcustomdisplay(u.g0,'standardGravity') 
    Gal = setcustomdisplay(u.cm/u.s^2,'Gal') % gal

    %---- force ----

    N = setcustomdisplay(u.kg*u.m/u.s^2,'N') % newton
    newton = setcustomdisplay(u.N,'newton') 
    kN = setcustomdisplay(1e3*u.N,'kN') % kilonewton
    kilonewton = setcustomdisplay(u.kN,'kilonewton') 
    MN = setcustomdisplay(1e6*u.N,'MN') % meganewton
    meganewton = setcustomdisplay(u.MN,'meganewton') 
    mN = setcustomdisplay(1e-3*u.N,'mN') % millinewton
    millinewton = setcustomdisplay(u.mN,'millinewton') 
    uN = setcustomdisplay(1e-6*u.N,'uN') % micronewton
    micronewton = setcustomdisplay(u.uN,'micronewton') 
    dyn = setcustomdisplay(1e-5*u.N,'dyn') % dyne
    dyne = setcustomdisplay(u.dyn,'dyne') 
    lbf = setcustomdisplay(4.4482216152605*u.N,'lbf') % pound force
    lb_f = setcustomdisplay(u.lbf,'lb_f') % pound force
    poundForce = setcustomdisplay(u.lbf,'poundForce') 
    kip = setcustomdisplay(1000*u.lbf,'kip') % kip
    kilopoundForce = setcustomdisplay(u.kip,'kilopoundForce') 
    kgf = setcustomdisplay(u.kg*u.g0,'kgf') % kilogram force
    kg_f = setcustomdisplay(u.kgf,'kg_f') % kilogram force
    kilogramForce = setcustomdisplay(u.kgf,'kilogramForce') 
    kp = setcustomdisplay(u.kgf,'kp') % kilopond
    kilopond = setcustomdisplay(u.kp,'kilopond') 
    p = setcustomdisplay(u.kp/1000,'p') % pond
    pond = setcustomdisplay(u.p,'pond') 
    sn = setcustomdisplay(u.kN,'sn') % sthène
    sthene = setcustomdisplay(u.sn,'sthene') 

    %---- mass ----

    kilogram = setcustomdisplay(u.kg,'kilogram') 
    kilo = setcustomdisplay(u.kg,'kilo') % kilogram
    g = setcustomdisplay(1e-3*u.kg,'g') % gram
    gram = setcustomdisplay(u.g,'gram') 
    mg = setcustomdisplay(1e-3*u.gram,'mg') % milligram
    milligram = setcustomdisplay(u.mg,'milligram') 
    ug = setcustomdisplay(1e-6*u.gram,'ug') % microgram
    microgram = setcustomdisplay(u.ug,'microgram') 
    ng = setcustomdisplay(1e-9*u.gram,'ng') % nanogram
    nanogram = setcustomdisplay(1e-6*u.gram,'nanogram')
    Mg = setcustomdisplay(1e6*u.gram,'Mg') % Megagram/metric tonne
    Megagram = setcustomdisplay(u.Mg,'Megagram') 
    t = setcustomdisplay(1000*u.kg,'t') % metric tonne
    tonne = setcustomdisplay(u.t,'tonne') % metric ton
    Mt = setcustomdisplay(1e6*u.t,'Mt') % metric megatonne
    megatonne = setcustomdisplay(u.Mt,'megatonne') 
    lbm = setcustomdisplay(0.45359237*u.kg,'lbm') % pound mass
    lb_m = setcustomdisplay(u.lbm,'lb_m') % pound mass
    poundMass = setcustomdisplay(u.lbm,'poundMass') 
    lb = setcustomdisplay(u.lbm,'lb') % pound mass
    pound = setcustomdisplay(u.lb,'pound') 
    tn = setcustomdisplay(2000*u.lbm,'tn') % US customary short ton
    ton = setcustomdisplay(u.tn,'ton') % US customary short ton
    ton_UK = setcustomdisplay(2240*u.lbm,'ton_UK') % British imperial ton
    st = setcustomdisplay(14*u.lbm,'st') % stone
    stone = setcustomdisplay(u.st,'stone') 
    cwt = setcustomdisplay(100*u.lbm,'cwt') % US customary short hundredweight
    hundredweight = setcustomdisplay(u.cwt,'hundredweight') 
    cwt_UK = setcustomdisplay(8*u.stone,'cwt_UK') % British imperial short hundredweight
    quarter = setcustomdisplay(u.cwt_UK/4,'quarter') % British imperial quarter
    slug = setcustomdisplay(u.lbf/(u.ft/u.s^2),'slug') % slug
    slinch = setcustomdisplay(u.lbf/(u.in/u.s^2),'slinch') 
    blob = setcustomdisplay(u.slinch,'blob') 
    oz = setcustomdisplay(u.lbm/16,'oz') % ounce
    ounce = setcustomdisplay(u.oz,'ounce') 
    dr = setcustomdisplay(u.oz/16,'dr') % dram
    dram = setcustomdisplay(u.dr,'dram') 
    gr = setcustomdisplay(u.lbm/7000,'gr') % grain
    grain = setcustomdisplay(u.gr,'grain') 
    ct = setcustomdisplay(200*u.mg,'ct') % carat
    carat = setcustomdisplay(u.ct,'carat') 
    amu = setcustomdisplay(1.660539040e-27*u.kg,'amu') % atomic mass unit
    atomicMassUnit = setcustomdisplay(u.amu,'atomicMassUnit') 
    Da = setcustomdisplay(u.amu,'Da') % atomic mass unit
    dalton = setcustomdisplay(u.Da,'dalton') 
    kDa = setcustomdisplay(1000*u.Da,'kDa') 
    mu = setcustomdisplay(u.amu,'mu') % atomic mass unit
    mP = setcustomdisplay(2.176470e-8*u.kg,'mP') % Planck mass
    PlanckMass = setcustomdisplay(u.mP,'PlanckMass') 
    m_e = setcustomdisplay(9.10938356e-31*u.kg,'m_e') % electron mass
    electronMass = setcustomdisplay(u.m_e,'electronMass') 
    mug = setcustomdisplay(u.kgf/(u.m/u.s^2),'mug') % metric slug
    metricSlug = setcustomdisplay(u.mug,'metricSlug') 
    hyl = setcustomdisplay(u.mug,'hyl') % hyl
    par = setcustomdisplay(u.mug,'par') % par
    TMU = setcustomdisplay(u.mug,'TMU') % technische Masseneinheit
    technischeMasseneinheit = setcustomdisplay(u.TMU,'technischeMasseneinheit') 
    glug = setcustomdisplay(u.g*u.g0/(u.cm/u.s^2),'glug') 

    %---- more force ----

    pdl = setcustomdisplay(u.lbm*u.ft/u.s^2,'pdl') % poundal
    poundal = setcustomdisplay(u.pdl,'poundal') 
    gf = setcustomdisplay(u.gram*u.g0,'gf') % gram force
    g_f = setcustomdisplay(u.gf,'g_f') %gram force
    gramForce = setcustomdisplay(u.gf,'gramForce') 
    ozf = setcustomdisplay(u.oz*u.g0,'ozf') % ounce force
    oz_f = setcustomdisplay(u.ozf,'oz_f') % ounce force
    ounceForce = setcustomdisplay(u.ozf,'ounceForce') 
    tonf = setcustomdisplay(u.tn*u.g0,'tonf') % short ton force
    ton_f = setcustomdisplay(u.tonf,'ton_f') % short ton force
    tonForce = setcustomdisplay(u.tonf,'tonForce') 

    %---- mass per length ----

    den = setcustomdisplay(u.gram/(9*u.km),'den') % denier
    denier = setcustomdisplay(u.den,'denier') 
    tex = setcustomdisplay(u.gram/u.km,'tex') % tex
    dtex = setcustomdisplay(u.tex/10,'dtex') % decitex
    decitex = setcustomdisplay(u.dtex,'decitex') 

    %---- time ----

    second = setcustomdisplay(u.s,'second') 
    sec = setcustomdisplay(u.s,'sec') % second
    ms = setcustomdisplay(1e-3*u.s,'ms') % millisecond
    millisecond = setcustomdisplay(u.ms,'millisecond') 
    us = setcustomdisplay(1e-6*u.s,'us') % microsecond
    microsecond = setcustomdisplay(u.us,'microsecond') 
    ns = setcustomdisplay(1e-9*u.s,'ns') % nanosecond
    nanosecond = setcustomdisplay(u.ns,'nanosecond') 
    ps = setcustomdisplay(1e-12*u.s,'ps') % picosecond
    picosecond = setcustomdisplay(u.ps,'picosecond') 
    fs = setcustomdisplay(1e-15*u.s,'fs') % femtosecond
    femtosecond = setcustomdisplay(u.fs,'femtosecond') 
    tP = setcustomdisplay(5.39116e-44*u.s,'tP') % Planck time
    PlanckTime = setcustomdisplay(u.tP,'PlanckTime') 
    min = setcustomdisplay(60*u.s,'min') % minute
    minute = setcustomdisplay(u.min,'minute') 
    h = setcustomdisplay(60*u.min,'h') % hour
    hr = setcustomdisplay(u.h,'hr') % hour
    hrs = setcustomdisplay(u.h,'hrs')
    hour = setcustomdisplay(u.hr,'hour') 
    d = setcustomdisplay(24*u.hr,'d') % day
    day = setcustomdisplay(u.d,'day') % day
    days = setcustomdisplay(u.d,'days')
    week = setcustomdisplay(7*u.day,'week') % week
    fortnight = setcustomdisplay(2*u.week,'fortnight') % fortnight
    month_30 = setcustomdisplay(30*u.day,'month_30') % 30-day month
    yr = setcustomdisplay(365.25*u.day,'yr') % julian year
    y = setcustomdisplay(u.yr,'y') % julian year
    year = setcustomdisplay(u.yr,'year') % julian year
    yrs = setcustomdisplay(u.yr,'yrs') % julian year
    year_julian = setcustomdisplay(u.year,'year_julian') % julian year
    year_360 = setcustomdisplay(360*u.day,'year_360') % 360-day year
    year_Tropical = setcustomdisplay(365.24219*u.day,'year_Tropical') % tropical year
    year_Gregorian = setcustomdisplay(365.2425*u.day,'year_Gregorian') % gregorian year
    month = setcustomdisplay(u.yr/12,'month') % 1/12th julian year
    flick = setcustomdisplay(u.s/705600000,'flick') 

    %---- frequency ----

    Hz = setcustomdisplay(1/u.s,'Hz') % hertz (NB: incompatible with angle and angular velocity)
    hertz = setcustomdisplay(u.Hz,'hertz') 
    kHz = setcustomdisplay(1e3*u.Hz,'kHz') % kilohertz
    kilohertz = setcustomdisplay(u.kHz,'kilohertz') 
    MHz = setcustomdisplay(1e6*u.Hz,'MHz') % megahertz
    megahertz = setcustomdisplay(u.MHz,'megahertz') 
    GHz = setcustomdisplay(1e9*u.Hz,'GHz') % gigahertz
    gigahertz = setcustomdisplay(u.GHz,'gigahertz') 
    THz = setcustomdisplay(1e12*u.Hz,'THz') % terahertz
    terahertz = setcustomdisplay(u.THz,'terahertz') 
    Bd = setcustomdisplay(1/u.s,'Bd') % baud
    baud = setcustomdisplay(u.Bd,'baud') 

    %---- energy ----

    Nm = setcustomdisplay(u.N*u.m,'Nm') % newton-meter
    newton_meter = setcustomdisplay(u.Nm,'newton_meter') 
    J = setcustomdisplay(u.Nm,'J') % joule
    joule = setcustomdisplay(u.J,'joule') 
    kJ = setcustomdisplay(1e3*u.J,'kJ') % kilojoule
    kilojoule = setcustomdisplay(u.kJ,'kilojoule') 
    MJ = setcustomdisplay(1e6*u.J,'MJ') % megajoule
    megajoule = setcustomdisplay(u.MJ,'megajoule') 
    GJ = setcustomdisplay(1e9*u.J,'GJ') % gigajoule
    gigajoule = setcustomdisplay(u.GJ,'gigajoule') 
    mJ = setcustomdisplay(1e-3*u.J,'mJ') % millijoule
    millijoule = setcustomdisplay(u.mJ,'millijoule') 
    uJ = setcustomdisplay(1e-6*u.J,'uJ') % microjoule
    microjoule = setcustomdisplay(u.uJ,'microjoule') 
    nJ = setcustomdisplay(1e-9*u.J,'nJ') % nanojoule
    nanojoule = setcustomdisplay(u.nJ,'nanojoule') 
    eV = setcustomdisplay(1.6021766208e-19*u.J,'eV') % electronvolt
    electronvolt = setcustomdisplay(u.eV,'electronvolt') 
    BTU = setcustomdisplay(1055.06*u.J,'BTU') % British thermal unit (ISO)
    Btu = setcustomdisplay(u.BTU,'Btu') % British thermal unit (ISO)
    britishThermalUnit = setcustomdisplay(u.Btu,'britishThermalUnit') 
    Btu_IT = setcustomdisplay(1055.0559*u.J,'Btu_IT') % British thermal unit (International Table)
    Btu_th = setcustomdisplay(1054.3503*u.J,'Btu_th') % British thermal unit (thermochemical)
    kpm = setcustomdisplay(u.kp*u.m,'kpm') % kilopond-meter
    kilopond_meter = setcustomdisplay(u.kpm,'kilopond_meter') 
    Ws = setcustomdisplay(u.J,'Ws') % watt-second
    watt_second = setcustomdisplay(u.Ws,'watt_second') 
    kWh = setcustomdisplay(3.6e6*u.J,'kWh') % kilowatt-hour
    kilowatt_hour = setcustomdisplay(u.kWh,'kilowatt_hour') 
    Wh = setcustomdisplay(3.6e3*u.J,'Wh') % watt-hour
    watt_hour = setcustomdisplay(u.Wh,'watt_hour') 
    cal = setcustomdisplay(4.1868*u.J,'cal') % calorie (International Table)
    calorie = setcustomdisplay(u.cal,'calorie') 
    cal_IT = setcustomdisplay(u.cal,'cal_IT') % calorie (International Table)
    cal_4 = setcustomdisplay(4.204*u.J,'cal_4') % calorie (4°C)
    cal_15 = setcustomdisplay(4.1855*u.J,'cal_15') % calorie (15°C)
    cal_20 = setcustomdisplay(4.182*u.J,'cal_20') % calorie (20°C)
    cal_mean = setcustomdisplay(4.190*u.J,'cal_mean') % calorie (mean)
    cal_th = setcustomdisplay(4.184*u.J,'cal_th') % calorie (thermochemical)
    kcal = setcustomdisplay(1e3*u.cal,'kcal') % kilocalorie
    kilocalorie = setcustomdisplay(u.kcal,'kilocalorie') 
    kcal_IT = setcustomdisplay(1e3*u.cal_IT,'kcal_IT') % kilocalorie (International Table)
    Cal = setcustomdisplay(u.kcal,'Cal') % large calorie / food calorie
    foodCalorie = setcustomdisplay(u.Cal,'foodCalorie') 
    largeCalorie = setcustomdisplay(u.Cal,'largeCalorie') 
    kcal_4 = setcustomdisplay(1e3*u.cal_4,'kcal_4') % kilocalorie (4°C)
    kcal_15 = setcustomdisplay(1e3*u.cal_15,'kcal_15') % kilocalorie (15°C)
    kcal_20 = setcustomdisplay(1e3*u.cal_20,'kcal_20') % kilocalorie (20°C)
    kcal_mean = setcustomdisplay(1e3*u.cal_mean,'kcal_mean') % kilocalorie (mean)
    kcal_th = setcustomdisplay(1e3*u.cal_th,'kcal_th') % kilocalorie (thermochemical)
    erg = setcustomdisplay(1e-7*u.J,'erg') % en.wikipedia.org/wiki/Erg
    E_h = setcustomdisplay(4.359744650e-18*u.J,'E_h') % Hartree energy
    Ha = setcustomdisplay(u.E_h,'Ha') % hartree
    hartree = setcustomdisplay(u.Ha,'hartree') 
    thm = setcustomdisplay(1e5*u.BTU,'thm') % therm
    therm = setcustomdisplay(u.thm,'therm') 
    quad = setcustomdisplay(1e15*u.BTU,'quad') % quad

    %---- temperature ----
    % For reference: °C = °K-273.15; °F = °R-459.67.

    kelvin = setcustomdisplay(u.K,'kelvin') 
    R = setcustomdisplay(u.K*5/9,'R') % rankine (°F = °R-459.67)
    rankine = setcustomdisplay(u.R,'rankine') 
    mK = setcustomdisplay(1e-3*u.K,'mK') % millikelvin
    millikelvin = setcustomdisplay(u.mK,'millikelvin') 
    uK = setcustomdisplay(1e-6*u.K,'uK') % microkelvin
    microkelvin = setcustomdisplay(u.uK,'microkelvin') 
    nK = setcustomdisplay(1e-9*u.K,'nK') % nanokelvin
    nanokelvin = setcustomdisplay(u.nK,'nanokelvin') 
    deltaK = setcustomdisplay(u.K,'deltaK') % kelvin (relative temperature)
    deltadegC = setcustomdisplay(u.K,'deltadegC') % celsius (relative, °C = °K-273.15)
    deltadegR = setcustomdisplay(u.R,'deltadegR') % rankine (relative temperature)
    deltadegF = setcustomdisplay(u.R,'deltadegF') % fahrenheit (relative, °F = °R-459.67)
    TP = setcustomdisplay(1.416808e32*u.K,'TP') % Planck temperature
    PlanckTemperature = setcustomdisplay(u.TP,'PlanckTemperature') 

    %---- pressure ----

    Pa = setcustomdisplay(u.N/u.sqm,'Pa') % pascal
    pascal = setcustomdisplay(u.Pa,'pascal') 
    mPa = setcustomdisplay(1e-3*u.Pa,'mPa') % millipascal
    millipascal = setcustomdisplay(u.mPa,'millipascal') 
    uPa = setcustomdisplay(1e-6*u.Pa,'uPa') % micropascal
    micropascal = setcustomdisplay(u.uPa,'micropascal') 
    kPa = setcustomdisplay(1e3*u.Pa,'kPa') % kilopascal
    kilopascal = setcustomdisplay(u.kPa,'kilopascal') 
    MPa = setcustomdisplay(1e6*u.Pa,'MPa') % megapascal
    megapascal = setcustomdisplay(u.MPa,'megapascal') 
    GPa = setcustomdisplay(1e9*u.Pa,'GPa') % gigapascal
    gigapascal = setcustomdisplay(u.GPa,'gigapascal') 
    torr = setcustomdisplay(133.322*u.Pa,'torr') % torr
    Torr = setcustomdisplay(u.torr,'Torr') % torr
    mtorr = setcustomdisplay(1e-3*u.torr,'mtorr') % millitorr
    millitorr = setcustomdisplay(u.mtorr,'millitorr') 
    bar = setcustomdisplay(1e5*u.Pa,'bar') % bar
    mbar = setcustomdisplay(1e-3*u.bar,'mbar') % millibar
    millibar = setcustomdisplay(u.mbar,'millibar') 
    kbar = setcustomdisplay(1e3*u.bar,'kbar') % kilobar
    kilobar = setcustomdisplay(u.kbar,'kilobar') 
    atm = setcustomdisplay(101325*u.Pa,'atm') % standard atmosphere
    atmosphere = setcustomdisplay(u.atm,'atmosphere') 
    standardAtmosphere = setcustomdisplay(u.atm,'standardAtmosphere') 
    at = setcustomdisplay(u.kgf/u.sqcm,'at') % technical atmosphere
    technicalAtmosphere = setcustomdisplay(u.at,'technicalAtmosphere') 
    psi = setcustomdisplay(u.lbf/u.sqin,'psi') % pound force per square inch
    poundPerSquareInch = setcustomdisplay(u.psi,'poundPerSquareInch') 
    ksi = setcustomdisplay(1e3*u.psi,'ksi') % kip per square inch
    kipPerSquareInch = setcustomdisplay(u.ksi,'kipPerSquareInch') 
    Msi = setcustomdisplay(1e6*u.psi,'Msi') % million pound force per square inch
    megapoundPerSquareInch = setcustomdisplay(u.Msi,'megapoundPerSquareInch') 
    psf = setcustomdisplay(u.lbf/u.sqft,'psf') % pound force per square foot
    poundPerSquareFoot = setcustomdisplay(u.psf,'poundPerSquareFoot') 
    ksf = setcustomdisplay(u.kip/u.sqft,'ksf') % kip per square foot
    kipPerSquareFoot = setcustomdisplay(u.ksf,'kipPerSquareFoot') 
    Ba = setcustomdisplay(0.1*u.Pa,'Ba') % barye
    barye = setcustomdisplay(u.Ba,'barye') 
    pz = setcustomdisplay(u.kPa,'pz') % pièze
    pieze = setcustomdisplay(u.pz,'pieze') 
    mmHg = setcustomdisplay(13.5951*u.kgf/u.sqm,'mmHg') % millimeter of mercury
    millimeterMercury = setcustomdisplay(u.mmHg,'millimeterMercury') 
    cmHg = setcustomdisplay(10*u.mmHg,'cmHg') % centimeter of mercury
    centimeterMercury = setcustomdisplay(u.cmHg,'centimeterMercury') 
    mHg = setcustomdisplay(1e3*u.mmHg,'mHg') % meter of mercury
    meterMercury = setcustomdisplay(u.mHg,'meterMercury') 
    inHg = setcustomdisplay(2.54*u.cmHg,'inHg') % inch of mercury
    inchMercury = setcustomdisplay(u.inHg,'inchMercury') 
    ftHg = setcustomdisplay(12*u.inHg,'ftHg') % foot of mercury
    footMercury = setcustomdisplay(u.ftHg,'footMercury') 
    mmH2O = setcustomdisplay(u.kgf/u.sqm,'mmH2O') % millimeter of water (density 1 g/cc)
    mmAq = setcustomdisplay(u.mmH2O,'mmAq') % millimeter of water
    millimeterWater = setcustomdisplay(u.mmH2O,'millimeterWater') 
    cmH2O = setcustomdisplay(10*u.mmH2O,'cmH2O') % centimeter of water
    cmAq = setcustomdisplay(u.cmH2O,'cmAq') % centimeter of water
    centimeterWater = setcustomdisplay(u.cmH2O,'centimeterWater') 
    mH2O = setcustomdisplay(1e3*u.mmH2O,'mH2O') % meter of water
    mAq = setcustomdisplay(u.mH2O,'mAq') % meter of water
    meterWater = setcustomdisplay(u.mH2O,'meterWater') 
    inH2O = setcustomdisplay(2.54*u.cmH2O,'inH2O') % inch of water
    inAq = setcustomdisplay(u.inH2O,'inAq') % inch of water
    inchWater = setcustomdisplay(u.inH2O,'inchWater') 
    wc = setcustomdisplay(u.inH2O,'wc') % inch water column
    inchWaterColumn = setcustomdisplay(u.wc,'inchWaterColumn') 
    ftH2O = setcustomdisplay(12*u.inH2O,'ftH2O') % foot of water
    ftAq = setcustomdisplay(u.ftH2O,'ftAq') % foot of water
    footWater = setcustomdisplay(u.ftH2O,'footWater') 

    %---- viscosity ----

    St = setcustomdisplay(u.sqcm/u.s,'St') % stokes
    stokes = setcustomdisplay(u.St,'stokes') 
    cSt = setcustomdisplay(u.St/100,'cSt') % centistokes
    centistokes = setcustomdisplay(u.cSt,'centistokes') 
    newt = setcustomdisplay(u.sqin/u.s,'newt') % newt
    P = setcustomdisplay(u.Pa*u.s / 10,'P') % poise
    poise = setcustomdisplay(u.P,'poise') 
    cP = setcustomdisplay(u.mPa*u.s,'cP') % centipoise
    centipoise = setcustomdisplay(u.cP,'centipoise') 
    reyn = setcustomdisplay(u.lbf*u.s/u.sqin,'reyn') % reyn

    %---- power ----

    W = setcustomdisplay(u.J/u.s,'W') % watt
    watt = setcustomdisplay(u.W,'watt') 
    kW = setcustomdisplay(1e3*u.W,'kW') % kilowatt
    kilowatt = setcustomdisplay(u.kW,'kilowatt') 
    MW = setcustomdisplay(1e6*u.W,'MW') % megawatt
    megawatt = setcustomdisplay(u.MW,'megawatt') 
    GW = setcustomdisplay(1e9*u.W,'GW') % gigawatt
    gigawatt = setcustomdisplay(u.GW,'gigawatt') 
    TW = setcustomdisplay(1e12*u.W,'TW') % terawatt
    terawatt = setcustomdisplay(u.TW,'terawatt') 
    mW = setcustomdisplay(1e-3*u.W,'mW') % milliwatt
    milliwatt = setcustomdisplay(u.mW,'milliwatt') 
    uW = setcustomdisplay(1e-6*u.W,'uW') % microwatt
    microwatt = setcustomdisplay(u.uW,'microwatt') 
    nW = setcustomdisplay(1e-9*u.W,'nW') % nanowatt
    nanowatt = setcustomdisplay(u.nW,'nanowatt') 
    pW = setcustomdisplay(1e-12*u.W,'pW') % picowatt
    picowatt = setcustomdisplay(u.pW,'picowatt') 
    hp = setcustomdisplay(550*u.ft*u.lbf/u.s,'hp') % mechanical horsepower (550 ft-lbf/s)
    horsepower = setcustomdisplay(u.hp,'horsepower') 
    HP_I = setcustomdisplay(u.hp,'HP_I') % mechanical horsepower (550 ft-lbf/s)
    hpE = setcustomdisplay(746*u.W,'hpE') % electrical horsepower
    HP_E = setcustomdisplay(u.hpE,'HP_E') % electrical horsepower
    electricalHorsepower = setcustomdisplay(u.hp,'electricalHorsepower') 
    PS = setcustomdisplay(75*u.kg*u.g0*u.m/u.s,'PS') % metric horsepower (DIN 66036)
    HP = setcustomdisplay(u.PS,'HP') % metric horsepower (DIN 66036)
    HP_DIN = setcustomdisplay(u.PS,'HP_DIN') % metric horsepower (DIN 66036)
    metricHorsepower = setcustomdisplay(u.PS,'metricHorsepower') 

    %---- current ----

    amp = setcustomdisplay(u.A,'amp') % ampere
    ampere = setcustomdisplay(u.A,'ampere') 
    mA = setcustomdisplay(1e-3*u.A,'mA') % milliampere
    milliampere = setcustomdisplay(u.mA,'milliampere') 
    uA = setcustomdisplay(1e-6*u.A,'uA') % microampere
    microampere = setcustomdisplay(u.uA,'microampere') 
    nA = setcustomdisplay(1e-9*u.A,'nA') % nanoampere
    nanoampere = setcustomdisplay(u.nA,'nanoampere') 
    pA = setcustomdisplay(1e-12*u.A,'pA') % picoampere
    picoampere = setcustomdisplay(u.pA,'picoampere') 
    kA = setcustomdisplay(1e3*u.A,'kA') % kiloampere
    kiloampere = setcustomdisplay(u.kA,'kiloampere') 
    abA = setcustomdisplay(10*u.A,'abA') % abampere
    abampere = setcustomdisplay(u.abA,'abampere') 
    Bi = setcustomdisplay(u.abA,'Bi') % biot
    biot = setcustomdisplay(u.Bi,'biot') 

    %---- charge ----

    C = setcustomdisplay(u.A*u.s,'C') % coulomb
    coulomb = setcustomdisplay(u.C,'coulomb') 
    mC = setcustomdisplay(1e-3*u.C,'mC') % millicoulomb
    millicoulomb = setcustomdisplay(u.mC,'millicoulomb') 
    uC = setcustomdisplay(1e-6*u.C,'uC') % microcoulomb
    microcoulomb = setcustomdisplay(u.uC,'microcoulomb') 
    nC = setcustomdisplay(1e-9*u.C,'nC') % nanocoulomb
    nanocoulomb = setcustomdisplay(u.nC,'nanocoulomb') 
    pC = setcustomdisplay(1e-12*u.C,'pC') % picocoulomb
    picocoulomb = setcustomdisplay(u.pC,'picocoulomb') 
    abC = setcustomdisplay(10*u.C,'abC') % abcoulomb
    aC = setcustomdisplay(u.abC,'aC') % abcoulomb
    abcoulomb = setcustomdisplay(u.abC,'abcoulomb') 
    statC = setcustomdisplay(u.dyn^(1/2)*u.cm,'statC') % statcoulomb
    statcoulomb = setcustomdisplay(u.statC,'statcoulomb') 
    Fr = setcustomdisplay(u.statC,'Fr') % franklin
    franklin = setcustomdisplay(u.Fr,'franklin') 
    esu = setcustomdisplay(u.statC,'esu') % electrostatic unit of charge
    electrostaticUnitCharge = setcustomdisplay(u.esu,'electrostaticUnitCharge') 
    e = setcustomdisplay(1.6021766208e-19*u.C,'e') % elementary charge
    elementaryCharge = setcustomdisplay(u.e,'elementaryCharge') 
    mAh = setcustomdisplay(u.mA*u.hr,'mAh') % milliamp-hour
    milliamp_hour = setcustomdisplay(u.mAh,'milliamp_hour') 
    Ah = setcustomdisplay(u.A*u.hr,'Ah') % amp-hour
    amp_hour = setcustomdisplay(u.Ah,'amp_hour') 

    %---- voltage ----

    V = setcustomdisplay(1*u.J/u.C,'V') % volt
    volt = setcustomdisplay(u.V,'volt') 
    kV = setcustomdisplay(1e3*u.V,'kV') % kilovolt
    kilovolt = setcustomdisplay(u.kV,'kilovolt') 
    MV = setcustomdisplay(1e6*u.V,'MV') % megavolt
    megavolt = setcustomdisplay(u.MV,'megavolt') 
    GV = setcustomdisplay(1e9*u.V,'GV') % gigavolt
    gigavolt = setcustomdisplay(u.GV,'gigavolt') 
    mV = setcustomdisplay(1e-3*u.V,'mV') % millivolt
    millivolt = setcustomdisplay(u.mV,'millivolt') 
    uV = setcustomdisplay(1e-6*u.V,'uV') % microvolt
    microvolt = setcustomdisplay(u.uV,'microvolt') 

    %---- resistance/conductance ----

    Ohm = setcustomdisplay(u.V/u.A,'Ohm') % ohm
    GOhm = setcustomdisplay(1e9*u.Ohm,'GOhm') % gigaohm
    gigaohm = setcustomdisplay(u.GOhm,'gigaohm') 
    MOhm = setcustomdisplay(1e6*u.Ohm,'MOhm') % megaohm
    megaohm = setcustomdisplay(u.MOhm,'megaohm') 
    kOhm = setcustomdisplay(1e3*u.Ohm,'kOhm') % kiloohm
    kiloohm = setcustomdisplay(u.kOhm,'kiloohm') 
    mOhm = setcustomdisplay(1e-3*u.Ohm,'mOhm') % milliohm
    milliohm = setcustomdisplay(u.mOhm,'milliohm') 
    uOhm = setcustomdisplay(1e-6*u.Ohm,'uOhm') % microohm
    microohm = setcustomdisplay(u.uOhm,'microohm') 
    nOhm = setcustomdisplay(1e-9*u.Ohm,'nOhm') % nanoohm
    nanoohm = setcustomdisplay(u.nOhm,'nanoohm') 
    abOhm = setcustomdisplay(u.nOhm,'abOhm') % abohm
    Z0 = setcustomdisplay(376.730313461*u.Ohm,'Z0') % characteristic impedance of vacuum
    impedanceOfVacuum = setcustomdisplay(u.Z0,'impedanceOfVacuum') 
    R_K = setcustomdisplay(25812.8074555*u.Ohm,'R_K') % von Klitzing constant
    vonKlitzingConstant = setcustomdisplay(u.R_K,'vonKlitzingConstant') 
    R_K_90 = setcustomdisplay(25812.807*u.Ohm,'R_K_90') % von Klitzing constant (conventional value)
    vonKlitzingConstant_conv = setcustomdisplay(u.R_K_90,'vonKlitzingConstant_conv') 
    S = setcustomdisplay(1/u.Ohm,'S') % siemens
    siemens = setcustomdisplay(u.S,'siemens') 
    mS = setcustomdisplay(1e-3*u.S,'mS') % millisiemens
    millisiemens = setcustomdisplay(u.mS,'millisiemens') 
    uS = setcustomdisplay(1e-6*u.S,'uS') % microsiemens
    microsiemens = setcustomdisplay(u.uS,'microsiemens') 
    nS = setcustomdisplay(1e-9*u.S,'nS') % nanosiemens
    nanosiemens = setcustomdisplay(u.nS,'nanosiemens') 
    G0 = setcustomdisplay(7.7480917310e-5*u.S,'G0') % conductance quantum
    conductanceQuantum = setcustomdisplay(u.G0,'conductanceQuantum') 

    %---- capacitance ----

    F = setcustomdisplay(u.A*u.s/u.V,'F') % farad
    farad = setcustomdisplay(u.F,'farad') 
    mF = setcustomdisplay(1e-3*u.F,'mF') % millifarad
    millifarad = setcustomdisplay(u.mF,'millifarad') 
    uF = setcustomdisplay(1e-6*u.F,'uF') % microfarad
    microfarad = setcustomdisplay(u.uF,'microfarad') 
    nF = setcustomdisplay(1e-9*u.F,'nF') % nanofarad
    nanofarad = setcustomdisplay(u.nF,'nanofarad') 
    pF = setcustomdisplay(1e-12*u.F,'pF') % picofarad
    picofarad = setcustomdisplay(u.pF,'picofarad') 

    %---- inductance ----

    H = setcustomdisplay(u.Ohm*u.s,'H') % henry
    henry = setcustomdisplay(u.H,'henry') 
    mH = setcustomdisplay(1e-3*u.H,'mH') % millihenry
    millihenry = setcustomdisplay(u.mH,'millihenry') 
    uH = setcustomdisplay(1e-6*u.H,'uH') % microhenry
    microhenry = setcustomdisplay(u.uH,'microhenry') 
    nH = setcustomdisplay(1e-9*u.H,'nH') % nanohenry
    nanohenry = setcustomdisplay(u.nH,'nanohenry') 
    abH = setcustomdisplay(u.nH,'abH') % abhenry
    abhenry = setcustomdisplay(u.abH,'abhenry') 
    kH = setcustomdisplay(1e3*u.H,'kH') % kilohenry
    kilohenry = setcustomdisplay(u.kH,'kilohenry') 
    MH = setcustomdisplay(1e6*u.H,'MH') % megahenry
    megahenry = setcustomdisplay(u.MH,'megahenry') 
    GH = setcustomdisplay(1e9*u.H,'GH') % gigahenry
    gigahenry = setcustomdisplay(u.GH,'gigahenry') 

    %---- EM ----

    T = setcustomdisplay(1*u.N/(u.A*u.m),'T') % tesla
    tesla = setcustomdisplay(u.T,'tesla') 
    Gs = setcustomdisplay(1e-4*u.T,'Gs') % gauss
    gauss = setcustomdisplay(u.Gs,'gauss') 
    Wb = setcustomdisplay(u.V*u.s,'Wb') % weber
    weber = setcustomdisplay(u.Wb,'weber') 
    Mx = setcustomdisplay(1e-8*u.Wb,'Mx') % maxwell
    maxwell = setcustomdisplay(u.Mx,'maxwell') 
    mWb = setcustomdisplay(u.Wb/1000,'mWb') % milliweber
    milliweber = setcustomdisplay(u.mWb,'milliweber') 
    uWb = setcustomdisplay(1e-6*u.Wb,'uWb') % microweber
    microweber = setcustomdisplay(u.uWb,'microweber') 
    nWb = setcustomdisplay(1e-9*u.Wb,'nWb') % nanoweber
    nanoweber = setcustomdisplay(u.nWb,'nanoweber') 
    Oe = setcustomdisplay(250/pi*u.A/u.m,'Oe') % oersted
    oersted = setcustomdisplay(u.Oe,'oersted') 
    Gb = setcustomdisplay(2.5/pi*u.A,'Gb') % gilbert
    gilbert = setcustomdisplay(u.Gb,'gilbert') 

    %---- non-dimensionals ----

    percent = 0.01 % %
    pct = u.percent % %
    permil = 0.001 % ‰
    permill = u.permil % ‰
    permille = u.permil % ‰
    permyriad = 1e-4 % permyriad
    bp = u.permyriad % basis point
    basisPoint = u.bp
    ppm = 1e-6 % part per million
    partPerMillion = u.ppm 
    ppb = 1e-9 % part per billion
    partPerBillion = u.ppb
    ppt = 1e-12 % part per trillion
    partPerTrillion = u.ppt
    ppq = 1e-15 % part per quadrillion
    partPerQuadrillion = u.ppq 
    
    %---- angles ----
    % Note: angles are dimensionless

    rad = 1 % radian
    radian = u.rad
    sr = 1 % steradian
    steradian = u.sr
    turn = 2*pi*u.rad % turn
    rev = u.turn % revolution = 2*pi radians
    revolution = u.rev
    deg = u.turn/360 % degree
    degree = u.deg
    arcmin = u.deg/60 % arcminute
    arcminute = u.arcmin
    arcsec = u.arcmin/60 % arcsecond
    arcsecond = u.arcsec
    grad = u.turn/400 % gradian
    gradian = u.grad
    
    %---- rotational speed ----

    rpm = setcustomdisplay(u.rev/u.min,'rpm') % revolution per minute
    revolutionPerMinute = setcustomdisplay(u.rpm,'revolutionPerMinute') 
    rps = setcustomdisplay(u.rev/u.s,'rps') % revolution per second
    revolutionPerSecond = setcustomdisplay(u.rps,'revolutionPerSecond') 

    %---- velocity ----

    mps = setcustomdisplay(u.m/u.s,'mps') % meter per second
    meterPerSecond = setcustomdisplay(u.mps,'meterPerSecond') 
    kyne = setcustomdisplay(u.cm/u.s,'kyne') % kyne
    Kyne = setcustomdisplay(u.kyne,'Kyne') % kyne
    fps = setcustomdisplay(u.ft/u.s,'fps') % foot per second
    footPerSecond = setcustomdisplay(u.fps,'footPerSecond') 
    fpm = setcustomdisplay(u.ft/u.min,'fpm') % foot per minute
    footPerMinute = setcustomdisplay(u.fpm,'footPerMinute') 
    kt = setcustomdisplay(u.nmi/u.hr,'kt') % knot
    kn = setcustomdisplay(u.kt,'kn') % knot
    kts = setcustomdisplay(u.kt,'kts') % knot
    knot = setcustomdisplay(u.kt,'knot') 
    knot_UK = setcustomdisplay(u.nm_UK/u.hr,'knot_UK') % British imperial knot
    KTAS = setcustomdisplay(u.kt,'KTAS') % knot
    nmph = setcustomdisplay(u.kt,'nmph') % nautical mile per hour
    nauticalMilePerHour = setcustomdisplay(u.nmph,'nauticalMilePerHour') 
    kph = setcustomdisplay(u.km/u.hr,'kph') % kilometer per hour
    kmh = setcustomdisplay(u.kph,'kmh') % kilometer per hour
    kilometerPerHour = setcustomdisplay(u.kmh,'kilometerPerHour') 
    mph = setcustomdisplay(u.mi/u.hr,'mph') % mile per hour
    milePerHour = setcustomdisplay(u.mph,'milePerHour') 

    %---- volume flow rate ----

    cfm = setcustomdisplay(u.ft^3/u.min,'cfm') % cubic foot per minute
    cubicFootPerMinute = setcustomdisplay(u.cfm,'cubicFootPerMinute') 
    cfs = setcustomdisplay(u.ft^3/u.s,'cfs') % cubic foot per second
    cubicFootPerSecond = setcustomdisplay(u.cfs,'cubicFootPerSecond') 
    gpm = setcustomdisplay(u.gal/u.min,'gpm') % US customary gallon per minute
    gallonPerMinute = setcustomdisplay(u.gpm,'gallonPerMinute') 
    gph = setcustomdisplay(u.gal/u.hr,'gph') % US customary gallon per hour
    gallonPerHour = setcustomdisplay(u.gph,'gallonPerHour') 
    gpm_UK = setcustomdisplay(u.gal_UK/u.min,'gpm_UK') % British imperial gallon per minute
    lpm = setcustomdisplay(u.l/u.min,'lpm') % liter per minute
    literPerMinute = setcustomdisplay(u.lpm,'literPerMinute') 

    %---- fuel economy ----

    l_100km = setcustomdisplay(u.l/(100*u.km),'l_100km') % liter per 100 km
    literPer100kilometer = setcustomdisplay(u.l_100km,'literPer100kilometer') 
    mpg = setcustomdisplay(u.mi/u.gal,'mpg') % mile per gallon
    milePerGallon = setcustomdisplay(u.mpg,'milePerGallon') 

    %---- Luminance etc. ----

    candela = setcustomdisplay(u.cd,'candela') 
    asb = setcustomdisplay(u.cd/u.sqm,'asb') % apostilb
    apostilb = setcustomdisplay(u.asb,'apostilb') 
    sb = setcustomdisplay(u.cd/u.sqcm,'sb') % stilb
    stilb = setcustomdisplay(u.sb,'stilb') 
    ph = setcustomdisplay(1e4*u.cd*u.sr/u.sqm,'ph') % phot
    phot = setcustomdisplay(u.ph,'phot') 
    cp = setcustomdisplay(0.981*u.cd,'cp') % candlepower
    candlepower = setcustomdisplay(u.cp,'candlepower') 
    lm = setcustomdisplay(u.cd*u.sr,'lm') % lumen
    lumen = setcustomdisplay(u.lm,'lumen') 
    lx = setcustomdisplay(u.lm/u.sqm,'lx') % lux
    lux = setcustomdisplay(u.lx,'lux') 
    nx = setcustomdisplay(1e-3*u.lx,'nx') % nox
    nox = setcustomdisplay(u.nx,'nox') 

    %---- other derived SI ----

    mole = setcustomdisplay(u.mol,'mole') 
    mmol = setcustomdisplay(1e-3*u.mol,'mmol') % millimole
    umol = setcustomdisplay(1e-6*u.mol,'umol') % micromole
    nmol = setcustomdisplay(1e-9*u.mol,'nmol') % nanomole
    kat = setcustomdisplay(u.mol/u.s,'kat') % katal
    katal = setcustomdisplay(u.kat,'katal') 
    M = setcustomdisplay(u.mol/u.L,'M') % molar
    mM = setcustomdisplay(1e-3*u.M,'mM') % millimolar
    uM = setcustomdisplay(1e-6*u.M,'uM') % micromolar
    nM = setcustomdisplay(1e-9*u.M,'nM') % nanomolar

    molar = setcustomdisplay(u.M,'molar') 
    molarity = setcustomdisplay(u.M,'molarity') % molarity
    Nms = setcustomdisplay(u.N*u.m*u.s,'Nms') % newton-meter-second
    newton_meter_second = setcustomdisplay(u.Nms,'newton_meter_second') 

    %---- radiation ----

    Gy = setcustomdisplay(u.J/u.kg,'Gy') % gray
    gray = setcustomdisplay(u.Gy,'gray') 
    Sv = setcustomdisplay(u.J/u.kg,'Sv') % sievert
    sievert = setcustomdisplay(u.Sv,'sievert') 
    Rad = setcustomdisplay( u.Gy/100,'Rad') % absorbed radiation dose
    rem = setcustomdisplay(u.Sv/100,'rem') % roentgen equivalent man
    roentgenEquivalentMan = setcustomdisplay(u.rem,'roentgenEquivalentMan') 
    roentgen = setcustomdisplay(2.58e-4*u.C/u.kg,'roentgen') % roentgen
    Ly = setcustomdisplay(u.cal_th/u.sqcm,'Ly') % langley
    lan = setcustomdisplay(u.Ly,'lan') % langley
    langley = setcustomdisplay(u.lan,'langley') 
    Bq = setcustomdisplay(1/u.s,'Bq') % becquerel
    becquerel = setcustomdisplay(u.Bq,'becquerel') 
    Ci = setcustomdisplay(3.7e10*u.Bq,'Ci') % curie
    curie = setcustomdisplay(u.Ci,'curie') 

    %---- constants ----
    
    i = 1i
    j = 1j
    pi = pi % Archimedes' constant ?
    tau = 2*pi
    phi = (1 + sqrt(5))/2 % golden ratio
    EulersNumber = exp(1) % ("e" is reserved for elementary charge)

    k_B = setcustomdisplay(1.38064852e-23*u.J/u.K,'k_B') % Boltzmann constant
    BoltzmannConstant = setcustomdisplay(u.k_B,'BoltzmannConstant') 
    sigma_SB = setcustomdisplay(5.670367e-8*u.W/(u.sqm*u.K^4),'sigma_SB') % Stefan–Boltzmann constant
    Stefan_BoltzmannConstant = setcustomdisplay(u.sigma_SB,'Stefan_BoltzmannConstant') 
    h_c = setcustomdisplay(6.626070040e-34*u.J*u.s,'h_c') % Planck constant
    PlanckConstant = setcustomdisplay(u.h_c,'PlanckConstant') 
    h_bar = setcustomdisplay(u.h_c/(2*pi),'h_bar') % Dirac constant
    DiracConstant = setcustomdisplay(u.h_bar,'DiracConstant') 
    mu_B = setcustomdisplay(9.274009994e-24*u.J/u.T,'mu_B') % Bohr magneton
    BohrMagneton = setcustomdisplay(u.mu_B,'BohrMagneton') 
    mu_N = setcustomdisplay(5.050783699e-27*u.J/u.T,'mu_N') % nuclear magneton
    nuclearMagneton = setcustomdisplay(u.mu_N,'nuclearMagneton') 
    c = setcustomdisplay(299792458*u.m/u.s,'c') % speed of light in vacuum
    c_0 = setcustomdisplay(u.c,'c_0') % speed of light in vacuum
    lightSpeed = setcustomdisplay(u.c,'lightSpeed') 
    speedOfLight = setcustomdisplay(u.c,'speedOfLight') 
    ly = setcustomdisplay(u.c*u.year,'ly') % light-year
    lightYear = setcustomdisplay(u.ly,'lightYear') % light-year
    mu0 = setcustomdisplay(pi*4e-7*u.N/u.A^2,'mu0') % vacuum permeability
    vacuumPermeability = setcustomdisplay(u.mu0,'vacuumPermeability') 
    eps0 = setcustomdisplay(u.c^-2/u.mu0,'eps0') % vacuum permittivity
    vacuumPermittivity = setcustomdisplay(u.eps0,'vacuumPermittivity') 
    G = setcustomdisplay(6.67408e-11*u.m^3/u.kg/u.s^2,'G') % gravitational constant
    gravitationalConstant = setcustomdisplay(u.G,'gravitationalConstant') 
    N_A = setcustomdisplay(6.022140857e23/u.mol,'N_A') % Avogadro constant
    NA = setcustomdisplay(u.N_A,'NA') % Avogadro constant
    AvogadroConstant = setcustomdisplay(u.N_A,'AvogadroConstant') 
    NAh = setcustomdisplay(u.N_A*u.h_c,'NAh') % molar Planck constant
    molarPlanckConstant = setcustomdisplay(u.NAh,'molarPlanckConstant') 
    M_u = setcustomdisplay(u.g/u.mol,'M_u') % molar mass constant
    molarMassConstant = setcustomdisplay(u.M_u,'molarMassConstant') 
    K_J = setcustomdisplay(483597.8525e9*u.Hz/u.V,'K_J') % Josephson constant
    JosephsonConstant = setcustomdisplay(u.K_J,'JosephsonConstant') 
    K_J_90 = setcustomdisplay(483597.9*u.Hz/u.V,'K_J_90') % Josephson constant (conv. value)
    JosephsonConstant_conv = setcustomdisplay(u.K_J_90,'JosephsonConstant_conv') 
    F_c = setcustomdisplay(96485.33289*u.C/u.mol,'F_c') % Faraday constant
    FaradayConstant = setcustomdisplay(u.F_c,'FaradayConstant') 
    alpha = 7.2973525664e-3 % fine-structure constant
    fine_structureConstant = u.alpha
    SommerfeldConstant = u.alpha
    c1 = setcustomdisplay(3.741771790e-16*u.W/u.sqm,'c1') % first radiation constant
    firstRadiationConstant = setcustomdisplay(u.c1,'firstRadiationConstant') 
    c2 = setcustomdisplay(1.43877736e-2*u.m*u.K,'c2') % second radiation constant
    secondRadiationConstant = setcustomdisplay(u.c2,'secondRadiationConstant') 
    b_prime = setcustomdisplay(5.8789238e10*u.Hz/u.K,'b_prime') % Wien frequency displ. law const.
    WienFrequencyDisplacementLawConstant = setcustomdisplay(u.b_prime,'WienFrequencyDisplacementLawConstant') 
    b_c = setcustomdisplay(2.8977729e-3*u.m*u.K,'b_c') % Wien wavelength displ. law const.
    WienWavelengthDisplacementLawConstant = setcustomdisplay(u.b_c,'WienWavelengthDisplacementLawConstant') 
    R_air = setcustomdisplay(287.05287*u.J/u.kg/u.K,'R_air') % spec. gas const., air (ESDU 77022)
    specificGasConstant_air = setcustomdisplay(u.R_air,'specificGasConstant_air') 
    R_bar = setcustomdisplay(8.3144598*u.J/u.mol/u.K,'R_bar') % molar gas constant
    molarGasConstant = setcustomdisplay(u.R_bar,'molarGasConstant') 
    radarStatuteMile = setcustomdisplay(2*u.mi/u.c,'radarStatuteMile') 
    radarNauticalMile = setcustomdisplay(2*u.NM/u.c,'radarNauticalMile') 
    radarDataMile = setcustomdisplay(2*u.dataMile/u.c,'radarDataMile') 
    radarKilometer = setcustomdisplay(2*u.km/u.c,'radarKilometer') 

    %---- digital information ----

    nibble = setcustomdisplay(4*u.bit,'nibble') 
    B = setcustomdisplay(8*u.bit,'B') % byte
    byte = setcustomdisplay(u.B,'byte') 
    octet = setcustomdisplay(u.B,'octet') % octet
    kB = setcustomdisplay(1e3*u.B,'kB') % kilobyte
    kilobyte = setcustomdisplay(u.kB,'kilobyte') 
    MB = setcustomdisplay(1e6*u.B,'MB') % megabyte
    megabyte = setcustomdisplay(u.MB,'megabyte') 
    GB = setcustomdisplay(1e9*u.B,'GB') % gigabyte
    gigabyte = setcustomdisplay(u.GB,'gigabyte') 
    TB = setcustomdisplay(1e12*u.B,'TB') % terabyte
    terabyte = setcustomdisplay(u.TB,'terabyte') 
    PB = setcustomdisplay(1e15*u.B,'PB') % petabyte
    petabyte = setcustomdisplay(u.PB,'petabyte') 
    EB = setcustomdisplay(1e18*u.B,'EB') % exabyte
    exabyte = setcustomdisplay(u.EB,'exabyte') 
    Kibit = setcustomdisplay(2^10*u.bit,'Kibit') % kibibit
    kibibit = setcustomdisplay(u.Kibit,'kibibit') 
    KiB = setcustomdisplay(2^10*u.B,'KiB') % kibibyte
    KB = setcustomdisplay(u.KiB,'KB') % kibibyte
    kibibyte = setcustomdisplay(u.KB,'kibibyte') 
    Mibit = setcustomdisplay(2^20*u.bit,'Mibit') % mebibit
    mebibit = setcustomdisplay(u.Mibit,'mebibit') 
    MiB = setcustomdisplay(2^20*u.B,'MiB') % mebibyte
    mebibyte = setcustomdisplay(u.MiB,'mebibyte') 
    Gibit = setcustomdisplay(2^30*u.bit,'Gibit') % gibibit
    gibibit = setcustomdisplay(u.Gibit,'gibibit') 
    GiB = setcustomdisplay(2^30*u.B,'GiB') % gibibyte
    gibibyte = setcustomdisplay(u.GiB,'gibibyte') 
    Tibit = setcustomdisplay(2^40*u.bit,'Tibit') % tebibit
    tebibit = setcustomdisplay(u.Tibit,'tebibit') 
    TiB = setcustomdisplay(2^40*u.B,'TiB') % tebibyte
    tebibyte = setcustomdisplay(u.TiB,'tebibyte') 
    Pibit = setcustomdisplay(2^50*u.bit,'Pibit') % pebibit
    pebibit = setcustomdisplay(u.Pibit,'pebibit') 
    PiB = setcustomdisplay(2^50*u.B,'PiB') % pebibyte
    pebibyte = setcustomdisplay(u.PiB,'pebibyte') 
    Eibit = setcustomdisplay(2^60*u.bit,'Eibit') % exbibit
    exbibit = setcustomdisplay(u.Eibit,'exbibit') 
    EiB = setcustomdisplay(2^60*u.B,'EiB') % exbibyte
    exbibyte = setcustomdisplay(u.EiB,'exbibyte') 
    bps = setcustomdisplay(u.bit/u.s,'bps') % bit per second
    bitPerSecond = setcustomdisplay(u.bps,'bitPerSecond') 
    kbps = setcustomdisplay(1e3*u.bps,'kbps') % kilobit per second
    kilobitPerSecond = setcustomdisplay(u.kbps,'kilobitPerSecond') 
    Mbps = setcustomdisplay(1e6*u.bps,'Mbps') % megabit per second
    megabitPerSecond = setcustomdisplay(u.Mbps,'megabitPerSecond') 
    Gbps = setcustomdisplay(1e9*u.bps,'Gbps') % gigabit per second
    gigabitPerSecond = setcustomdisplay(u.Gbps,'gigabitPerSecond') 
    Tbps = setcustomdisplay(1e12*u.bps,'Tbps') % terabit per second
    terabitPerSecond = setcustomdisplay(u.Tbps,'terabitPerSecond') 

    %---- currency ----
    % For display purposes - not for exchange rates.
    % See also mathworks.com/matlabcentral/fileexchange/47255

    cent = setcustomdisplay(u.currency/100,'cent') % cent (currency)
    Cent = setcustomdisplay(u.cent,'Cent') % cent (currency)
    pip = setcustomdisplay(u.cent/100,'pip') % pip (currency)
    USD = setcustomdisplay(u.currency,'USD') % currency
    EUR = setcustomdisplay(u.currency,'EUR') % currency
    GBP = setcustomdisplay(u.currency,'GBP') % currency
    JPY = setcustomdisplay(u.currency,'JPY') % currency
    AUD = setcustomdisplay(u.currency,'AUD') % currency
    CAD = setcustomdisplay(u.currency,'CAD') % currency
    CHF = setcustomdisplay(u.currency,'CHF') % currency
    CNY = setcustomdisplay(u.currency,'CNY') % currency
    dollar = setcustomdisplay(u.currency,'dollar') % currency
    franc = setcustomdisplay(u.currency,'franc') % currency

    %---- used by Matlab's symunit but not here ----
    % gg - gauge
    % land - league
    % ha_US - US survey hectare
    % molecule
    % HP_UK - British imperial horsepower
    % PS_SAE - net horsepower (SAE J1349)
    % PS_DIN - horsepower (DIN 70020)
    % dry volumes
end

%% METHODS
methods
    %% Plotting and display:
    function disp(o)
        f = fieldnames(o);
        for iField = 1:length(f)
            thisField = u.(f{iField});
            if isa(thisField,'DimVar')
                thisField = scd(thisField);
            end
            uDisplayStruct.(f{iField}) = thisField;
        end
                
        try    
            dispdisp(uDisplayStrucasdft);
            % mathworks.com/matlabcentral/fileexchange/48637
        catch
            builtin('disp',uDisplayStruct);
            
            url = 'http://www.mathworks.com/matlabcentral/fileexchange/48637/';
            dlCmd = sprintf('matlab:unzip(websave(tempname,''%s%s''),pwd);u',...
                url,'?download=true');
            
            warning('The function <a href="%s">%s</a> %s\n%s',...
                'www.mathworks.com/matlabcentral/fileexchange/48637',...
                'dispdisp',...
                'is recommended for display of physical units.',...
                ['<a href="' dlCmd ...
                '">Direct download of dispdisp into current directory</a>']);
        end
    end
end
end

%% Processing base units.
function U = buildCoreUnits(baseUnitSystem)
coreBaseNames = {'m' 'kg' 's' 'A' 'K' 'mol' 'cd' 'bit' 'currency'};

if ischar(baseUnitSystem) && strcmpi('none',baseUnitSystem)
    % Use normal variables - not DimVars - if baseUnitSystem is 'none'.
    U = cell2struct(num2cell(ones(size(coreBaseNames))),coreBaseNames,2);
    return
end

validateattributes(baseUnitSystem,{'cell'},{'size',[9,2]},'u','baseUnitSystem');

if ~iscellstr(u.baseUnitSystem(:,1))
    error('First column of baseUnitSystem must be type char.')
end

baseValues = baseUnitSystem(:,2);
if ~all(cellfun('isclass', baseValues, 'double'))
    error('Second column of baseUnitSystem must contain doubles.')
end

expos = eye(numel(coreBaseNames));
for i = 1:numel(baseValues)
    U.(coreBaseNames{i}) = DimVar(expos(i,:),baseValues{i});
end
end

% unit checking within definitions of class 'u' impossible. Use another
% function 'setcustomdisplay' in this case, which doesn't check units.
function  v = setcustomdisplay(v,val)
    v = scd(v,val,'no-check');
end

%%
%   Original inspiration for this tool by Rob deCarvalho.
%     http://www.mathworks.com/matlabcentral/fileexchange/authors/22148
%     http://www.mathworks.com/matlabcentral/fileexchange/10070