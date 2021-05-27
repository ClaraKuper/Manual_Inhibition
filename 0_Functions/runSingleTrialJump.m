function trialData  = runSingleTrialJump(trial, visual, scr)
    
    global design settings
    
    ListenChar(0);

    Datapixx('SetTouchpixxLog');                                    % Configure TOUCHPixx logging with default buffer
    Datapixx('EnableTouchpixxLogContinuousMode');                   % Continuous logging during a touch. This also gives you long output from buffer reads
    Datapixx('StartTouchpixxLog');
    
    t_initPixx = Datapixx('GetTime');  % Save when the DataPixx Log was initiated

    Eyelink('StartRecording');
    
    % prepare the trial
    % set stimuli
    
    tarxPos = design.jTarxPos;
    taryPos = design.jTaryPos;
    
    tarxJump  = trial.tarJumpPos * visual.ppd;
    tarxShift = trial.tarShiftPos * visual.ppd; 
    
    tarpos = [tarxPos, taryPos];
    tarposJ = [tarxPos + tarxJump, taryPos];
    tarposS = [tarxPos + tarxShift, taryPos];

    tarx_range = [tarpos(1)-visual.rangeAccept, tarpos(1)+visual.rangeAccept];
    tary_range = [tarpos(2)-visual.rangeAccept, tarpos(2)+visual.rangeAccept];
    
    tarxJ_range = [tarposJ(1)-visual.rangeAccept, tarposJ(1)+visual.rangeAccept];
    taryJ_range = [tarposJ(2)-visual.rangeAccept, tarposJ(2)+visual.rangeAccept];
    
    % Draw stuff on Eyelink:
    Eyelink('command',sprintf('draw_box %d %d %d %d 15', tarpos(1)-visual.rangeAccept, tarpos(2)-visual.rangeAccept, tarpos(1)+visual.rangeAccept, tarpos(2)+visual.rangeAccept));
    Eyelink('command',sprintf('draw_box %d %d %d %d 15', tarposJ(1)-visual.rangeAccept, tarposJ(2)-visual.rangeAccept, tarposJ(1)+visual.rangeAccept, tarposJ(2)+visual.rangeAccept));
    
    % set the flash      
    flashPos_up     = [0, 0, design.flashx, design.flashy];
    flashPos_low    = [0, visual.winHeight-design.flashy, design.flashx, visual.winHeight];
    
    if trial.flash
        flashColor = visual.flashColor;
    else
        flashColor = visual.bgColor;
    end
    
    % set flash timing
    gapDur = design.mean_rea - trial.gapDur;
    gapDurFlip = gapDur * scr.hz;    
       
    % monitoring parameters
    fix_hand = false;
    fix_eye  = false;
    fix_time = true;
    sacc_on  = false;
    sacc_off = false;
    flash_on = 0;
    flip_count = 0;
    trial_on = true;

    % timing
    t_start    = NaN;  % the trial has started
    t_draw     = NaN;  % the first stimulus was on screen
    t_handfixed= NaN;  % the hand was on the start position 
    t_eyesfixed= NaN;  % the eyes were in the fixation area
    t_bothfixed= NaN;  % the trial can start
    t_flash    = NaN;  % the time when the flash was shown
    t_movStart = NaN;  % the hand movement started
    t_movEnd   = NaN;  % the movements ended
    t_saccStart= NaN;  % the saccade moved out of the box around target 1
    t_saccEnd  = NaN;  % the saccade moved into the vox around target 2
    t_jump     = NaN;  % the second stimulus was on screen
    t_feedback = NaN;  % feedback was on screen
    t_end      = NaN;  % the trial is over
    rea_time   = NaN;  % manual reaction time
    mov_time   = NaN;  % manual movement duration
    sacc_rea   = NaN;  % saccade reaction time
    sacc_dur   = NaN;  % duration of the saccade
    % positions
    resp_X     = NaN;  % response touch x
    resp_Y     = NaN;  % response touch Y
    
    % per default, the trial is a success :)
    trial_succ = 1;
    fixation_break = false;
    
    % Run the trial. Display the start point, get information about timing
    Datapixx('RegWrRd');
    t_start = Datapixx('GetTime'); 
    Eyelink('Message', sprintf('TRIAL_START_%i', settings.id));
    Eyelink('Message', 'TRIAL_SYNCTIME');
	
    Screen('DrawDots', visual.window, tarpos, visual.tarRad, visual.tarColor, [], 2); % first target
    Screen('Flip', visual.window);
    Datapixx('RegWrRd');
    t_draw = Datapixx('GetTime');
    Eyelink('Message', 'TARGET_ON_SCREEN');

    % while the finger is not yet on the starting position, monitor for that
    while ~ fix_hand || ~ fix_eye
        
        Datapixx('RegWrRd');
        status = Datapixx('GetTouchpixxStatus');
        
        % Check for events on touchpixx
        if status.newLogFrames                                              % something new happened
            [touches, ~] = Datapixx('ReadTouchpixxLog');
            touch_X = visual.mx*touches(1,status.newLogFrames)+visual.bx;   % Convert touch to screen coordinates
            touch_Y = visual.my*touches(2,status.newLogFrames)+visual.by;   % We use the one-before-last available touch information
            Datapixx('RegWrRd');
            
            % check if the detected touch was in the target box
            if inpolygon(touch_X, touch_Y, tarx_range, tary_range)
               t_handfixed    = Datapixx('GetTime');                    % we want a time tag when the first target was touched
               Eyelink('Message', 'HAND_FIX');
               fix_hand      = true;
            end
        end
        
        if Eyelink('NewFloatSampleAvailable') > 0
            % get the sample in the form of an event structure
            evt = Eyelink('NewestFloatSample');
            % if we do, get current gaze position from sample
            x = evt.gx(settings.eye_used+1); % +1 as we're accessing MATLAB array
            y = evt.gy(settings.eye_used+1);
            
            % do we have valid data and is the pupil visible?
            if  inpolygon(x, y, tarx_range, tary_range) && ~ fix_eye
                fix_eye = true; % get out of monitioring loop
                t_eyesfixed = Datapixx('GetTime'); % save time to data
                Eyelink('Message', 'EYES_FIX'); % save time to eyelink 
            end
        end
        
        time_passed = Datapixx('GetTime') - t_draw;
        
        if time_passed > design.waitToFix
            fix_time = false;
        end
        
        if ~fix_time
            % break the experiment here, do calibration or alike
        end
        
        % draw stimuli again and flip
        Screen('DrawDots', visual.window, tarpos, visual.tarRad, visual.tarColor, [], 2); % first target
        Screen('Flip', visual.window);
        Datapixx('RegWrRd');
    end
    
    Datapixx('RegWrRd');
    t_bothfixed = Datapixx('GetTime');
    Eyelink('Message', 'BOTH_FIX');
    WaitSecs(trial.fixDur);
    
    % let the first target disappear, show the second
    % monitor time to show a flash when in the right condition
    % get time stamp when the first target was released
    % get time stamp when the first target was touched
    Datapixx('RegWrRd');
    
    while flip_count <= visual.trialFlips && trial_on
        
        % draw the second target
        Screen('DrawDots', visual.window, tarposJ, visual.tarRad, visual.tarColor, [], 2);
        % draw flash in some conditions
        if flip_count >= gapDurFlip && flash_on < visual.flashFlips
            % Draw the flash
            Screen('FillRect', visual.window, flashColor, flashPos_up);
            Screen('FillRect', visual.window, flashColor, flashPos_low);
            % get the flash timing
            if isnan(t_flash)
                % get the flash timing
                t_flash = Datapixx('GetTime');
                Eyelink('Message', 'FLASH_ON_SCREEN');
                tarposJ = tarposS;
            end
            % monitor the flash duration
            flash_on = flash_on+1;
        end
        
        % get everything on screen
        Screen('Flip', visual.window);
        flip_count = flip_count+1;
        Datapixx('RegWrRd');
        
        if isnan(t_jump) % set time stamp the first time this is executed
            t_jump = Datapixx('GetTime');
            Eyelink('Message', 'TARGET_JUMPED');
        end
        
        % Get the touchpixx status
        Datapixx('RegWrRd');
        status = Datapixx('GetTouchpixxStatus');
                
        % Check for touchpixx releases
        if ~status.isPressed && isnan(t_movStart)
            Datapixx('RegWrRd');
            t_movStart =  Datapixx('GetTime');
            Eyelink('Message', 'HAND_MOVED');
        end
        
        % Check for new touches
        if status.newLogFrames && ~isnan(t_movStart) && isnan(t_movEnd)                                            % something new happened
            [touches, ~] = Datapixx('ReadTouchpixxLog');
            touch_X = visual.mx*touches(1,status.newLogFrames)+visual.bx;   % Convert touch to screen coordinates
            touch_Y = visual.my*touches(2,status.newLogFrames)+visual.by;   % We use the one-before-last available touch information
            Datapixx('RegWrRd');
            
            % check if movement reached the target box
            if inpolygon(touch_X, touch_Y, tarxJ_range, taryJ_range)
               t_movEnd    = Datapixx('GetTime');                    % we want a time tag when the target was touched for the first time
               Eyelink('Message', 'HAND_LANDED');
               resp_X      = touch_X;
               resp_Y      = touch_Y;
               trial_on    = false;
            end
        end
        
        % Check for eye movements
        % get gaze position to check if it's on screen
        if Eyelink('NewFloatSampleAvailable') > 0
            evt = Eyelink('NewestFloatSample');
            
            x = evt.gx(settings.eye_used+1);
            y = evt.gy(settings.eye_used+1);

            if evt.pa(settings.eye_used+1) < 1 % is the pupil visible?
                %fixation_break = true;
                %Eyelink('Message', 'FIXATION_BREAK');
                %trial_on = false;
            elseif ~sacc_on &&  ~ inpolygon(x,y, tarx_range, tary_range)
                sacc_on = true;
                t_saccStart    = Datapixx('GetTime');                    % we want a time tag when the target was touched for the first time
                Eyelink('Message', 'SACCADE_STARTED');
            elseif sacc_on && ~sacc_off && inpolygon(x,y, tarxJ_range, taryJ_range)
                sacc_off = true;
                t_saccEnd    = Datapixx('GetTime');                    % we want a time tag when the target was touched for the first time
                Eyelink('Message', 'SACCADE_LANDED');
            end
        end
    end
    
    Datapixx('RegWrRd');
    t_end  = Datapixx('GetTime');
    Eyelink('Message', sprintf('TRIAL_END_%i', settings.id));
    Datapixx('StopTouchpixxLog');  

    rea_time = t_movStart - t_jump;
    mov_time = t_movEnd - t_movStart; 
    
    sacc_rea = t_saccStart - t_jump;
    sacc_dur = t_saccEnd - t_saccStart;
    
    if sacc_rea > 0.35 || sacc_rea < 0.05
        clean_rea = NaN;
    else
        clean_rea = sacc_rea;
        design.mean_rea = mean([design.mean_rea, clean_rea]);
    end
    
    
    
    % present feedback
    if fixation_break
        DrawFormattedText(visual.window, 'Please Fixate', 'center', 'center', visual.textColor);
        trial_succ = 0;
        settings.FIXBREAK = settings.FIXBREAK +1;
        sprintf('fixbreak 1 %i', settings.FIXBREAK)
        if settings.FIXBREAK > 2
            sprintf('fixbreak 2 %i', settings.FIXBREAK)
            EyelinkDoTrackerSetup(el);
            settings.FIXBREAK = 0;
        end
    elseif ~ sacc_off
        DrawFormattedText(visual.window, 'The eye movement was inaccurate', 'center', 'center', visual.textColor);
        trial_succ = 0;
    elseif ~fix_time || isnan(t_movEnd)
        DrawFormattedText(visual.window, 'Too slow', 'center', 'center', visual.textColor);
        trial_succ = 0;
    elseif rea_time < 0.07
        DrawFormattedText(visual.window, 'Too fast', 'center', 'center', visual.textColor);
        trial_succ = 0;  
    else
        rt_message = sprintf('Reaction Time: %.3f seconds', rea_time);
        DrawFormattedText(visual.window,  rt_message, 'center', 'center', visual.textColor);
        trial_succ = 1;
    end
    
    Screen('Flip', visual.window);
    t_feedback = Datapixx('GetTime');
    Eyelink('Message', 'FEEDBACK_PRESENTED');
    Eyelink('StopRecording');
    WaitSecs(1.5);
    trialData.id = settings.id;
    trialData.success         = trial_succ;                                 % 1 = success 
                                                                            % 0 = unknown error
    trialData.rea_time        = rea_time;
    trialData.clean_rea       = clean_rea;
    trialData.mov_time        = mov_time;
    trialData.sacc_rea        = sacc_rea;
    trialData.sacc_dur        = sacc_dur;
    trialData.initPixx        = t_initPixx;
    trialData.t_start         = t_start;
    trialData.t_draw          = t_draw;
    trialData.t_jump          = t_jump;
    trialData.t_handfixed     = t_handfixed;
    trialData.t_eyesfixed     = t_eyesfixed;
    trialData.t_bothfixed     = t_bothfixed;
    trialData.t_flash         = t_flash;
    trialData.t_movStart      = t_movStart;
    trialData.t_movEnd        = t_movEnd;
    trialData.t_saccStart     = t_saccStart;
    trialData.t_saccEnd       = t_saccEnd;
    trialData.t_feedback      = t_feedback;
    trialData.t_end           = t_end;
    trialData.mean_rt         = design.mean_rea;
    trialData.gapDur          = gapDur;
    trialData.touchX          = resp_X;
    trialData.touchY          = resp_Y;
    trialData.version         = 'JUMP';
    
    Eyelink('command', 'clear_screen 0');
    WaitSecs(design.iti);
end