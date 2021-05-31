function genDesign(vpcode)
% eye movements only
% 2017 by Martin Rolfs
% 2021 mod by Clara Kuper

global design scr visual settings

% set values that generalize across both parts
% randomize random
rand('state',sum(100*clock));

% general experiment info
design.vpcode    = vpcode;
if settings.TYPE == 0
    design.trialType = 'J';
elseif settings.TYPE == 1
    design.trialType = 'S';
elseif settings.TYPE == 2
    design.trialType = ['J', 'S'];
end

design.leaveKey  = KbName('escape');
design.fixKey    = KbName('space');

% timing
design.iti       = 0.2; % Inter trial interval
design.waitToFix = 2.0;
design.mean_rea  = 0.3; % setting a value from where we compute the mean reaction time
design.flashTime = 0.1; % the flash lag time in the first trial
design.flashDur  = 0.1; % how long the flash will be on the screen
design.trialDur  = 10; % maximum time to make a response in sec

% stimulus design specifics
design.tarRad = 1; % diameter of target in dva

% flash design
design.flashy = 1/3 * scr.yres; % proportion of the screen with a flash
design.flashx = scr.xres;

% touch area
design.rangeAccept = 2;
design.rangeCalib  = 1;

% set values specific to the JUMP part
% timing
design.jFixDur   = 0.5; % Fixation duration till trial starts [s]
design.jFixDurJ  = 0.25; % Additional jitter to fixation
design.jGapDur   = 0.11; % When the dot jumps a second time
design.jGapDurJitter = 0.1; % jitter when the dot will jump a second time  

% conditions
design.jFlash = [1,0]; % if there will be a flash (1) or not (0)
design.jTarget = [-10,10]; % left and right target presentation
design.jShift = [-1,0,1]; % the target can be shifted inwards, outwards or not at all

% the target
design.jShiftSize = 1;
design.jTarxPos = visual.xCenter; % the first target is always in the screen center
design.jTaryPos = visual.yCenter; 

% set values specific to the SERIAL part
% target series
design.sTarN        = 6; % how many dots there will be in the target sequence
design.sTarRadTouch = 1; % how large the target will be after it was touched
design.sTarxPos     = linspace(-10,10,design.sTarN); % the positions of the serial targets
design.sTaryPos     = repelem(visual.yCenter, design.sTarN); % a vector with the y positions ofthe same length

% flash information
design.sFlashN  = 1; % number of flashes that can appear in a serial trial
design.sFlashOn = linspace(0,1,design.sTarN);

% overall information %
% number of blocks and trials
design.nBlocks = 2; % number of blocks per condition
design.nTrialsCond = 5; % the total number of trials per condition in each block
  
% build experimental blocks
b = 0;

% preallocate design structures
jTotalTrialN = design.nTrialsCond * length(design.jFlash) * length(design.jTarget) * length(design.jShift);
sTotalTrialN = design.nTrialsCond * design.sTarN;

design.b = struct('trial', cell(1, 4));
for type = design.trialType
    for block = 1:design.nBlocks
        b = b+1;
        t = 0;
        if type == 'J'
            trial = struct('flash', cell(1, jTotalTrialN), 'tarxPos', cell(1, jTotalTrialN), 'taryPos', cell(1, jTotalTrialN), 'shiftxPos', cell(1, jTotalTrialN), 'shiftyPos', cell(1, jTotalTrialN), 'fixDur', cell(1, jTotalTrialN), 'gapDur', cell(1, jTotalTrialN));            
            for triali = 1:design.nTrialsCond
                for flash = design.jFlash
                    for tar = design.jTarget
                        for shift = design.jShift
                            t = t+1;
                            shift = shift * design.jShiftSize;
                            % define the trial condition
                            trial(t).flash     = flash;
                            trial(t).tarJumpPos= tar;
                            trial(t).tarShiftPos = tar + shift;
                            
                            % define a fixation duration
                            trial(t).fixDur = design.jFixDur + rand() * design.jFixDurJ;
                            trial(t).gapDur = design.jGapDur + ((rand()-0.5)*design.jGapDurJitter*2);
                        end
                    end
                end
            end
            
        elseif type == 'S'
            trial = struct('flashon', cell(1, sTotalTrialN));            
            for triali = 1:design.nTrialsCond
                for flashon = design.sFlashOn
                    t = t+1;
                    % define the trial condition
                    trial(t).flashn = flashon;
                end
            end
        end
        
        % randomize trials
        r = randperm(t);
        design.b(b).trial = trial(r);
        design.b(b).type = type;
        clear trial;
    end
end

blockOrder = [1:b];

design.blockOrder = blockOrder(randperm(length(blockOrder)));
design.b          = design.b(design.blockOrder); 
design.nTrialsPB  = t;

% save 
save(sprintf('./1_Design/%s.mat',vpcode),'design');

end

