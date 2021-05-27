% prepare stimuli for presentation

function prepStim
  global design visual scr

  
  % define stimulus properties as visuals
  % parameters for stimuli in pix
  % parameters that differ on a trial-by-trial basis are set on each trial
  
  % timing
  visual.flashFlips = round(design.flashDur * scr.hz); 
  visual.trialFlips = round(design.trialDur * scr.hz);
  
  % Target
  visual.tarRad = design.tarRad * visual.ppd;
  visual.sTarRadTouch = design.sTarRadTouch * visual.ppd;
   
  % area in which a response is accepted
  visual.rangeAccept = design.rangeAccept * visual.ppd; 
  visual.rangeCalib = design.rangeCalib * visual.ppd; 

  % color definitions
  visual.tarColor = visual.white;
  visual.flashColor = visual.white;
  visual.textColor = visual.white; 
  visual.fixColor = visual.white;
  
  visual.bgColor = visual.white * [0.5, 0.5, 0.5];
  
end
