% Experiment with TouchScreen
% 2020 by Clara Kuper
% check timing

% System setup
% Clear the workspace and the screen
sca;
clear all;
clear mex;
clear functions;

% cursor goes home, command window scrolled up
home;

% Which experiment are we running?
expCode = 'MI';
sprintf('Now running experiment %s',expCode);

% add the functions folder to searchpath and define storage paths
addpath('0_Functions/','1_Data/', '1_edf/');

% Unify keys in case sb codes with a different system
KbName('UnifyKeyNames');

% Here we call some default settings for setting up Psychtoolbox
PsychDefaultSetup(2);

% Init random
rand('seed', sum(100 * clock));

%start a timer for the experiment
tic;

% define some settings for the experiment
global settings visual design;

settings.SYNCTEST = 1; % 1 runs synctest, 0 does not
settings.eye_used = str2double(input('\nWhich eye do we track (0 = left, 1 = right):  ','s'));
settings.TEST = 1;
settings.TYPE = 0; % 0 = jump only, 1 = serial only, 2 = both


% do some general stuff
% get subject code

[datFileJ, datFileS, subCode, subPath] = getSubjectCode(expCode);

% prepare the screens    
setScreens;
                                                                                
% generate design for both parts
genDesign(subCode);

% prepare the stimuli
prepStim;

% Add experiment Info after OpenWindow so it's under the text generated by Screen
fprintf('\nManualInhibition\n');
HideCursor;

% Configure DATAPixx/TOUCHPixx
Datapixx('SetVideoMode', 0);                        % Normal passthrough
Datapixx('EnableTouchpixx');                        % Turn on TOUCHPixx hardware driver
Datapixx('SetTouchpixxStabilizeDuration', 0.01);    % stable coordinates in secs before recognising touch
Datapixx('RegWrRd');

calibrate_touchpixx();


% initialize EyeLink
[el, error] = initEyelink(subCode);

% first calibration
eye_available = Eyelink('EyeAvailable'); % get eye that's tracked

if ~ settings.eye_used == eye_available
    disp('The eye set for tracking does not match the tracked eye.');
    WaitSecs(3);
    ListenChar(1);
    Eyelink('Shutdown');

    ShowCursor;
    Screen('CloseAll');
    expEnd = toc;

    sprintf('This experiment lasted %i minutes', round(expEnd/60,1));
end

disp([num2str(GetSecs) ' Eyelink initialized.']);

% calibrate
calibresult = EyelinkDoTrackerSetup(el);


% Display Instructions:
ListenChar(0);
Eyelink('Message', 'EXPERIMENT STARTED');
DrawFormattedText(visual.window, 'Welcome to the experiment', 'center', 200, visual.textColor);
DrawFormattedText(visual.window, 'Press any key to start', 'center', 'center', visual.textColor);
Screen('Flip',visual.window);
KbPressWait;

% initialize the block names


%% run the two experiments
 b_i = 1;
 for b = 1:design.nBlocks
   
    if design.b(b).type == 'J'
        dataJump.block(b_i) = runBlock(b, b_i, el);
    elseif design.b(b).type == 'S'
        dataSerial.block(b_i) = runBlock(b, b_i, el);
    end
    b_i = b_i+1;
    settings.feedback = 0;

end 

Eyelink('Message', 'EXPERIMENT ENDED');

DrawFormattedText(visual.window, 'Thanks for your participation', 'center', 'center', visual.textColor);
Screen('Flip',visual.window);


% save all the data
dataJumpTable = data2output(dataJump);
dataSerialTable = data2output(dataSerial);
writetable(dataJumpTable, sprintf('./1_Data/%sJump_dat.csv',design.vpcode));
writetable(dataSerialTable, sprintf('./Data/%sSerial_dat.csv',design.vpcode));

save(datFileJ, 'dataJump');
save(datFileS, 'dataSerial');

% save the design
design_table = design2output(design);
writetable(design_table, sprintf('./1_Design/%s_des.csv',design.vpcode));
save(sprintf('./1_Design/%s_design.mat',design.vpcode),'design'); %

Datapixx('DisableTouchpixx');
Datapixx('Close'); %call the close command after closing the screens


Eyelink('CloseFile');

% download data file
WaitSecs(2);

try
    fprintf('Receiving data file ''%s''\n', settings.edffilename);
    status=Eyelink('ReceiveFile',settings.edffilename, 'edf/', 1);
    WaitSecs(2);
    if status > 0
        fprintf('ReceiveFile status %d\n', status);
    end
    if 2==exist(settings.edffilename, 'file')
        fprintf('Data file ''%s'' can be found in ''%s''\n', settings.edffilename, pwd );
        [sucMov,mesMov,messMov] = movefile(settings.edffilename,'edf/','f');

        if ~sucMov
            fprintf('File successfully moved into edf folder.\n');
        end
    end
catch rdf
    fprintf('Problem receiving data file ''%s''\n', settings.edffilename);
    rdf;
end

WaitSecs(2);
Eyelink('Shutdown');


ListenChar(1);

ShowCursor;
expEnd = toc;

fprintf('This experiment lasted %i minutes', round(expEnd/60,0));
sca;
Screen('CloseAll');

% get some values that we want to print (visualize) later
saccades = data_table.t_saccStart;
hand_movements = data_table.t_movStart;
flash = data_table.t_flash;

hmf =  hand_movements - flash;
f_hmf = hmf(hmf > 0.0);
% plot them
figure(1)
histogram(saccades-flash)
title('histogram of saccades')
figure(2)
histogram(f_hmf)
title('histogram of hand movements')