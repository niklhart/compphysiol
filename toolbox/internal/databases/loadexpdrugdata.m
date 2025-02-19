%LOADEXPDRUGDATA Load drug data for a (set of) compound(s).
%   ED = LOADEXPDRUGDATA(COMPOUNDS), with a character array / cellstr 
%   COMPOUNDS, accesses the experimental drug database and returns the 
%   information as an ExpDrugData object/array ED.
%
%   Examples:
%       % Access a single  drug
%       loadexpdrugdata('Warfarin')
%
%       % Access multiple drugs
%       loadexpdrugdata({'Warfarin','Warfarin'})
%
%       % Access a drug based on a Dosing object
%       dosing = Bolus('Warfarin',0*u.h,10*u.mg,'iv');
%       loadexpdrugdata(compounds(dosing))
function eD = loadexpdrugdata(compounds, varargin)

    ddb = getoptcompphysiol('ExpDrugDBhandle');
    compounds = cellstr(compounds);
    eD = copy(ddb{compounds{:}});
                
    if nargin > 1
        filtervariants(eD,varargin{:});
    end

end