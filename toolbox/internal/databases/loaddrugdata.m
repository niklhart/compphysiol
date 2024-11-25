%LOADDRUGDATA Load drug data for a (set of) compound(s).
%   DRUGDATA = LOADDRUGDATA(COMPOUNDS), with a character array / cellstr 
%   COMPOUNDS, accesses the drug database and returns the information as a 
%   DRUGDATA (array).
%
%   Examples:
%       % Access a single  drug
%       loaddrugdata('Warfarin')
%
%       % Access multiple drugs
%       loaddrugdata({'Amitriptyline','Warfarin'})
%
%       % Access a drug based on a Dosing object
%       dosing = Bolus('Warfarin',0*u.h,10*u.mg,'iv');
%       loaddrugdata(compounds(dosing))
function drugdata = loaddrugdata(compounds, varargin)

    ddb = DrugDB.Instance;

    compounds = cellstr(compounds);
    drugdata = copy(ddb{compounds{:}});
                
    if nargin > 1
        filtervariants(drugdata,varargin{:});
    end

end