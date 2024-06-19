%INITCOMPPHYSIOL Add compphysiol toolbox to path & initialize databases
%   INITCOMPPHYSIOL only needs to be executed in the following two 
%   situations:
%   
%    - directly after starting MATLAB 
%    - when changing the physiologytemplate or drugtemplate
%   
%   Note that any variable defined in the global workspace will be deleted
%   when calling INITCOMPPHYSIOL, which ensures that the physiology and
%   drug templates can be updated correctly.

function [] = initcompphysiol()
    
    vars = evalin('base','who');
    if ~isempty(vars)
        msg = 'All workspace variables will be cleared. Continue? Y/N [Y]: ';
        str = input(msg,'s');
        if ~startsWith('Y',str,'IgnoreCase',true)
            fprintf('...installation aborted.\n')
            return
        end
    end

    S = dbstack('-completenames');
    basepath = fileparts(S(1).file);
    
    addpath(genpath(fullfile(basepath, 'data')))
    addpath(genpath(fullfile(basepath, 'internal')))
    addpath(genpath(fullfile(basepath, 'models')))

    % prepare updating of database templates
%    evalin('base','clear classes')      % not needed any more?
%    evalin('base','clearvars')          % not needed any more?

    clear pathPBPKtoolbox

    % set project path
    pathPBPKtoolbox(basepath);
    
    fprintf(['\n\n'...
        ' --------------------------------------------------------------- \n'...
        '|         compphysiol: Computational Physiology Toolbox         |\n'...
        '|                                                               |\n'...
        '|             (c) Niklas Hartung, Wilhelm Huisinga              |\n'...
        '|                   University of Potsdam, 2024                 |\n'...
        '|                                                               |\n'...
        '|  The program is distributed under the terms of the            |\n'...
        '|  BSD 2-Clause License (see file license.txt).                 |\n'...
        '|                                                               |\n'...
        ' --------------------------------------------------------------- \n\n\n'])
    
    
    fprintf('Initializing units ... ')
    u;
    gettype(1);
    fprintf('finished.\n\n')
    fprintf('Initializing the physiological database ... ')
    initphysiologydb();
    fprintf('finished.\nThe following reference individuals are defined:\n')
    disp(referenceid()')
    fprintf('Initializing the drug database ... ')
    ddb=initdrugdb();
    fprintf('finished.\nThe following drugs are defined:\n')
    disp({ddb.name}')
    fprintf('Initialization successful.\n')

end
