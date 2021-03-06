function trialData  = runSingleTrial_em(trial, design, visual, settings)
    
    ListenChar(0);

    Datapixx('SetTouchpixxLog');                                    % Configure TOUCHPixx logging with default buffer
    Datapixx('EnableTouchpixxLogContinuousMode');                   % Continuous logging during a touch. This also gives you long output from buffer reads
    Datapixx('StartTouchpixxLog');
    
    t_initPixx = Datapixx('GetTime');  % Save when the DataPixx Log was initiated

    Eyelink('StartRecording');
    
    % prepare the trial
    % set stimuli
    
    tar2xPos = trial.tar2xPos * visual.ppd + visual.xCenter;
    tar2yPos = trial.tar2yPos;
    
    tar1pos = [design.tar1xPos, design.tar1yPos];
    tar2pos = [tar2xPos, tar2yPos];
    
    tar1x_range = [tar1pos(1)-visual.rangeAccept, tar1pos(1)+visual.rangeAccept];
    tar1y_range = [tar1pos(2)-visual.rangeAccept, tar1pos(2)+visual.rangeAccept];
    
    tar2x_range = [tar2pos(1)-visual.rangeAccept, tar2pos(1)+visual.rangeAccept];
    tar2y_range = [tar2pos(2)-visual.rangeAccept, tar2pos(2)+visual.rangeAccept];
    
    % Draw stuff on Eyelink:
    Eyelink('command',sprintf('draw_box %d %d %d %d 15', tar1pos(1)-visual.rangeAccept, tar1pos(2)-visual.rangeAccept, tar1pos(1)+visual.rangeAccept, tar1pos(2)+visual.rangeAccept));
    Eyelink('command',sprintf('draw_box %d %d %d %d 15', tar2pos(1)-visual.rangeAccept, tar2pos(2)-visual.rangeAccept, tar2pos(1)+visual.rangeAccept, tar2pos(2)+visual.rangeAccept));
    
    % set the flash      
    flashPos_up     = [0, 0, design.flashx, design.flashy];
    flashPos_low    = [0, visual.winHeight-design.flashy, design.flashx, visual.winHeight];
       
    % Initialize timing and monitoring parameters
    on_fix_hand = true;
    on_fix_eye  = false;
    time_to_fix = true;
    trial_on  = true;
    sacc_on = false;
    sacc_off = false;
    rt_timer  = 0;
    flash_on_screen = 0;

    % timing
    t_start    = NaN;  % the trial has started
    t1_draw    = NaN;  % the first stimulus was on screen
    t2_draw    = NaN;  % the second stimulus was on screen
    t_handfixed= NaN;  % check if the hand was on the start position 
    t_eyesfixed= NaN;  % check if the eyes were in the fixation area
    t_bothfixed= NaN;  % when the trial can start
    t_flash    = NaN;  % the time when the flash was shown
    t_movStart = NaN;  % the hand movement started
    t_movEnd   = NaN;  % the movements ended
    t_saccStart= NaN;  % the saccade moved out of the box around target 1
    t_saccEnd  = NaN;  % the saccade moved into the vox around target 2
    t_feedback = NaN;  % feedback was on screen
    t_end      = NaN;  % the trial is over
    rea_time   = NaN;  % manual reaction time
    mov_time   = NaN;  % manual movement duration
    sacc_rea   = NaN;  % saccade reaction time
    sacc_dur   = NaN;  % duration of the saccade
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
	
    Screen('DrawDots', visual.window, tar1pos, visual.tar1Rad, visual.black, [], 2); % first target
    Screen('Flip', visual.window);
    Datapixx('RegWrRd');
    t1_draw = Datapixx('GetTime');
    Eyelink('Message', 'T1_ON_SCREEN');

    % while the finger is not yet on the starting position, monitor for that
    while ~ on_fix_hand || ~ on_fix_eye
        
        Datapixx('RegWrRd');
        status = Datapixx('GetTouchpixxStatus');
        
        % Check for events on touchpixx
        if status.newLogFrames                                              % something new happened
            [touches, ~] = Datapixx('ReadTouchpixxLog');
            touch_X = visual.mx*touches(1,status.newLogFrames)+visual.bx;   % Convert touch to screen coordinates
            touch_Y = visual.my*touches(2,status.newLogFrames)+visual.by;   % We use the one-before-last available touch information
            Datapixx('RegWrRd');
            
            % check if the detected touch was in the target box
            if inpolygon(touch_X, touch_Y, tar1x_range, tar1y_range)
               t_handfixed    = Datapixx('GetTime');                    % we want a time tag when the first target was touched
               Eyelink('Message', 'HAND_FIX');
               on_fix_hand      = true;
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
                t_eyesfixed = Datapixx('GetTime'); % save time to data
                Eyelink('Message', 'EYES_FIX'); % save time to eyelink 
            end
        end
        
        time_passed = Datapixx('GetTime') - t2_draw;
        
        if time_passed > design.wait_to_fix
            time_to_fix = false;
            break
        end
        
        % draw stimuli again and flip
        Screen('DrawDots', visual.window, tar1pos, visual.tar1Rad, visual.black, [], 2); % first target
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
    
    trial_timer = 0;
    while trial_timer <= design.trialDur
        
        % draw the second target
        Screen('DrawDots', visual.window, tar2pos, visual.tar2Rad, visual.black, [], 2); % first target
        % draw flash in some conditions
        if trial.flash && trial_timer >= trial.gapDur && flash_on_screen < visual.flashFlips
            % Draw the flash
            Screen('FillRect', visual.window, visual.flashcolor, flashPos_up);
            Screen('FillRect', visual.window, visual.flashcolor, flashPos_low);
            % get the flash timing
            if isnan(t_flash)
                t_flash = Datapixx('GetTime');
                Eyelink('Message', 'FLASH_ON_SCREEN');
            end
            % monitor the flash duration
            flash_on_screen = flash_on_screen+1;
        end
        
        % get everything on screen
        Screen('Flip', visual.window);
        Datapixx('RegWrRd');
        
        if isnan(t2_draw) % set time stamp the first time this is executed
            t2_draw = Datapixx('GetTime');
            Eyelink('Message', 'T2_ON_SCREEN');
        end
        
        % Get the touchpixx status
        Datapixx('RegWrRd');
        status = Datapixx('GetTouchpixxStatus');
                
        % Check for touchpixx releases
        %if ~status.isPressed && isnan(t_movStart)
        %    Datapixx('RegWrRd');
        %    t_movStart =  Datapixx('GetTime');
        %    Eyelink('Message', 'HAND_MOVED');
        %end
        
        % Check for new touches
        %if status.newLogFrames && ~isnan(t_movStart) && isnan(t_movEnd)                                            % something new happened
        %    [touches, ~] = Datapixx('ReadTouchpixxLog');
        %    touch_X = visual.mx*touches(1,status.newLogFrames)+visual.bx;   % Convert touch to screen coordinates
        %    touch_Y = visual.my*touches(2,status.newLogFrames)+visual.by;   % We use the one-before-last available touch information
        %    Datapixx('RegWrRd');
            
            % check if movement reached the target box
        %    if inpolygon(touch_X, touch_Y, tar2x_range, tar2y_range)
        %       t_movEnd    = Datapixx('GetTime');                    % we want a time tag when the target was touched for the first time
        %       Eyelink('Message', 'HAND_LANDED');
        %       resp_X      = touch_X;
        %       resp_Y      = touch_Y;
        %    end
        %end
        
        % Check for eye movements
        % get gaze position to check if it's on screen
        if Eyelink('NewFloatSampleAvailable') > 0
            evt = Eyelink('NewestFloatSample');
            
            x = evt.gx(settings.eye_used+1);
            y = evt.gy(settings.eye_used+1);

            if evt.pa(settings.eye_used+1) < 1 % is the pupil visible?
                fixation_break = true;
                Eyelink('Message', 'FIXATION_BREAK');
            elseif ~sacc_on &&  ~ inpolygon(x,y, tar1x_range, tar1y_range)
                sacc_on = true;
                t_saccStart    = Datapixx('GetTime');                    % we want a time tag when the target was touched for the first time
                Eyelink('Message', 'SACCADE_STARTED');
            elseif sacc_on && ~sacc_off && inpolygon(x,y, tar2x_range, tar2y_range)
                sacc_off = true;
                t_saccEnd    = Datapixx('GetTime');                    % we want a time tag when the target was touched for the first time
                Eyelink('Message', 'SACCADE_LANDED');
            end
        end
        
        % update the trial timer
        trial_timer = Datapixx('GetTime') - t2_draw;
    end
    
    Datapixx('RegWrRd');
    t_end  = Datapixx('GetTime');
    Eyelink('Message', sprintf('TRIAL_END_%i', settings.id));
    Datapixx('StopTouchpixxLog');  

    %rea_time = t_movStart - t2_draw;
    %mov_time = t_movEnd - t_movStart; 
    
    sacc_rea = t_saccStart - t2_draw;
    sacc_dur = t_saccEnd - t_saccStart;
    
    if sacc_rea > 0.35 || sacc_rea < 0.05
        clean_rea = NaN;
    else
        clean_rea = sacc_rea;
    end
    
    % present feedback
    if fixation_break
        DrawFormattedText(visual.window, 'Please Fixate', 'center', 'center', visual.textColor);
        trial_succ = 0;
    elseif ~ sacc_off
        DrawFormattedText(visual.window, 'The eye movement was inaccurate', 'center', 'center', visual.textColor);
        trial_succ = 0;
    elseif ~time_to_fix || isnan(t_saccEnd)
        DrawFormattedText(visual.window, 'Too slow', 'center', 'center', visual.textColor);
        trial_succ = 0;
    else
        rt_message = sprintf('Reaction Time: %.3f seconds', sacc_rea);
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
    trialData.t1_draw         = t1_draw;
    trialData.t2_draw         = t2_draw;
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
    %trialData.mean_rt         = design.flashTime;
    trialData.touchX          = resp_X;
    trialData.touchY          = resp_Y;
    trialData.version         = 'em_only';
    
    Eyelink('command', 'clear_screen 0');
    WaitSecs(design.iti);
end