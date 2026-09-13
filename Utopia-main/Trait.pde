class Trait {
  float size;
  
  // priorities array and graphics preserved as-is
  float [] priorities;
  PGraphics display;
  int id;
  String name;
  int birth_tick;
  int generation;
  String parents;
  float bw;
  int mc = 0;
  int timeOfLastMeal = -99999;
  ArrayList<String> children;
  Player player;
  float age;
  float extraLifespan;
  float lifespan;
  int species;

  // 5 Heritable Stats [0: Speed, 1: Stamina, 2: Metabolism, 3: Vision, 4: Fertility]
  float[] stats = new float[5];

  // Updated constructor maintaining UI initialization and adding genetic inheritance
  public Trait(Player p, boolean DETAILED, float startingHunger, float startingThirst, float[] parentStats) {
    player = p;
    size = 0;
    species = player.species;

    // --- GENETIC DRIFT INHERITANCE ---
    if (parentStats != null) {
      for (int i = 0; i < 5; i++) {
        float mutation = random(-0.075, 0.075); // +/- 7.5% drift
        stats[i] = constrain(parentStats[i] + mutation, 0.0, 1.0);
      }
    } else {
      // Primordial population baseline
      for (int i = 0; i < 5; i++) {
        stats[i] = random(0.4, 0.6);
      }
    }

    // ORIGINAL DETAILED UI SETUP (PRESERVED)
    if(DETAILED){
      priorities = new float[PRIORITY_NAMES.length];
      for(int i = 0; i < PRIORITY_NAMES.length; i++){
        priorities[i] = random(0,1);
      }
      priorities[0] = startingHunger;
      priorities[1] = startingThirst;
      priorities[2] = 1; // freakiness baseline
      priorities[3] = 1;
      priorities[5] = 1;
      display = createGraphics(400,700);
    }
    bw = startingHunger;
    birth_tick = ticks;
    children = new ArrayList<String>(0);
  }

  // --- STAT GETTERS & SCALING ---
// Stamina speed boost (+10% speed at 0, -10% top speed at 1.0)
  public float getStaminaSpeedMultiplier() {
     return map(stats[0], 0.0, 1.0, 1.1, 0.9);
  }

  // Stamina hunger modifier (+20% at 0.0, -20% at 1.0)
  public float getStaminaHungerMultiplier() {
    return map(stats[1], 0.0, 1.0, 1.2, 0.8);
  }
  
  public float getSpeedBonus() { // -15% at 0, +15% at 1
    return map(stats[0], 0.0, 1.0, 0.85, 1.15);
  }

  public float getSpeedModifier() { // returns total top speed multiplier when moving
    float baseSpeed = getSpeedBonus();
    return baseSpeed * getStaminaSpeedMultiplier() * getMetabolicSpeedMultiplier();
  }

  // Higher speed stat leads to higher energy burn rate while moving
  public float getSpeedHungerMultiplier() {
    return map(stats[0], 0.0, 1.0, 0.7, 1.3); // also, higher hunger multipliers equals more energy burn
  }

  public float getMetabolicDrainMultiplier() { //-15% at 0, +15% at max, affects hunger and thrist even when not moving
    return map(stats[2], 0.0, 1.0, 0.85, 1.15);
  }

  // High metabolism reduces lifespan; low metabolism extends it
  public float getMetabolicLifespanMultiplier() {
    return map(stats[2], 0.0, 1.0, 1.2, 0.8); //+20% at 0, -20% at 1
  }
  
  public float getMetabolicSpeedMultiplier() {
    return map(stats[2], 0.0, 1.0, 0.85, 1.15); //-15% at 0, +15% at 1
  }

  public float getVisionOffset() { //-3 tile vision at 0, +3 tile vision at 1
    return map(stats[3], 0.0, 1.0, -T*3.0, T*3.0);
  }
  
  public float getVisionHungerMultiplier() {
    return map(stats[3], 0.0, 1.0, 0.875, 1.125); //-12.5% hunger growth at 0, +12.5% hunger growth at 1
  }
  
  //Fertility increases freakyness growth rate by +20% at 1, and -20% at 0. High fertility has advantages but also disadvantages too.

  String getChildrenString(){
    if(children.size() == 0){
      return "0";
    }
    String result = children.size()+" (";
    for(int c = 0; c < children.size(); c++){
      result += children.get(c);
      if(c < children.size()-1){
        result += ", ";
      }
    }
    result += ")";
    return result;
  }
  
  String weightToString(float n){
    return nf(n*100,0,1)+" lbs";
  }

  // COMPLETE ORIGINAL UI DRAW FUNCTION (UNTOUCHED)
  void drawDisplay(){
    boolean[] RIGHT_SIDE = {true, true, false, false, false, false};
    int[] order = ArrayUtils.argsort(priorities, true);
    display.beginDraw();
    display.background(0);
    
    // Kept original background box dimensions (384x375)
    display.fill(80);
    display.rect(8,0,384,375,25);
    display.fill(255);
    display.textAlign(LEFT);
    display.textSize(36);
    display.text(name,15,36);
    display.textSize(18);

    float metaLifeMult = getMetabolicLifespanMultiplier();
    if(getSpeciesType(species) == 1){
      lifespan = (extraLifespan+16000) * metaLifeMult;
    }else if(getSpeciesType(species) == 2){
      lifespan = (extraLifespan+20000) * metaLifeMult;
    }else if(getSpeciesType(species) == 0){
      lifespan = (extraLifespan+12000) * metaLifeMult;
    }
    String[] info = {"Creature #"+(id+1), "Generation "+(generation+1),
    "Birth weight: "+weightToString(bw),"Weight now: "+weightToString(priorities[0]),
    "Age: "+nf(ticksToDays(ticks-birth_tick),0,2)+" days","Max Lifespan: "+nf(ticksToDays(lifespan),0,2)+" days","Parents: "+parents,
    "Children: "+getChildrenString()};
    
    for(int i = 0; i < info.length; i++){
      float y = (i%(info.length/2))*18+60;
      float x = ((i >= info.length/2) ? 205 : 15);
      display.text(info[i],x,y);
    }
    
    // Priorities list vertically compressed slightly to fit stats inside original height
    for(int i = 0; i < priorities.length; i++){
      int p = order[i];
      display.pushMatrix();
      display.translate(120,132+32*i);
      display.noStroke();
      
      float fullW = 250;
      float appW = (1-PRIORITY_CAPS[p])*fullW;
      if(i == 0){
        display.fill(255);
        display.rect(-3,-2,appW+6,27);
      }
      display.fill(0);
      display.rect(0,0,appW,23);
      display.fill(PRIORITY_COLORS[p]);
      float lineX = fullW*(1-priorities[p]);
      if(RIGHT_SIDE[p]){
        display.rect(lineX,0,appW-lineX,23);
      }else{
        display.rect(0,0,lineX,23);
      }
      
      display.textAlign(RIGHT);
      display.textSize(16);
      display.fill(255);
      display.text(PRIORITY_NAMES[p],-5,13);
      
      display.popMatrix();
    }

    // --- GENETIC STATS SECTION (Fits inside 375px board) ---
    float statsStartY = 328;

    display.fill(255, 255, 255);
    display.textAlign(LEFT);
    display.textSize(20);
    display.text("Genetics", 14, statsStartY + 8);

    // Concrete stat values and actual game parameters
    String[] statNames = {"SPD: ", "STM: ", "MET: ", "VIS: ", "FER: "};
    
    for (int i = 0; i < stats.length; i++) {
      float x = 15 + (i * 73);
      float y = statsStartY + 24;

      // Stat Label & Value
      display.fill(255);
      display.textSize(12);
      display.text(statNames[i] + " " + nf(stats[i], 1, 2), x, y);

      // Stat Bar
      display.fill(0);
      display.rect(x, y + 4, 65, 5);
      display.fill(255, 255, 255);
      display.rect(x, y + 4, stats[i] * 65, 5);
    }

    display.endDraw();
  }
}
