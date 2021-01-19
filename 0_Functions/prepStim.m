% prepare stimuli for presentation

function prepStim
  global design visual scr

  
  % define stimulus properties as visuals
  % parameters for stimuli in pix
  % parameters that differ on a trial-by-trial basis are set on each trial
  
  % timing
  visual.flashFlips = round(design.flashDur * scr.hz); 
  
  % Target
  visual.tar1Rad = design.tar1Rad * visual.ppd;
  visual.tar2Rad = design.tar2Rad * visual.ppd;
   
  % area in which a response is accepted
  visual.rangeAccept = design.rangeAccept * visual.ppd; 
  visual.rangeCalib = design.rangeCalib * visual.ppd; 

  % color definitions
  visual.tar1color = visual.white;
  visual.tar2color = visual.white;
  visual.flashcolor = visual.white;
  visual.textColor = visual.white; 
  visual.fixColor = visual.white;
  
  visual.bgcolor = visual.white * [0.5, 0.5, 0.5];
  
end
