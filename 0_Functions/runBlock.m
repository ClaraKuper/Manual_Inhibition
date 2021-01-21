function blockData = runBlock(b, b_i)

    global visual design settings
    
    % print some messages at the beginning
    messageStart = sprintf('This is block no. %i', b_i);
    DrawFormattedText(visual.window, messageStart, 'center', 200, visual.textColor);
    DrawFormattedText(visual.window, 'Press any key to start', 'center', 'center', visual.textColor);
    Screen('Flip',visual.window);
    
    % prepare block info
    trials_total = design.nTrialsPB;
    t            = 1;
    
    % wait for participant
    KbPressWait;  
    
    if settings.EYETRACK
        Eyelink('Message', sprintf('BLOCK_START, %i, DESIGN %i', b_i, b));
    end
    
    % go through trials
    while t <=  trials_total
                
        settings.id = settings.id+1;
        
        if settings.EYETRACK
            Eyelink('Message', 'TRIAL_ID, %i', settings.id);
        end
        
        trial = design.b(b).trial(t);
        if settings.EYETRACK
            blockData.trial(t) = runSingleTrial_2tar_ET(trial, design, visual, settings);
        else
            blockData.trial(t) = runSingleTrial_2tar(trial, design, visual, settings);
        end
        % adjust the flash gap time to the reaction time of the participant
        block_table = struct2table(blockData.trial);
        design.flashTime = mean(block_table.clean_rea, 'omitnan') - design.gapDur;
        
        % repeat the trial, if needed
        if ~ blockData.trial(t).success
            
            trials_total                    = trials_total + 1;
            design.b(b).trial(trials_total) = trial;
       
        end
        
        design.b(b).trial(t).id = settings.id;
        t = t+1;        
    end
    
    % end of the block
    
    if settings.EYETRACK
         Eyelink('Message', sprintf('BLOCK_END, %i, DESIGN, %i', b_i, b));
    end
    
    Screen('Flip', visual.window);
    WaitSecs(2);
end
