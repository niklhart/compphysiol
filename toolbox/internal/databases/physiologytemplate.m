%PHYSIOLOGYTEMPLATE Template for physiological parameters with metadata 
%   PHYSIOLOGYTEMPLATE is a customizable template to define the type of
%   physiological parameters that may be added to the physiology database. 
%   
%   Note that in order for a change in PHYSIOLOGYTEMPLATE to take effect,
%   function 'initPBPKtoolbox' must be re-run, and that this clears all
%   variables from the global workspace.
%
%   PARAMS = PHYSIOLOGYTEMPLATE() returns a N-by-4 cell array PARAMS. Every 
%   row corresponds to a physiological parameter and must have the 
%   following form:
%   
%       {<name> <unit type> <per tissue> <description>}
%   
%   - <name> specifies the parameter name (a char)
%   - <unit type> specifies the unit type of the parameter (a char; see
%       typecheck() for possible values)
%   - <per tissue> is a boolean specifying whether the parameter is scalar
%       (false) or a per-tissue parameter (true)
%   - <description> is a descriptive text (character array) that can be
%       displayed with function about()
%
%   The following naming convention is used for composite parameters:
%   - parameters specifying a particular subtype of a main parameter have
%   the form <MAIN TYPE><subtype>, e.g. Vtis for tissue volume.
%   - parameters specifying a fraction of a particular type have the form
%   	f<what><OF WHAT>, like fuP for fraction unbound in plasma.
%
%   See also initphysiologydb, Physiology, typecheck, about, 
%   initPBPKtoolbox

function params = physiologytemplate()

%  Parameter      Unit type     Per tissue?  Description          
params = {
    'species'     'char'           false    'Species of individual' 
    'type'        'char'           false    'Type of individual (race or strain)' 
    'sex'         'char'           false    'Sex of individual' 

    'age'         'Time'           false    'Age of individual'
    'BH'          'Length'         false    'Body height'  
    'BW'          'Mass'           false    'Body weight'  
    'LBW'         'Mass'           false    'Lean body weight'  
    'BMI'         'Mass/Area'      false    'Body mass index'  
    'BSA'         'Area'           false    'Body surface area'  
    
    'fowtisBW'    'unitless'       true     'Tissue organ weight fraction of body weight'    
    'ftblBW'      'unitless'       false    'Total blood volume (incl regional blood) fraction of body weight'

    'hct'         'unitless'       false    'Hematocrit (cellular fraction of blood volume)'
    'pH'          'unitless'       true     'pH value (acidity of a physiological liquid)'  

    'OWtis'       'Mass'           true     'Tissue organ weight (without residual blood)'  
    'OWtot'       'Mass'           true     'Total organ weight (including vascular part)' 
    'OWrbt'       'Mass'           true     'Organ tissue weight including residual blood' 
    'OWtbl'       'Mass'           false    'Total blood weight (including regional blood)'

    'fcelOWtot'   'unitless'       true     'Cellular fraction of total organ weight'  
    'fintOWtot'   'unitless'       true     'Interstitial fraction of total organ weight'  
    'fvasOWtot'   'unitless'       true     'Vascular fraction of total organ weight'  
    'fresOWrbt'   'unitless'       true     'Residual blood fraction of tissue organ weight with residual blood' 
    'fcelOWtis'   'unitless'       true     'Cellular fraction of tissue organ weight'  
    'fintOWtis'   'unitless'       true     'Interstitial fraction of tissue organ weight'
    'faphOWtis'   'unitless'       true     'Intercellular acidic phospholipid fraction of tissue organ weight'
    
    'dens'        'Mass/Volume'    true     'Density'   

    'Vtot'        'Volume'         true     'Total volume of an organ (including vascular part)'   
    'Vtis'        'Volume'         true     'Tissue volume of an organ (without residual blood)'   
    'Vvas'        'Volume'         true     'Vascular volume of an organ'   
    'Vres'        'Volume'         true     'Residual blood volume of an organ'  
    'Vtbl'        'Volume'         false    'Total blood volume (including regional blood)'
 
    'fcelVtot'    'unitless'       true     'Cellular fraction of total organ volume'  
    'fintVtot'    'unitless'       true     'Interstitial fraction of total organ volume'  
    'fvasVtot'    'unitless'       true     'Vascular fraction of total organ volume'  
    'fcelVtis'    'unitless'       true     'Cellular fraction of tissue organ volume'  
    'fintVtis'    'unitless'       true     'Interstitial fraction of tissue organ volume'
    'fnliVtis'    'unitless'       true     'Neutral lipid fraction of tissue organ volume'
    'fnphVtis'    'unitless'       true     'Neutral phospholipid fraction of tissue organ volume'
    'faphVtis'    'unitless'       true     'Acidic phospholipid fraction of tissue organ volume'
    'fwecVtis'    'unitless'       true     'Extracellular water fraction of tissue organ volume'  
    'fwicVtis'    'unitless'       true     'Intracellular water fraction of tissue organ volume'
    'fwtotVtis'   'unitless'       true     'Total water fraction of tissue organ volume'
    'fwecVrbt'    'unitless'       true     'Extracellular water fraction of tissue organ volume with residual blood'  
    'fwicVrbt'    'unitless'       true     'Intracellular water fraction of tissue organ volume with residual blood'      
    'fregVtbl'    'unitless'       true     'Regional peripheral blood fraction of total blood volume'  
    'fartVtbl'    'unitless'       false    'Arterial fraction of total blood volume'  
    'fvenVtbl'    'unitless'       false    'Venous fraction of total blood volume'  
        
    'rtpAlb'      'unitless'       true     'Tissue-to-plasma ratio of albumin'   
    'rtpLip'      'unitless'       true     'Tissue-to-plasma ratio of lipoprotein'     

    'co'          'Volume/Time'    false    'Cardiac output'   
    'fqbloCO'     'unitless'       true     'Blood flow fraction of cardiac output'    
    'Qblo'        'Volume/Time'    true     'Blood flow'   
    'GFR'         'Volume/Time'    false    'Glomerular filtration rate'
};

end

