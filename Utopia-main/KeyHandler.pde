class KeyHandler{
  // Added 86 ('V') to the end of the KEYS array
  int[] KEYS = {65,87,68,83,32,16,10,67,89,84,85,86}; 
  int LEN = KEYS.length;
  boolean[] keysDown = new boolean[LEN];
  
  // Create a boolean flag to track control mode
  boolean canControl = false; 

  public KeyHandler(){
    for(int i = 0; i < LEN; i++){
      keysDown[i] = false;
    }
  }

  void handle(int k, boolean state){
    for(int i = 0; i < LEN; i++){
      if(KEYS[i] == k){
        keysDown[i] = state;
      }
      

      if(i == 6 && KEYS[i] == k && state){ 
        TRAP_MOUSE = !TRAP_MOUSE;
        r.confinePointer(TRAP_MOUSE);
        r.setPointerVisible(!TRAP_MOUSE);
      }
      

      if(i == 7 && KEYS[i] == k && state){
        followSpecimen = !followSpecimen;
        if(followSpecimen){
          if(closest_AI == null){
            getClosestAI();
          }
          if(closest_AI != null){
            controlledAgent = closest_AI;
          }
        }else{
          if(players.size() > 0){
            controlledAgent = players.get(0);
          }else{
            controlledAgent = null;
          }
        }
      }
      

      if(i == 9 && KEYS[i] == k && state && followSpecimen){
        if(closest_AI != null && closest_AI.target != null &&
           getSpeciesType(closest_AI.target.species) >= 1){
          closest_AI = closest_AI.target;
          controlledAgent = closest_AI;
        }
      }

      // V to toggle manual control of creaturs or just view them
      if(i == 11 && KEYS[i] == k && state){
        canControl = !canControl;
      }
    }
  }

  boolean keysToAction(int n){
    if(n <= 4){ 
      return keysDown[n];
    }else if(n == 7){ 
      return keysDown[8];
    }
    return false;
  }
}
