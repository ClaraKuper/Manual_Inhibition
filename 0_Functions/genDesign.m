function genDesign(vpcode)
%
% 2017 by Martin Rolfs
% 2021 mod by Clara Kuper

global design scr

% randomize random
rand('state',sum(100*clock));

design.vpcode    = vpcode;

% Timing %
design.fixDur   = 0.5; % Fixation duration till trial starts [s]
design.fixDurJ  = 0.25; % Additional jitter to fixation

design.iti         = 0.2; % Inter stimulus interval
design.wait_to_fix = 2.0;

% response key
% design.response = KbName('space');

% conditions
design.flash = [1,0]; % if there will be a flash (1) or not (0)

% target 1
design.tar1Rad = 1;
design.tar1xCov = 0.6; % the part of the screen where the targt can appear
design.tar1yCov = 0.6; % the part of the screen where the targt can appear

% target 2
design.tar2Rad = 1;
design.tar2xCov = 0.6; % the part of the screen where the targt can appear
design.tar2yCov = 0.6; % the part of the screen where the targt can appear

% timing
design.trialDur = 1; % maximum time to make a response
design.gapDur   = 0.05; % gap before flash
design.flashTime = 0.1; % the flash lag time in the first trial
design.flashDur = 0.05; % how long the flash will be on the screen

% flash area
design.flashy = 1/3 * scr.yres; % proportion of the screen with a flash
design.flashx = scr.xres;

% touch area
design.rangeAccept = 2;
design.rangeCalib  = 1;

% overall information %
% number of blocks and trials in the first round
design.nBlocks = 5;
design.nTrials = 50; %50 trials per condition and block 
  
% build experimental blocks
for b = 1:design.nBlocks
    t = 0;
    for triali = 1:design.nTrials
        for flash = design.flash
            t = t+1;
            % define the trial condition
            trial(t).flash = flash;
            % define the x and y position of both targets
            trial(t).tar1xPos = scr.xres * ((1 - design.tar1xCov)/2) + (scr.xres - scr.xres * (1 - design.tar1xCov)) * rand(); 
            trial(t).tar1yPos = scr.yres * ((1 - design.tar1yCov)/2) + (scr.yres - scr.yres * (1 - design.tar1yCov)) * rand(); 
            trial(t).tar2xPos = scr.xres * ((1 - design.tar2xCov)/2) + (scr.xres - scr.xres * (1 - design.tar2xCov)) * rand();
            trial(t).tar2yPos = scr.yres * ((1 - design.tar2yCov)/2) + (scr.yres - scr.yres * (1 - design.tar2yCov)) * rand(); 
            
            % define a fixation duration
            trial(t).fixDur = design.fixDur + rand() * design.fixDurJ;
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

