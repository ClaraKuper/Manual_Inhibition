function trialData  = runSingleTrial_random(trial, design, visual, settings)

    ListenChar(0);

    Datapixx('SetTouchpixxLog');                                    % Configure TOUCHPixx logging with default buffer
    Datapixx('EnableTouchpixxLogContinuousMode');                   % Continuous logging during a touch. This also gives you long output from buffer reads
    Datapixx('StartTouchpixxLog');
    
    t_initPixx = Datapixx('GetTime');  % Save when the DataPixx Log was initiated

    % prepare the trial
    % set stimuli
    tar1pos = [trial.tar1xPos, trial.tar1yPos];
    tar2pos = [trial.tar2xPos, trial.tar2yPos];
    
    % set the flash      
    flashPos_up     = [0, 0, design.flashx, design.flashy];
    flashPos_low    = [0, visual.winHeight-design.flashy, design.flashx, visual.winHeight];
       
    % Initialize timing and monitoring parameters
    on_fix_hand    = false;
    time_to_fix = true;
    trial_on  = true;
    rt_timer  = 0;
    flash_on_screen = 0;

    % timing
    t_start    = NaN;  % the trial has started
    t1_draw    = NaN;  % the first stimulus was on screen
    t2_draw    = NaN;  % the second stimulus was on screen
    t_fixed    = NaN;  % check if the hand was on the start position 
    t_flash    = NaN;  % the time when the flash was shown
    t_movStart = NaN;  % the hand movement started
    t_movEnd   = NaN;  % the movements ended
    t_feedback = NaN;  % feedback was on screen
    t_end      = NaN;  % the trial is over
    resp_X     = NaN;  % response touch x
    resp_Y     = NaN;  % response touch Y
    
    % per default, the trial is a success :)
    trial_succ = 1;
    
    % Run the trial. Display the goal and a moving ball
    Datapixx('RegWrRd');
    t_start = Datapixx('GetTime'); 
	
    Screen('DrawDots', visual.window, tar1pos, visual.tar1Rad, visual.black, [], 2); % first target
    Screen('Flip', visual.window);
    Datapixx('RegWrRd');
    t1_draw = Datapixx('GetTime');

    % while the finger is not yet on the starting position, monitor for that
    while ~ on_fix_hand
        
        Datapixx('RegWrRd');
        status = Datapixx('GetTouchpixxStatus');
        
        % Check for events on touchpixx
        if status.newLogFrames                                              % something new happened
            [touches, ~] = Datapixx('ReadTouchpixxLog');
            touch_X = visual.mx*touches(1,status.newLogFrames)+visual.bx;   % Convert touch to screen coordinates
            touch_Y = visual.my*touches(2,status.newLogFrames)+visual.by;   % We use the one-before-last available touch information
            Datapixx('RegWrRd');
            
            % check if the detected touch was in the target box
            if ~ tar1pos(1) - visual.rangeAccept < touch_X && touch_X < tar1pos(1) + visual.rangeAccept &&...
                    tar1pos(2) - visual.rangeAccept < touch_Y && touch_Y < tar1pos(2) + visual.rangeAccept
               t_fixed    = Datapixx('GetTime');                    % we want a time tag when the first target was touched
               on_fix_hand      = true;
            end
        end
        
        time_passed = Datapixx('GetTime') - t2_draw;
        
        if time_passed > design.wait_to_fix
            time_to_fix = false;
            break
        end
        
        % fraw stimuli again and flip
        Screen('DrawDots', visual.window, tar1pos, visual.tar1Rad, visual.black, [], 2); % first target
        Screen('Flip', visual.window);
        Datapixx('RegWrRd');
    end
    
    Datapixx('RegWrRd');
    WaitSecs(trial.fixDur);
    
    % let the first target disappear, show the second
    % monitor time to show a flash when in the right condition
    % get time stamp when the first target was released
    % get time stamp when the first target was touched
    Datapixx('RegWrRd');
    
    trial_timer = 0;
    while trial_timer <= design.trialDur
        
        % draw the second target
        Screen('DrawDots', visual.window, tar2pos, visual.tar2Rad, visual.black, [], 2); % first target
        % draw flash in some conditions
        if trial.flash && trial_timer >= design.flashTime && flash_on_screen < visual.flashFlips
            % Draw the flash
            Screen('FillRect', visual.window, visual.flashcolor, flashPos_up);
            Screen('FillRect', visual.window, visual.flashcolor, flashPos_low);
            % get the flash timing
            if isnan(t_flash)
                t_flash = Datapixx('GetTime');
            end
            % monitor the flash duration
            flash_on_screen = flash_on_screen+1;
        end
        
        % get everything on screen
        Screen('Flip', visual.window);
        Datapixx('RegWrRd');
        
        if isnan(t2_draw) % set time stamp the first time this is executed
            t2_draw = Datapixx('GetTime');
        end
        
        % Get the touchpixx status
        Datapixx('RegWrRd');
        status = Datapixx('GetTouchpixxStatus');
                
        % Check for touchpixx releases
        if ~status.isPressed && isnan(t_movStart)
            Datapixx('RegWrRd');
            t_movStart =  Datapixx('GetTime');
        end
        
        % Check for new touches
        if status.newLogFrames && ~isnan(t_movStart) && isnan(t_movEnd)                                            % something new happened
            [touches, ~] = Datapixx('ReadTouchpixxLog');
            touch_X = visual.mx*touches(1,status.newLogFrames)+visual.bx;   % Convert touch to screen coordinates
            touch_Y = visual.my*touches(2,status.newLogFrames)+visual.by;   % We use the one-before-last available touch information
            Datapixx('RegWrRd');
            
            % check if movement reached the target box
            if tar2pos(1) - visual.rangeAccept < touch_X && touch_X < tar2pos(1) + visual.rangeAccept &&...
               tar2pos(2) - visual.rangeAccept < touch_Y && touch_Y < tar2pos(2) + visual.rangeAccept
               t_movEnd    = Datapixx('GetTime');                    % we want a time tag when the target was touched for the first time
               resp_X      = touch_X;
               resp_Y      = touch_Y;
            end
        end
        
        % update the trial timer
        trial_timer = Datapixx('GetTime') - t2_draw;
    end
    
    Datapixx('RegWrRd');
    t_end  = Datapixx('GetTime');
    Datapixx('StopTouchpixxLog');  

    rea_time = t_movStart - t2_draw;
    mov_time = t_movEnd - t_movStart; 
    
    if rea_time > 0.4 || rea_time < 0.1
        clean_rea = NaN;
    else
        clean_rea = rea_time;
    end
    
    % present feedback
    if ~time_to_fix || isnan(t_movEnd)
        DrawFormattedText(visual.window, 'Too slow', 'center', 'center', visual.textColor);
        trial_succ = 0;
    else
        rt_message = sprintf('Reaction Time: %.3f seconds', rea_time);
        DrawFormattedText(visual.window,  rt_message, 'center', 'center', visual.textColor);
        trial_succ = 1;
    end
    
    Screen('Flip', visual.window);
    t_feedback = Datapixx('GetTime');
    WaitSecs(1.5);
    trialData.id = settings.id;
    trialData.success         = trial_succ;                                 % 1 = success 
                                                                            % 0 = unknown error
    trialData.rea_time        = rea_time;
    trialData.clean_rea       = clean_rea;
    trialData.mov_time        = mov_time;
    trialData.initPixx        = t_initPixx;
    trialData.t_start         = t_start;
    trialData.t1_draw         = t1_draw;
    trialData.t2_draw         = t2_draw;
    trialData.t_fixed         = t_fixed;
    trialData.t_flash         = t_flash;
    trialData.t_movStart      = t_movStart;
    trialData.t_movEnd        = t_movEnd;
    trialData.t_feedback      = t_feedback;
    trialData.t_end           = t_end;
    trialData.mean_rt         = design.flashTime;
    trialData.touchX          = resp_X;
    trialData.touchY          = resp_Y;

    WaitSecs(design.iti);
end