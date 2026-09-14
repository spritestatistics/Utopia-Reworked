class Player{
  float[] prevCoor;
  float[] coor;
  float[] velo;
  float[] tilt;
  
  float FRICTION = 0.85;
  float ACCEL = 2;
  float WANDER_ACCEL = 1;
  float R_ACCEL = 0.05;
  float THICKNESS = 11;
  float EPS = 0.1;
  float walk_speed = -1.0;
  boolean toDie = false;
  int species;
  int topPriority = -1;
  boolean[] animalKeyPresses = {false,false,false,false,false,false,false,false};
  boolean plant_landed = false;
  int wander_action = -1;
  
  int tick_bucket = 0; 
  
  Player predator = null;
  Player target = null;
  Player recentChild = null;
  
  Trait trait; 

  public Player(int s, float[] _coor, boolean BURST, boolean PRIMORDIAL, float hunger, float thirst, int gen, String rents, float[] parentStats){
    coor = deepCopy(_coor);
    if(s == -1){
      deepCopy(_coor, camera);
    }
    if(BURST){
      velo = newBurst(true);
      coor[2] = map.getGroundLevel(coor)+0.1;
    }else{
      velo = newBlank();
      plant_landed = true;
    }
    species = s;
    
    // Instantiates trait passing down genetic stats
    trait = new Trait(this, getSpeciesType(species) >= 1, hunger, thirst, parentStats);
    
    if(getSpeciesType(species) == 0){
      if(PRIMORDIAL){
        trait.size = random(0,1);
      }else{
        trait.size = 0;
      }
      trait.extraLifespan = random(0,8000); 
    }
    if(getSpeciesType(species) >= 1){
      tick_bucket = (int)random(0,TICK_BUCKET_COUNT);
      trait.id = MAX_ID;
      MAX_ID++;
      trait.name = getNewName();
      trait.generation = gen;
      trait.parents = rents;
      if(getSpeciesType(species) == 1){
        trait.extraLifespan = random(0,14000); 
      }else if(getSpeciesType(species) == 2){
        trait.extraLifespan = random(0,16000); 
      }else if(getSpeciesType(species) == 3){ 
        trait.extraLifespan = random(0,20000); 
      }
    }
    tilt = new float[2];
    tilt[0] = 0;
    tilt[1] = 0;

    joinTile();
  }

  public Player(int s, float[] _coor, boolean BURST, boolean PRIMORDIAL, float hunger, float thirst, int gen, String rents) {
    this(s, _coor, BURST, PRIMORDIAL, hunger, thirst, gen, rents, null);
  }
  
  Tile getCurrentTile(){
    int x = (int)(coor[0]/T);
    int y = (int)(coor[1]/T);
    return map.tiles[x][y];
  }
  
  void joinTile(){
    if(getSpeciesType(species) != 0){
      return;
    }
    ArrayList<Player> list = getCurrentTile().occupants;
    if(!list.contains(this)){
      list.add(this);
    }
  }
  
  void leaveTile(){
    if(getSpeciesType(species) != 0){
      return;
    }
    ArrayList<Player> list = getCurrentTile().occupants;
    list.remove(this);
  }
  
  void switchTile(){
    if(getSpeciesType(species) != 0){
      return;
    }
    int x1 = (int)(prevCoor[0]/T);
    int y1 = (int)(prevCoor[1]/T);
    int x2 = (int)(coor[0]/T);
    int y2 = (int)(coor[1]/T);
    if(x1 == x2 && y1 == y2){
      return;
    }
    ArrayList<Player> prevList = map.tiles[x1][y1].occupants;
    ArrayList<Player> currList = map.tiles[x2][y2].occupants;
    prevList.remove(this);
    if(!currList.contains(this)){
      currList.add(this);
    }
  }
  
  float[] newBlank(){
    float[] result = {0,0,0,0};
    return result;
  }
  float[] newBurst(boolean newAngle){
    float angle = 0;
    if(newAngle){
      angle = random(2*PI);
    }else{
      angle = atan2(velo[1],velo[0]);
    }
    float dist = random(2,11);
    float[] result = {cos(angle)*dist,sin(angle)*dist,18,0};
    return result;
  }
  void drawPlayer(){
    if(!mapVisible(coor)){
      return;
    }
    g.noStroke();
    g.pushMatrix();
    g.translate(unloop_two(coor[0],camera[0]),unloop_two(coor[1],camera[1]),coor[2]);
    g.rotateZ(coor[3]);
    drawBody();
    g.popMatrix();
    
    if(this == closest_AI && followSpecimen &&
    (topPriority == 0 || topPriority == 1 || topPriority == 2 || topPriority == 6)){
      drawVisibilityRing();
    }
    if(this != closest_AI || topPriority == 3 || target == null){
      return;
    }
    drawArrow(target.coor, (topPriority == 4));
  }
  void drawVisibilityRing(){
    int P = 40;
    float WALL = 100;
    float effectiveVision = VISION_DISTANCE + trait.getVisionOffset();
    for(int p = 0; p < P; p++){
      if(p%2 == (ticks/10)%2){
        continue;
      }
      float ang1 = p*2*PI/P;
      float ang2 = (p+1)*2*PI/P;
      float c_x = unloop_two(coor[0],camera[0]);
      float c_y = unloop_two(coor[1],camera[1]);
      
      float x1 = c_x+cos(ang1)*effectiveVision;
      float y1 = c_y+sin(ang1)*effectiveVision;
      float z1 = map.getGroundLevel(x1,y1);
      float x2 = c_x+cos(ang2)*effectiveVision;
      float y2 = c_y+sin(ang2)*effectiveVision;
      float z2 = map.getGroundLevel(x2,y2);
      g.fill(255,255,0);
      g.beginShape();
      g.vertex(x1,y1,z1+WALL);
      g.vertex(x2,y2,z2+WALL);
      g.vertex(x2,y2,z2-WALL);
      g.vertex(x1,y1,z1-WALL);
      g.endShape();
    }
  }
  void drawArrow(float[] c, boolean fleeing){
    float z_base = max(c[2], map.getWaterLevel(c[0],c[1]));
    float upShift = 100+40*sin((ticks/40.0)*2*PI);
    g.pushMatrix();
    g.translate(random(-10,10)+unloop_two(c[0],camera[0]),unloop_two(c[1],camera[1]),z_base+upShift);
    g.rotateZ((ticks/20.0)*2*PI);
    g.scale(0.6);
    g.fill(fleeing ? color(255,0,0) : color(0,255,0));
    g.beginShape();
    g.vertex(0,0,0);
    g.vertex(100,0,100);
    g.vertex(-100,0,100);
    g.endShape(CLOSE);
    g.beginShape();
    g.vertex(50,0,100);
    g.vertex(50,0,200);
    g.vertex(-50,0,200);
    g.vertex(-50,0,100);
    g.endShape(CLOSE);
    g.popMatrix();
  }
  void drawBody(){
    if(getSpeciesType(species) == 0){
      drawFlower();
      return;
    }
    if(getSpeciesType(species) >= 1){
      float elev = map.getGroundLevel(coor);
      if(coor[2] <= elev){
        float step = T*0.2;
        
        float elev_front = map.getGroundLevel(advance(coor, step, 0));
        float angle_FB = atan2(elev_front-elev, step);
        tilt[1] += unloop_angle(-angle_FB-tilt[1])*0.2;
        
        float elev_side = map.getGroundLevel(advance(coor, 0, step));
        float angle_LR = atan2(elev_side-elev, step);
        tilt[0] += unloop_angle(-angle_LR-tilt[0])*0.2;
        
        g.rotateX(tilt[0]);
        g.rotateY(tilt[1]);
      }
    }
    drawStickFigure();
  }
  
  float[] advance(float[] coor, float step_front, float step_side){
    float ang = coor[3];
    float dx = step_front*cos(ang)+step_side*sin(ang);
    float dy = step_front*sin(ang)-step_side*cos(ang);
    float[] newCoor = deepCopy(coor);
    newCoor[0] += dx;
    newCoor[1] += dy;
    return newCoor;
  }
  
  void drawFlower(){
    g.pushMatrix();
    g.scale(0.15+trait.size);
    
    float HEIGHT = 75;
    float[] WIDTHS = {7,30};
    
    g.pushMatrix();
    g.fill(0,80,0);
    g.translate(0,0,HEIGHT/2);
    g.box(WIDTHS[0],WIDTHS[0],HEIGHT);
    g.popMatrix();
    
    g.pushMatrix();
    g.fill(0,160,0);
    g.translate(0,0,HEIGHT-HEIGHT/2*trait.size);
    g.box(WIDTHS[0]+1,WIDTHS[0]+1,HEIGHT*trait.size);
    g.popMatrix();
    
    g.pushMatrix();
    g.translate(0,0,HEIGHT);
    g.rotateZ(trait.size*10*2*PI);
    g.rotateX(0.7);
    g.scale(1,1,0.5);
    g.fill(255,255,0);
    if(species == 1){
      g.fill(255,255,255);
    }
    g.sphere(WIDTHS[1]*0.65);
    g.fill(SPECIES_COLORS[species]);
    if(!edible()){
      g.fill(inedibilize(SPECIES_COLORS[species]));
    }
    for(int p = 0; p < 5; p++){
      g.pushMatrix();
      g.rotateZ(2*PI*p/5.0);
      g.rotateY(0.2*sin(trait.size*100+p*1.61803*2*PI));
      if(species == 0){
        g.ellipse(WIDTHS[1],0,WIDTHS[1],WIDTHS[1]*0.8);
      }else{
        g.beginShape();
        g.vertex(0,-WIDTHS[1]*0.5,0);
        g.vertex(0,WIDTHS[1]*0.5,0);
        g.vertex(WIDTHS[1]*2,0,0);
        g.endShape();
      }
      g.popMatrix();
    }
    g.popMatrix();
    g.popMatrix();
  }
  
  void drawStickFigure(){
    float walk_swing = sin(millis()*0.04*walk_speed);
    float walk_swing2 = sin(millis()*0.052*walk_speed);
    float idle_swing = sin(millis()*0.003*walk_speed);
    boolean inAir = (coor[2] > map.getGroundLevel(coor));
    if(inAir){
      walk_swing = 0;
      walk_swing2 = 0;
      idle_swing = 0;
    }
    float SCALE_Y = 10;
    float SCALE_Z = 10;
    if(walk_speed >= 0.001){
      SCALE_Z = 10+walk_swing2;
    }else{
      SCALE_Z = 10+0.26*idle_swing;
    }
    float limbW = 3;
    color limbColor = color(50,50,50);
    drawLimbs(SCALE_Y, SCALE_Z, limbW, inAir, walk_swing, limbColor);
    
    color bodyColor;
    
    if(species == -1){
      bodyColor = color(160,160,160);
    }else{
      bodyColor = SPECIES_COLORS[species];
      if(keyHandler.canControl == true){
        if(this == closest_AI && this != controlledAgent){
           trait.drawDisplay();
           bodyColor = colorLerp(SPECIES_COLORS[species], color(255,255,255),0.5+0.5*sin(frameCount));
        }
      }else{
        if(this == closest_AI){
           trait.drawDisplay();
           bodyColor = colorLerp(SPECIES_COLORS[species], color(255,255,255),0.5+0.5*sin(frameCount));
        }
      }
    }
    g.fill(bodyColor);
    
    float HEAD_R = 20;
    float BODY_HEIGHT = ((getSpeciesType(species)+1)%3 == 0) ? 4 : 2; 
    g.pushMatrix();
    g.translate(0,0,BODY_HEIGHT*SCALE_Z+HEAD_R);
    g.sphere(HEAD_R);
    if(getSpeciesType(species) == 1){ 
      for(int i = 0; i < 2; i++){
        float s = i*2-1;
        g.beginShape();
        g.vertex(0,s*HEAD_R*0.5, HEAD_R*1.6);
        g.vertex(HEAD_R*0.1,s*HEAD_R*0.1, HEAD_R*0.9);
        g.vertex(-HEAD_R*0.1,s*HEAD_R*0.8, HEAD_R*0.6);
        g.endShape(CLOSE);
      }
    }
    
    boolean awake = (topPriority != 3);
    drawFace(HEAD_R, 2, awake);
    g.popMatrix();
    
    if(getSpeciesType(species) == 1){ 
      if(edible()){
        g.fill(bodyColor);
      }else{
        g.fill(inedibilize(bodyColor));
      }
      float meat = (2*trait.priorities[0]+0.05)*SCALE_Y;
      g.pushMatrix();
      g.translate(-2*SCALE_Y,0,2*SCALE_Y);
      g.box(4*SCALE_Y+limbW+meat*0.2,meat,meat);
      g.popMatrix();
    }
  }
  
  color inedibilize(color c){
    return color(190,190,190);
  }

  void drawLimbs(float SCALE_Y, float SCALE_Z, float W, boolean inAir, float walk_swing, color c){
    float[][][] bodies2 = {   
      {{0,0,4,0,0},{0,0,4,-1,-1},{0,0,4,1,1},{0,0,2,-1,1},{0,0,2,1,-1}},
      {{0,0,2,-1,-1},{0,0,2,1,1},{-4,0,2,-1,1},{-4,0,2,1,-1}}
    };
      
    float[][] lines = bodies2[(getSpeciesType(species) == 1 ? 1 : 0)]; 
    for(int i = 0; i < lines.length; i++){
      g.fill(c);
      g.beginShape();
      float dangleX = 0;
      
      if(i >= 1 && walk_speed >= 0.001){
        dangleX = walk_swing;
      }
      float flyMulti = 1.0;
      if(inAir){
        flyMulti *= (12-velo[2])*0.1;
      }
      
      g.pushMatrix();
      g.translate(lines[i][0]*SCALE_Z,lines[i][1]*SCALE_Y,lines[i][2]*SCALE_Z);
      g.rotateX((lines[i][3]*0.06*flyMulti*(1+0.2*dangleX))*(2*PI));
      g.rotateY(dangleX*lines[i][4]*0.10*(2*PI));
      float boxLength = 2*SCALE_Z;
      if(inAir && lines[i][3] != 0){
        boxLength *= 1.2;
      }
      g.translate(0,0,-boxLength/2);
      g.box(W,W,boxLength);
      g.popMatrix();
    }
  }
  
  void drawFace(float HEAD_R, float W, boolean awake){
    g.pushMatrix();
    g.rotateZ(-PI/2);
    g.translate(0,HEAD_R*0.9,0);
    g.rotateX(PI/2);
    g.fill(0,0,0);
    if(awake){
      for(int i = 0; i < 2; i++){
        g.rect(HEAD_R*(i-0.5)*0.6-W*0.5,W*1,W*1,W*4);
      }
      int mealAge = (ticks-trait.timeOfLastMeal);
      if(mealAge < 30 && mealAge%4 < 2){
        drawOpenMouth(g, HEAD_R, 1);
      }else{
        drawSmile(g,HEAD_R*0.5,W,10);
      }
    }else{
      for(int i = 0; i < 2; i++){
        g.pushMatrix();
        g.translate(HEAD_R*(i-0.5)*0.8,W*2.5,-HEAD_R*0.05);
        drawSmile(g,HEAD_R*0.2,W*0.8,5);
        g.popMatrix();
      }
      drawOpenMouth(g, HEAD_R, 0.4+0.2*sin(ticks*(2*PI)/50));
    }
    g.popMatrix();
  }
  
  void drawSmile(PGraphics img, float radius, float W, int pieces){
    img.beginShape();
    for(int i = 0; i <= pieces; i++){
      float ang = ((float)i)/pieces*PI*0.8+PI*1.1;
      float x = cos(ang)*(radius-W/2);
      float y = sin(ang)*(radius-W/2);
      img.vertex(x,y,0);
    }
    for(int i = pieces; i >= 0; i--){
      float ang = ((float)i)/pieces*PI*0.8+PI*1.1;
      float x = cos(ang)*(radius+W/2);
      float y = sin(ang)*(radius+W/2);
      img.vertex(x,y,0);
    }
    img.endShape(CLOSE);
  }

  void drawOpenMouth(PGraphics img, float HEAD_R, float OPEN_NESS){
    img.pushMatrix();
    img.translate(0,-HEAD_R*0.35,HEAD_R*(0.2+0.2*(1-OPEN_NESS)));
    img.fill(0);
    img.scale(1,0.8*OPEN_NESS,0.8);
    img.sphere(HEAD_R*0.52);
    img.popMatrix();
  }
  
  boolean isSleeping(){
    return (topPriority == 3);
  }

  boolean isAgentDoingAction(int n){
    if(this == controlledAgent && isSleeping()){
      return false;
    }

    if(this == controlledAgent){
      if(keyHandler.canControl == true || this.species == -1){
        return keyHandler.keysToAction(n);
      }else{
        return animalKeyPresses[n];
      }
    }else{
      return animalKeyPresses[n];
    }
  }

  void search(int topPriority){
    if(topPriority == 0){ 
      target = findTarget(1);
    }else if(topPriority == 1){ 
      target = findWater();
    }else if(topPriority == 2){ 
      target = findTarget(0);
    }else if(topPriority == 4){ 
      target = predator;
    }else if(topPriority == 5){ 
      target = recentChild;
    }
  }
  
  float getSoonCoor(int dim){
    return coor[dim]+7*velo[dim];
  }
  
  void pathfind(int topPriority){
    for(int i = 0; i < animalKeyPresses.length; i++){
      animalKeyPresses[i] = false;
    }
    if(target == null){
      if(topPriority <= 2){ 
        animalKeyPresses[7] = true; 
      }
      return;
    }
    
    if(topPriority <= 2 || topPriority == 5){ 
      float dx = unloop(target.getSoonCoor(0)-getSoonCoor(0));
      float dy = unloop(target.getSoonCoor(1)-getSoonCoor(1));
      float distance = dist(0,0,dx,dy);
      float angle = unloop_angle(atan2(dy, dx)-coor[3])/(2*PI);
      if(angle <= -0.03){
        animalKeyPresses[5] = true; 
      }else if(angle >= 0.03){
        animalKeyPresses[6] = true; 
      }
      
      float angleWindow = (distance <= T*3) ? 0.3 : 0.05;
      if(abs(angle) < angleWindow){ 
        animalKeyPresses[1] = true;
        if(random(0,1) < 0.03 && distance >= T){
          animalKeyPresses[4] = true; 
        }
        if(random(0,1) < 0.5){
          if(angle >= 0.05 && angle < 0.45){ 
            animalKeyPresses[0] = true;
          }else if(angle <= -0.05 && angle > -0.45){
            animalKeyPresses[2] = true;
          }
        }
      }
    }else if(topPriority == 4){ 
      float dx = unloop(coor[0]-target.coor[0]);
      float dy = unloop(coor[1]-target.coor[1]);
      float angle = unloop_angle(atan2(dy, dx)-coor[3])/(2*PI);
      if(angle <= -0.1){
        animalKeyPresses[5] = true; 
      }else if(angle >= 0.1){
        animalKeyPresses[6] = true; 
      }
      if(abs(angle) < 0.25){
        animalKeyPresses[1] = true; 
        if(random(0,1) < 0.03){
          animalKeyPresses[4] = true; 
        }
      }
      animalKeyPresses[4] = true; 
    }
  }
  
  boolean isExertingMotion(){
    for(int i = 0; i < 5; i++){
      if(isAgentDoingAction(i)){
        return true;
      }
    }
    return false;
  }
  
  void doPriorities(){
    for(int i = 0; i < PRIORITY_NAMES.length; i++){
      float drainRate = PRIORITY_RATES[species][i] * 0.00003;
      if(drainRate == 0){
        continue;
      }
      if(i == 2){
        if(isSleeping()){
          drainRate = 0;
        }else{
          // Higher fertility scale increases freakiness/mating urge build-up rate
          float fertilityUrgeBoost = (trait.stats[4]*2-1)*0.25;
          drainRate *= (0.2 + 0.8 * trait.priorities[0]) * (fertilityUrgeBoost+1);
        }
      }
      if(i == 1){
        drainRate *= trait.getMetabolicDrainMultiplier();
      }
      if(i == 0){
        if(!isExertingMotion()){
          drainRate *= 0.15 * trait.getMetabolicDrainMultiplier()*trait.getVisionHungerMultiplier();
        } else {
          // SPEED TRADE-OFF: Moving faster consumes proportionally more hunger
          drainRate *= trait.getSpeedHungerMultiplier() * trait.getMetabolicDrainMultiplier()*trait.getStaminaHungerMultiplier()*trait.getVisionHungerMultiplier();
        }
      }
      trait.priorities[i] = min(max(trait.priorities[i]-drainRate,PRIORITY_CAPS[i]),1.0);
      if(trait.priorities[i] <= 0 && i < 2){ 
        die(true);
      }
    }

    float cap = PRIORITY_CAPS[3];
    trait.priorities[3] = cap+(1-cap)*daylight();
    if(ticks%TICK_BUCKET_COUNT == tick_bucket){
      predator = findTarget(2);
      if(predator == null){
        trait.priorities[4] = 1.0;
      }else{
        float dx = unloop(coor[0]-predator.coor[0])/T;
        float dy = unloop(coor[1]-predator.coor[1])/T;
        trait.priorities[4] = min(max((dist(0,0,dx,dy)-1)/3.5,0),1);
      }
    }
    
    int nextPriority = ArrayUtils.argsort(trait.priorities, true)[0];
    boolean REFRESH = (ticks%TICK_BUCKET_COUNT == tick_bucket || nextPriority != topPriority);
    if(REFRESH){
      search(nextPriority);
    }
    pathfind(nextPriority);
    topPriority = nextPriority;
  }

  boolean isPreferredFood(int mySpecies, int targetSpecies) {
    if (mySpecies == 6) return targetSpecies == 8; // Green Cow prefers Green Flower
    if (mySpecies == 7) return targetSpecies == 6; // Green Predator prefers Green Cow
    return false;
  }

  Player findTarget(int targetType) { 
    if (targetType != 1) {
      Player recordHolder = null;
      float distanceRecord = VISION_DISTANCE + trait.getVisionOffset();
      for (int i = 0; i < players.size(); i++) {
        Player other = players.get(i);
        if (species <= -1 || other.species <= -1 || other == this) continue;
        if ((targetType == 0 && species != other.species) || 
            (targetType == 2 && !IS_FOOD[other.species][species])) continue;
      
        float distance = d_loop(coor, other.coor, false);
        if (distance < distanceRecord) {
          distanceRecord = distance;
          recordHolder = other;
        }
      }
      return recordHolder;
    }

    int primaryFood = -1;
    int secondaryFood = -1;
    int tertiaryFood = -1;

    // Define Food Hierarchy per Species
    if (species == 2) {        // Yellow Cow
      primaryFood = 0;   // Pink Flower
      secondaryFood = 1; // Ice Flower
      tertiaryFood = 8;  // Green Flower
    } else if (species == 3) { // Teal Cow
      primaryFood = 1;   // Ice Flower
      secondaryFood = 0; // Pink Flower
      tertiaryFood = 8;  // Green Flower
    } else if (species == 6) { // Green Cow
      primaryFood = 8;   // Green Flower
      secondaryFood = 0; // Pink Flower
      tertiaryFood = 1;  // Ice Flower
    } else if (species == 4) { // Orange Predator
      primaryFood = 2;   // Yellow Cow
      secondaryFood = 3; // Teal Cow
      tertiaryFood = 6;  // Green Cow
    } else if (species == 5) { // Blue Predator
      primaryFood = 3;   // Teal Cow
      secondaryFood = 2; // Yellow Cow
      tertiaryFood = 6;  // Green Cow
    } else if (species == 7) { // Green Predator
      primaryFood = 6;   // Green Cow
      secondaryFood = 2; // Yellow Cow
      tertiaryFood = 3;  // Teal Cow
    }

    Player primaryTarget = searchFoodBySpecies(primaryFood);
    if (primaryTarget != null) return primaryTarget;

    Player secondaryTarget = searchFoodBySpecies(secondaryFood);
    if (secondaryTarget != null) return secondaryTarget;

    return searchFoodBySpecies(tertiaryFood);
  }
  
  Player searchFoodBySpecies(int targetSpecies) {
    if (targetSpecies == -1) return null;
  
    Player recordHolder = null;
    float distanceRecord = VISION_DISTANCE + trait.getVisionOffset();
  
    for (int i = 0; i < players.size(); i++) {
      Player other = players.get(i);
      if (other.species != targetSpecies || !other.edible()) continue;

      float distance = d_loop(coor, other.coor, false);
      if (distance < distanceRecord) {
        distanceRecord = distance;
        recordHolder = other;
      }
    }
    return recordHolder;
  }
  
  boolean edible(){
    if(getSpeciesType(species) == 0){
      return (trait.size >= 0.25 && trait.size <= 0.75);
    }else{
      return (trait.priorities[0] >= 0.25 && trait.priorities[0] <= 0.75);
    }
  }
  
  Player findWater(){
    int ix = (int)unloop(coor[0]/T+0.5);
    int iy = (int)unloop(coor[1]/T+0.5);
    int[] closestWater = map.closestWater[ix%SIZE][iy%SIZE];
    float[] coor = {closestWater[0]*T,closestWater[1]*T,0,0};
    Player waterTarget = new Player(-2, coor, false, false, 0.5,0.5,0,null, null); 
    return waterTarget;
  }
  
  void doActions(KeyHandler keyHandler){
    if(getSpeciesType(species) == 0){ 
      return;
    }
    if(getSpeciesType(species) >= 1){ 
      doPriorities();
    }
    float r = coor[3];
    walk_speed = -1.0;
    for(int i = 0; i < ACTION_COUNT; i++){
      if(i == 7){
        if(isAgentDoingAction(i) && wander_action >= 1){
          walk_speed = 0.3;
        }
      }else if(isAgentDoingAction(i)){
        walk_speed = 1.0;
      }
    }
    
    float baseSpeed = (species <= -1) ? 1.0 : SPECIES_SPEED[species];
    float finalSpeed = baseSpeed * trait.getSpeedModifier();
    
    float HUNGER_MULT = 1.0;
    if(getSpeciesType(species) == 1 || getSpeciesType(species) == 2 || getSpeciesType(species) == 3){
      HUNGER_MULT = 1.0-0.25*min(trait.priorities[0],1.0);
    }
    if(isAgentDoingAction(3)){
      velo[0] -= cos(r)*ACCEL*finalSpeed*HUNGER_MULT;
      velo[1] -= sin(r)*ACCEL*finalSpeed*HUNGER_MULT;
    }
    if(isAgentDoingAction(1)){
      velo[0] += cos(r)*ACCEL*finalSpeed*HUNGER_MULT;
      velo[1] += sin(r)*ACCEL*finalSpeed*HUNGER_MULT;
    }
    if(isAgentDoingAction(2)){
      velo[0] -= sin(r)*ACCEL*finalSpeed*HUNGER_MULT;
      velo[1] += cos(r)*ACCEL*finalSpeed*HUNGER_MULT;
    }
    if(isAgentDoingAction(0)){
      velo[0] += sin(r)*ACCEL*finalSpeed*HUNGER_MULT;
      velo[1] -= cos(r)*ACCEL*finalSpeed*HUNGER_MULT;
    }
    
    if(isAgentDoingAction(7)){ 
      if(ticks%TICK_BUCKET_COUNT == tick_bucket){
        wander_action = (int)random(0,4); 
      }
      if(wander_action == 1){
        velo[0] += cos(r)*WANDER_ACCEL*finalSpeed*HUNGER_MULT;
        velo[1] += sin(r)*WANDER_ACCEL*finalSpeed*HUNGER_MULT;
      }else if(wander_action == 2){
        coor[3] -= ACCEL*0.05;
      }else if(wander_action == 3){
        coor[3] += ACCEL*0.05;
      }
    }
    
    if(isAgentDoingAction(4) && coor[2] <= map.getGroundLevel(coor) && velo[2] <= 1){
      velo[2] = 18;
      pawd(5, 0.1);
    }
    if(isAgentDoingAction(5)){ 
      coor[3] -= ACCEL*0.05;
    }
    if(isAgentDoingAction(6)){
      coor[3] += ACCEL*0.05;
    }
  }

  void pawd(int n, float volume){ 
    float dist_ = d_loop(camera, coor, true);
    float MAX_DIST = 4.3*T;
    if(dist_ >= MAX_DIST){
      return;
    }
    float vol = volume*(1-pow(dist_/MAX_DIST,0.4));
    
    sfx[n].rate(random(0.7,1.4));
    sfx[n].amp(vol);
    sfx[n].play();
  }

  boolean onGround(){
    return (coor[2] <= map.getGroundLevel(coor));
  }

  void plantPhysics(){
    if(!onGround()){
      return;
    }
    
    // Ideal terrain elevation profiles per flower species
    float[] IDEAL_HEIGHTS = {0.39, 0.72, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.55};
    float elev = min(map.getGroundLevel(coor)/T/map.ELEV_FACTOR,0.78); 
    float fertility = min(map.getFertilityLevel(coor)/T/map.FERTILITY_FACTOR,1); 
    float offby = abs(elev-IDEAL_HEIGHTS[species]);
    float elev_factor = 0.05+0.95*pow(min(max(1-offby/0.25,0),1),1.6);
    float fert_factor = fertility * 2; 
    
    float overp_factor = max(0.0,1.0-(getCurrentTile().occupants.size())/MAX_PER_TILE);
    float growth_speed = 0;
    
    // Check for all 3 flower species (0, 1, and 8)
    if(species == 0 || species == 1 || species == 8){
      growth_speed = 0.01+elev_factor*overp_factor*daylight()*fert_factor*trait.getMetabolicDrainMultiplier();
    }
    
    trait.size += growth_speed*random(0.001,0.002)*PRIORITY_RATES[species][0];
    
    if(trait.size >= 1){ 
      trait.size -= 0.5;
      float seedMutation = random(0, 20); 
      int nextSpecies = species;
      
      // Seed mutation across flower types
      if(seedMutation > 19){
        float r = random(0, 1);
        if(species == 0)
          nextSpecies = 8;
        else if(species == 1)
          nextSpecies = 8;
        else if(species == 8) 
          if(r > 0.5)
            nextSpecies = 0;
          else
            nextSpecies = 1;
      }
      
      Player newPlayer = new Player(nextSpecies, coor, true, false, 0.5, 0.5, trait.generation+1, trait.name, trait.stats);
      players.add(newPlayer);
      trait.children.add(newPlayer.trait.name);
      pawd(12, 0.1);
    }
  }

  void doPhysics(Map map){
    prevCoor = deepCopy(coor);
    
    if(getSpeciesType(species) == 0){
      plantPhysics();
    }
    
    boolean STARTED_ON_GROUND = (coor[2] <= map.getGroundLevel(coor));
    
    for(int d = 0; d < DIM_COUNT+1; d++){
      coor[d] += velo[d];
      if(d != 2 && getSpeciesType(species) != 0){ 
        velo[d] *= FRICTION;
      }
      if(d < 2){ 
        while(coor[d] >= SIZE*T){
          tweakDim(d, -SIZE*T);
        }
        while(coor[d] < 0){
          tweakDim(d, SIZE*T);
        }
      }
    }
    switchTile();
    float ground = map.getGroundLevel(coor);
    if(velo[2] <= 0 && STARTED_ON_GROUND){
      coor[2] = ground;
    }
    if(coor[2] <= ground){
      if(velo[2] <= -10){ 
        pawd(6, 0.2);
      }
      coor[2] = ground;
      velo[2] = 0;
      if(getSpeciesType(species) == 0 && !plant_landed){
        if(random(0,1) < 0.5){
          velo = newBurst(false);
        }else{
          velo[0] = 0;
          velo[1] = 0;
          plant_landed = true;
          if(getCurrentTile().occupants.size() > MAX_PER_TILE){
            die(false);
          }
        }
      }
    }else{
      velo[2] -= 1; 
    }
    if (topPriority == 0 && target != null && !target.toDie && species >= 0 && target.species >= 0
        && IS_FOOD[species][target.species] && target.edible()) { 
  
      float _dist = dist(coor[0], coor[1], coor[2], target.coor[0], target.coor[1], target.coor[2]);
      if (_dist < COLLISION_DISTANCE) { 
        target.die(true); 
    
        float gainedCalories;
        if (getSpeciesType(target.species) == 0) { 
          gainedCalories = CALORIES_RATE[target.species] * target.trait.size;
        } else {
          gainedCalories = CALORIES_RATE[target.species] * target.trait.priorities[0];
        }

        boolean isSecondary = false;
        boolean isTertiary = false;

        // Check food preference penalties
        if ((species == 2 && target.species == 1) || 
            (species == 3 && target.species == 0) || 
            (species == 6 && target.species == 0) || 
            (species == 4 && target.species == 3) || 
            (species == 5 && target.species == 2) ||
            (species == 7 && target.species == 2)) { 
          isSecondary = true;
        } else if ((species == 2 && target.species == 8) ||
                   (species == 3 && target.species == 8) ||
                   (species == 6 && target.species == 1) ||
                   (species == 4 && target.species == 6) ||
                   (species == 5 && target.species == 6) ||
                   (species == 7 && target.species == 3)) {
          isTertiary = true;
        }

        if (isSecondary) {
          gainedCalories *= 0.75;
        } else if (isTertiary) {
          gainedCalories *= 0.5;
        }

        trait.priorities[0] = min(1.0, trait.priorities[0] + gainedCalories);
        pawd((int)random(7, 12), 0.2);
        trait.timeOfLastMeal = ticks;
      }
    }
    if(topPriority == 1 && coor[2] < map.getWaterLevel(coor[0],coor[1])){ 
      trait.priorities[1] = min(1.0, trait.priorities[1]+WATER_CALORIES); 
      trait.mc += 1;
    }
    if(topPriority == 2 && target != null &&
    species >= 0 && target.species >= 0 && species == target.species){ 
      float _dist = dist(coor[0],coor[1],coor[2],target.coor[0],target.coor[1],target.coor[2]);
      if(_dist < COLLISION_DISTANCE){ 
        float hungerForOffspring = (trait.priorities[0]+target.trait.priorities[0])/3.0;
        trait.priorities[0] -= trait.priorities[0]/3.0;
        target.trait.priorities[0] -= target.trait.priorities[0]/3.0;
        trait.priorities[5] = 0.0; 
        target.trait.priorities[5] = 0.0; 
        float thirstForOffspring = (trait.priorities[1]+target.trait.priorities[1])/2.0;
        
        String parents = trait.name+" and "+target.trait.name;

        // FERTILITY MULTI-CHILD SPATIAL SPAWNING
        int numOffspring = int(random(1, 3));
        for (int k = 0; k < numOffspring; k++) {
          float mutationChance = random(0,20); 
          int offspringSpecies = species;
          
          float r = random(0,1);
          
          if(mutationChance > 19){
            if(species == 2)
              offspringSpecies = 6;
            else if(species == 3)
              offspringSpecies = 6;
            else if(species == 6)
              if(r > 0.5)
                offspringSpecies = 2;
              else
                offspringSpecies = 3;
          }

          Player newPlayer = new Player(offspringSpecies, coor, true, false, hungerForOffspring, thirstForOffspring, trait.generation+1, parents, trait.stats);
          players.add(newPlayer);
          trait.children.add(newPlayer.trait.name);
          target.trait.children.add(newPlayer.trait.name);
          recentChild = newPlayer;
          target.recentChild = newPlayer;
        }

        trait.priorities[2] = min(1.0, trait.priorities[2]+0.25); 
        pawd(13, 0.2);
      }
    }
    if(coor[2] < map.getWaterLevel(coor[0],coor[1]) && prevCoor[2] >= map.getWaterLevel(coor[0],coor[1])){
      pawd((int)random(0,5), 0.3); 
    }
    trait.age += 1;

    // METABOLISM-MODIFIED LIFESPAN DYNAMICS
    float lifeMult = trait.getMetabolicLifespanMultiplier();
    if(getSpeciesType(species) == 1){
      if(trait.age >= (16000+trait.extraLifespan) * lifeMult){ 
        die(true); 
      }
    }else if(getSpeciesType(species) == 2){
      if(trait.age >= (20000+trait.extraLifespan) * lifeMult){ 
        die(true);
      }
    }else if(getSpeciesType(species) == 0){
      if(trait.age >= (10000+trait.extraLifespan) * lifeMult){ 
        die(true);
      }
    }
  }

  void die(boolean playOof){
    if(playOof && getSpeciesType(species) >= 1){
      pawd(14, 0.25);
    }
    leaveTile();
    toDie = true;
  }
  void tweakDim(int d, int amt){
    coor[d] += amt;
    if(species == -1){
      camera[d] += amt;
    }
  }
  void lag(int LEN, float[] arr, float[] dest, float amt){
    for(int i = 0; i < LEN; i++){
      arr[i] += unloop(dest[i]-arr[i])*amt;
    }
  }
  void snapCamera(boolean withHeadRotation){
    if(withHeadRotation){
      coor[3] = camera[3];
    }else if(followSpecimen && this == closest_AI){
      if(!isSleeping() && this == controlledAgent && keyHandler.canControl == true){
          coor[3] = camera[3];
      }
    }

    if(keyHandler.keysDown[10]){
      camera[3] += 0.01;
    }
    lag(3,camera,coor,0.13);
    float HEIGHT_ABOVE_PLAYER = 50;
    g.translate(0,0,(g.height/2.0)/tan(PI*30.0 / 180.0)-DISTANCE_FROM_PLAYER);
    g.rotateX(PI*0.46-camera[4]);
    g.rotateZ(-camera[3]-PI/2);
    g.translate(-camera[0],-camera[1],-camera[2]-HEIGHT_ABOVE_PLAYER);
  }
}
