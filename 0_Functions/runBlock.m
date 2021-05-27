function blockData = runBlock(b, b_i, el)

    global visual design settings scr
    
    % start each block with a calibration
    if b_i > 1
        sprintf('block %i', b);
        EyelinkDoTrackerSetup(el);
    end
    
    settings.FIXBREAK = 0;
    settings.id = 0;
    
    % print some messages at the beginning
    messageStart = sprintf('This is block no. %i', b_i);
    if design.b(b).type == 'J'
        btype = 'Jump';
    elseif design.b(b).type == 'S'
        btype = 'Serial';
    end
    messageType  = sprintf('The block type is %i', btype);
    DrawFormattedText(visual.window, messageStart, 'center', 200, visual.textColor);
    %DrawFormattedText(visual.window, messageType, 'center', 500, visual.textColor);
    DrawFormattedText(visual.window, 'Press any key to start', 'center', 'center', visual.textColor);
    Screen('Flip',visual.window);
    
    % prepare block info
    trials_total = design.nTrialsPB;
    t            = 1;
    
    % wait for participant
    KbPressWait;  
    Eyelink('Message', sprintf('BLOCK_START, %i, DESIGN %i', b_i, b));

    
    % go through trials
    while t <=  trials_total
                
        settings.id = settings.id+1;
        Eyelink('Message', 'TRIAL_ID, %i', settings.id);
        trial = design.b(b).trial(t);
        
        if design.b(b).type == 'J'
            blockData.trial(t) = runSingleTrialJump(trial, visual, scr);
        elseif design.b(b).type == 'S'
            blockData.trial(t) = runSingleTrialSerial(trial, visual, scr);
        end

        % repeat the trial, if needed
        if ~ blockData.trial(t).success
            trials_total                    = trials_total + 1;
            design.b(b).trial(trials_total) = trial;
        end
        
        design.b(b).trial(t).id = settings.id;
        t = t+1;                   
    
    end
    
    % end of the block
    Eyelink('Message', sprintf('BLOCK_END, %i, DESIGN, %i', b_i, b));

    Screen('Flip', visual.window);
    WaitSecs(2);
end
