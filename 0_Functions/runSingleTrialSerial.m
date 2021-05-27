function trialData  = runSingleTrialSerial(trial, visual, scr)
    
    global settings design
    
    ListenChar(0);

    Datapixx('SetTouchpixxLog');                                    % Configure TOUCHPixx logging with default buffer
    Datapixx('EnableTouchpixxLogContinuousMode');                   % Continuous logging during a touch. This also gives you long output from buffer reads
    Datapixx('StartTouchpixxLog');
    
    Datapixx('RegWrRd');
    t_initPixx = Datapixx('GetTime');  % Save when the DataPixx Log was initiated

    Eyelink('StartRecording');
    
    % prepare the trial
    % set stimuli
    
    targetX = trial.seriesxPos * visual.ppd + visual.xCenter;
    targetY = trial.seriesyPos;
    
    targets = [targetX; targetY];
    targetsize = repelem(visual.tar1Rad, design.tarSn);
    
    % t1_range
    tar1x_range = [targetX(1)-visual.rangeAccept, targetX(1)+visual.rangeAccept];
    tar1y_range = [targetY(1)-visual.rangeAccept, targetY(1)+visual.rangeAccept];
    
    % define a range where targets can be touched
    tarsx_range = [targetX(1)-visual.rangeAccept, targetX(end)+visual.rangeAccept];
    tarsy_range = [targetY(1)-visual.rangeAccept, targetY(end)+visual.rangeAccept];
    
    % Draw stuff on Eyelink:
    Eyelink('command',sprintf('draw_box %d %d %d %d 15', tar1x_range(1), tar1y_range(1), tar1x_range(2), tar1y_range(2)));
    Eyelink('command',sprintf('draw_box %d %d %d %d 15', tarsx_range(1), tarsy_range(1), tarsx_range(2), tarsy_range(2)));
     
    % set the flash      
    flashPos_up     = [0, 0, design.flashx, design.flashy];
    flashPos_low    = [0, visual.winHeight-design.flashy, design.flashx, visual.winHeight];
    
    % set flash timing
    flashTimes = trial.flashtimes * scr.hz;
    % add a last flash Time that will never be executed
    flashTimes(end+1) = -1;
    
    % set the number which flash will be drawn
    flashn = 1;
       
    % Initialize timing and monitoring parameters
    trial_on  = true;
    on_fix_hand = false;
    on_fix_eye = false;
    flash_on_screen = 0;
    flip_count = 0;
    touch_state = NaN; % monitor if the hand is on the screen or not

    % timing
    t_start      = NaN;  % the trial has started
    t_draw       = NaN;  % the all stimuli were on screen
    t_inloop     = NaN;  % start counting when we are in the timing critical loop
    t_handfixed  = NaN;
    t_eyesfixed  = NaN;
    t_bothfixed  = NaN;
    t_touchDown  = [];  % list of touches 
    t_touchUp    = [];  % list of lifts
    x_touchDown  = [];  % list of X position of touches
    y_touchDown  = [];  % list of Y position of touches
    x_touchUp    = [];  % list of X position of lifts
    y_touchUp    = [];  % list of Y position of lifts
    ID_touchDown = [];  % dot ID of a touch
    ID_touchUp   = [];  % dot ID of a lift
    t_flashOn    = [];  % a list of all flash onsets
    t_flashOff   = [];  % a list of all flash offsets 
    t_feedback   = NaN;  % feedback was on screen
    t_end        = NaN;  % the trial is over
    seq_dur      = NaN;  % the time it took to finish the full sequence
    
    % per default, the trial is a success :)
    trial_succ = 1;
    fixation_break = false;
    time_to_fix = true;
    draw_flash = false;
    final_flip = false;
    
    % Run the trial. Display the start point, get information about timing
    Datapixx('RegWrRd');
    t_start = Datapixx('GetTime'); 
    Eyelink('Message', sprintf('TRIAL_START_%i', settings.id));
    Eyelink('Message', 'TRIAL_SYNCTIME');
	
    Screen('DrawDots', visual.window, targets, targetsize, visual.black, [], 2); % draw all targets
    Screen('Flip', visual.window);
    Datapixx('RegWrRd');
    t_draw = Datapixx('GetTime');
    Eyelink('Message', 'TAR_ON_SCREEN');

    % while the finger is not yet on the starting position, monitor for that
    while ~ on_fix_hand || ~ on_fix_eye
        
        Datapixx('RegWrRd');
        status = Datapixx('GetTouchpixxStatus');
        
        % Check for events on touchpixx
        if status.newLogFrames                                              % something new happened
            [touches, ~] = Datapixx('ReadTouchpixxLog');
            touch_X = visual.mx*touches(1,status.newLogFrames)+visual.bx;   % Convert touch to screen coordinates
            touch_Y = visual.my*touches(2,status.newLogFrames)+visual.by;   % We use the one-before-last available touch information
            
            % check if the detected touch was in the target box
            if inpolygon(touch_X, touch_Y, tar1x_range, tar1y_range)
               Datapixx('RegWrRd');
               t_handfixed    = Datapixx('GetTime');                    % we want a time tag when the first target was touched
               t_touchDown(end+1) = t_handfixed;
               Eyelink('Message', 'HAND_FIX');
               on_fix_hand      = true;
               touch_state            = true; % hand is on screen
            end
        end
        
        if Eyelink('NewFloatSampleAvailable') > 0
            % get the sample in the form of an event structure
            evt = Eyelink('NewestFloatSample');
            % if we do, get current gaze position from sample
            x = evt.gx(settings.eye_used+1); % +1 as we're accessing MATLAB array
            y = evt.gy(settings.eye_used+1);
            
            % do we have valid data and is the pupil visible?
            if  inpolygon(x, y, tar1x_range, tar1y_range) && ~ on_fix_eye
                on_fix_eye = true; % get out of monitioring loop
                Datapixx('RegWrRd');
                t_eyesfixed = Datapixx('GetTime'); % save time to data
                Eyelink('Message', 'EYES_FIX'); % save time to eyelink 
            end
        end
        
        Datapixx('RegWrRd');
        time_passed = Datapixx('GetTime') - t_draw;
        
        if time_passed > design.wait_to_fix
            time_to_fix = false;
            trial_on = false;
        end
        
        % draw stimuli again and flip
        Screen('DrawDots', visual.window, targets, targetsize, visual.black, [], 2); % draw all targets
        Screen('Flip', visual.window);
    end
    
    Datapixx('RegWrRd');
    t_bothfixed = Datapixx('GetTime');
    Eyelink('Message', 'BOTH_FIX');
    
    % let the first target disappear, show the second
    % monitor time to show a flash when in the right condition
    % get time stamp when the first target was released
    % get time stamp when the first target was touched
    
    while trial_on
        
        % draw everything
        Screen('DrawDots', visual.window, targets, targetsize, visual.black, [], 2); % draw all targets
        
        % define if this is a block where we want to draw a flash
        draw_flash = all(flip_count>= flashTimes(flashn) & flip_count<= flashTimes(flashn)+visual.flashFlips);
      
        % draw the flash conditionally
        if draw_flash
            
            % Draw the flash
            Screen('FillRect', visual.window, flashcolor, flashPos_up);
            Screen('FillRect', visual.window, flashcolor, flashPos_low);
            
            % get the flash timing
            Datapixx('RegWrRd');
            if isempty(t_flashOn)
                % get the flash timing
                t_flashOn(end) = Datapixx('GetTime');
                Eyelink('Message', 'FLASH_ON_SCREEN');
            end
            
            t_flashOff(end) = Datapixx('GetTime');
            %Eyelink('Message', 'FLASH_OFF_SCREEN');
        end
        
        % get everything on screen
        [VBLTimestamp, StimulusOnsetTime, FlipTimestamp, ~, ~] = Screen('Flip', visual.window);
        flip_count = flip_count+1;
        Datapixx('RegWrRd');
        
        if isnan(t_inloop) % set time stamp the first time this is executed
            t_inloop = FlipTimestamp;
            Eyelink('Message', 'IN_LOOP');
        end
        
        % Get the touchpixx status
        Datapixx('RegWrRd');
        status = Datapixx('GetTouchpixxStatus');
        
        % status        
        % Check for touchpixx releases
        if ~status.isPressed && touch_state
            
            % get the log data corresponding to the status
            % [touches, ~] = Datapixx('ReadTouchpixxLog');
            
            % convert touches to screen coordinates
            % touch_X = visual.mx*touches(1,status.newLogFrames)+visual.bx;   % Convert touch to screen coordinates
            % touch_Y = visual.my*touches(2,status.newLogFrames)+visual.by;
            
            % refresh the time
            Datapixx('RegWrRd');
            % save the release time
            t_touchUp(end+1) =  Datapixx('GetTime');
            
            % send message to eyelink
            Eyelink('Message', 'HAND_MOVED');
            
            % save the release coordinates
            % x_touchUp(end+1) = touch_X;
            % y_touchUp(end+1) = touch_Y;
            
            % find out which button was the closest to the press
            % dist = abs(targetX-touch_X);
            % touchedT = find(dist == min(dist));
            
            % save the touched button to output
            % ID_touchUp(end+1) = touchedT;
            
            % set the touch state
            touch_state = false;
  
        
        % if the screen is not currently touched
        % check if the screen was freshly touched
        elseif status.newLogFrames && ~touch_state                                    % something new happened
            
            [touches, ~] = Datapixx('ReadTouchpixxLog');
            
            touch_X = visual.mx*touches(1,status.newLogFrames)+visual.bx;   % Convert touch to screen coordinates
            touch_Y = visual.my*touches(2,status.newLogFrames)+visual.by;   % We use the one-before-last available touch information
            
            Datapixx('RegWrRd');
            
            % check if movement reached the target box
            if inpolygon(touch_X, touch_Y, tarsx_range, tarsy_range)
    
               t_touchDown(end+1) = Datapixx('GetTime');                    % we want a time tag when the target was touched for the first time
               Eyelink('Message', 'HAND_LANDED');
               x_touchDown(end+1)      = touch_X;
               y_touchDown(end+1)      = touch_Y;
               
               % find out which button was the closest to the press
               dist = abs(targetX-touch_X);
               
               touchedT = find(dist == min(dist));
               ID_touchDown(end+1) = touchedT;
               
               % and decrease the size of that guy
               targetsize(touchedT) = visual.tarTRad;
                           
               % set the state to finger on screen
               touch_state = true;
               
            end
        end
        
        % Check for eye movements
        % get gaze position to check if it's on screen
        if Eyelink('NewFloatSampleAvailable') > 0
            evt = Eyelink('NewestFloatSample');

            if evt.pa(settings.eye_used+1) < 1 % is the pupil visible?
                fixation_break = true;
                Eyelink('Message', 'FIXATION_BREAK');
            end
        end
        
        % Check if we still want to run the trial
        if flip_count >= visual.trialFlips || fixation_break || all(targetsize == visual.tarTRad)
            
            % show some last flip            
            if final_flip
                trial_on = false;
                Datapixx('RegWrRd');
                t_end  = Datapixx('GetTime');
                Eyelink('Message', sprintf('TRIAL_END_%i', settings.id));
                Datapixx('StopTouchpixxLog');
                WaitSecs(0.7);
            end
            
            final_flip = true;
        end
        
    end
    
    % present feedback
    if fixation_break
        DrawFormattedText(visual.window, 'Do not blink', 'center', 'center', visual.textColor);
        trial_succ = 0;
        settings.FIXBREAK = settings.FIXBREAK +1;

    elseif ~all(targetsize == visual.tarTRad)
        DrawFormattedText(visual.window, 'Too slow', 'center', 'center', visual.textColor);
        trial_succ = 0;
 
    else
        rt_message = sprintf('Well Done');
        DrawFormattedText(visual.window,  rt_message, 'center', 'center', visual.textColor);
        trial_succ = 1;
    end
    
    Screen('Flip', visual.window);
    Datapixx('RegWrRd');
    t_feedback = Datapixx('GetTime');
    Eyelink('Message', 'FEEDBACK_PRESENTED');
    Eyelink('StopRecording');
    WaitSecs(1.5);
    trialData.id = settings.id;
    trialData.success         = trial_succ;                                 % 1 = success 
                                                                            % 0 = unknown error                                                                          
    trialData.initPixx        = t_initPixx;
    trialData.t_start         = t_start;
    trialData.t_draw          = t_draw;
    trialData.t_inloop        = t_inloop;
    trialData.t_handfixed     = t_handfixed;
    trialData.t_eyesfixed     = t_eyesfixed;
    trialData.t_bothfixed     = t_bothfixed;
    trialData.t_touchDown     = t_touchDown;
    trialData.t_touchUp       = t_touchUp;
    trialData.x_touchDown     = x_touchDown;
    trialData.y_touchDown     = y_touchDown;
    trialData.x_touchUp       = x_touchUp;
    trialData.y_touchUp       = y_touchUp;
    trialData.ID_touchDown    = ID_touchDown;
    trialData.ID_touchUp      = ID_touchUp;
    trialData.t_flashOn       = t_flashOn;
    trialData.t_flashOff      = t_flashOff;
    trialData.t_feedback      = t_feedback;
    trialData.t_end           = t_end;
    trialData.version         = 'serial';
    
    Eyelink('command', 'clear_screen 0');
    WaitSecs(design.iti);
end