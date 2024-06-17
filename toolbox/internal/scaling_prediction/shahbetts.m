%SHAHBETTS Shah/Betts prediction of antibody biodistribution coefficients
%   ABC = SHAHBETTS(PHYS, DRUG, ORGANS) predicts antibody biodistribution
%   coefficients ABC using the method from Shah & Betts, mAbs 5:2, 297/305;
%   March/April 2013, Table 1.
%
%   Input: 
%   - a Physiology object PHYS
%   - a DrugData object DRUG of class mAb
%   - a cellstr ORGANS 
%
%   Output:
%   - a struct ABC 

function ABC = shahbetts(phys, drug, organs)

assert(isscalar(phys) && isa(phys,'Physiology'), ...
    'Input #1 must be a scalar Physiology object.')
assert(isscalar(drug) && isa(drug,'DrugData'), ...
    'Input #2 must be a scalar DrugData object.')

assert(ismember(drug.class,{'mAb','pAb','ADC'}),...
    "Shah/Betts method only applicable to monoclonal antibodies.");

I = initcmtidx(organs);

ABC_exp = nan(size(organs(:)));

% values in unit [%], so finally divide by 100 to obtain fractions 
if isfield(I, 'lun');   ABC_exp(I.lun) = 14.9;            end
if isfield(I, 'hea');   ABC_exp(I.hea) = 10.2;            end
if isfield(I, 'kid');   ABC_exp(I.kid) = 13.7;            end
if isfield(I, 'mus');   ABC_exp(I.mus) = 3.97;            end
if isfield(I, 'ski');   ABC_exp(I.ski) = 15.7;            end
if isfield(I, 'gut');   ABC_exp(I.gut) = 1/2*(5.22+5.03); end  % average of small and large intestine
if isfield(I, 'spl');   ABC_exp(I.spl) = 12.8;            end
if isfield(I, 'liv');   ABC_exp(I.liv) = 12.1;            end
if isfield(I, 'bon');   ABC_exp(I.bon) = 7.27;            end
if isfield(I, 'adi');   ABC_exp(I.adi) = 4.78;            end

% convert to fractions
ABC_exp = ABC_exp/100;

%NH Correct for residual blood -- to integrate in a future toolbox version
%
% %%% depending on correction for residual blood, either ABC_exp or 
% %%% corrected ABC values are assigned 
% correct_ABC_for_residual_blood = 0;
% 
% if correct_ABC_for_residual_blood
%     
%     species  = Individual.species;
%     V.vas    = species.V.vas; V.tis = species.V.tis; hct = species.hct;
%     
%     %%% ASSUMPTION: residual blood equal to fac * vascular blood ...
%     fac = 0.20;
%     f_resblo = fac * V.vas ./ (V.vas+V.tis);
%         
%     ABC_tis  = ( ABC_exp - (1-hct)*f_resblo ) ./ (1-f_resblo);  
%             
% else
%     
%     ABC_tis = ABC_exp;
%   
% end;

ABC = ABC_exp;


end

