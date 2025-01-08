function mustBeSmallMolecule(drug)

    if ~isa(drug,'DrugData') || ~strcmp(drug.class,'sMD')
        eid = 'DrugData:notSmallMolecule';
        msg = 'Input must be a small molecule drug.';
        error(eid,msg)
    end
end