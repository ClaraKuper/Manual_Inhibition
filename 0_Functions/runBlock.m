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
    % go through trials
    while t <=  trials_total
                
        settings.id = settings.id+1;
        trial = design.b(b).trial(t);
        blockData.trial(t) = runSingleTrial(trial, design, visual, settings);
        
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
    Screen('Flip', visual.window);
    WaitSecs(2);
end
