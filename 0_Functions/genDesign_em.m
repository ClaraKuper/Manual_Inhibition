function genDesign_em(vpcode)
% eye movements only
% 2017 by Martin Rolfs
% 2021 mod by Clara Kuper

global design scr visual

% randomize random
rand('state',sum(100*clock));

design.vpcode    = vpcode;
design.version   = '2tar';

% Timing %
design.fixDur   = 0.5; % Fixation duration till trial starts [s]
design.fixDurJ  = 0.25; % Additional jitter to fixation

design.iti         = 0.2; % Inter stimulus interval
design.wait_to_fix = 2.0;

% response key
% design.response = KbName('space');

% conditions
design.flash = [1,0]; % if there will be a flash (1) or not (0)
design.target = [-1,1]; % left and right target presentation

% target 1
design.tar1Rad = 1;
design.tar1xPos = visual.xCenter; % the first target is always in the screen center
design.tar1yPos = visual.yCenter; 

% target 2
design.tar2Rad = 1;
design.tar2x = 10; % the distance of the second target in dva
design.tar2y = visual.yCenter; 

% timing
design.trialDur = 1; % maximum time to make a response
design.maxgapDur   = 0.2; % time substracted from (saccade) reaction time to get flash time
design.flashTime = 0.1; % the flash lag time in the first trial
design.flashDur = 0.1; % how long the flash will be on the screen

% flash area
design.flashy = 1/3 * scr.yres; % proportion of the screen with a flash
design.flashx = scr.xres;

% touch area
design.rangeAccept = 2;
design.rangeCalib  = 1;

% overall information %
% number of blocks and trials in the first round
design.nBlocks = 5;
design.nTrials = 25; %50 trials per condition and block 
  
% build experimental blocks
for b = 1:design.nBlocks
    t = 0;
    for triali = 1:design.nTrials
        for flash = design.flash
            for tar = design.target
                t = t+1;
                % define the trial condition
                trial(t).flash = flash;
                trial(t).tar2xPos = design.tar2x * tar;
                trial(t).tar2yPos = design.tar2y;
               
                % define a fixation duration
                trial(t).fixDur = design.fixDur + rand() * design.fixDurJ;
                trial(t).gapDur = design.maxgapDur * rand();
            end
        end
    end
    % randomize trials
    r = randperm(t);
    design.b(b).trial = trial(r);
end

blockOrder = [1:b];

design.blockOrder = blockOrder(randperm(length(blockOrder)));
design.nTrialsPB  = t;

% save 
save(sprintf('./Design/%s.mat',vpcode),'design');

end

