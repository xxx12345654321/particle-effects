//2.Ocean Wave Perlin Noise Particle System

//Mouse drag trail changes to orange and remains permanently
//Black screen at start, click to begin; fades to black after 10 seconds, click to exit when fully black


//Flow Field Parameters
FlowField flowField;//Flow field object
int flowFieldScale = 20;// Flow field resolution, smaller value = denser grid
float noiseScale = 0.005;// Noise sampling precision
float noiseStrength = 1.5;// Noise influence strength

//Particle System Parameters
ArrayList<Particle> particles;//Stores all particle objects
int particleCount = 42500;//Total number of particles

// Visual Parameters
float trailAlpha = 3;// Trail residual transparency
float particleSpeed = 0.01;// Particle movement speed

//Mouse Interaction Parameters
PVector mousePos; // Current coordinates
boolean mouseDragging = false; // Whether dragging is in progress
float mouseInfluenceRadius = 30; //Mouse influence radius

//Program Flow Control
boolean programStarted = false;//Whether the program has started running

// Fade Effect Parameters
int startTime;// Timestamp when the program starts running
boolean fading = false;//Whether fade effect is in progress
float fadeAlpha = 0;//Current fade layer transparency (0-255)
int fadeDuration = 2000;//Fade duration
int fadeStartTime;//Timestamp when fade effect starts
boolean fullyFaded = false;//Whether fully black screen
boolean canExit = false;//Whether program exit is allowed

//Initialization Settings
void setup() {
  size(800, 600);  
  colorMode(HSB, 360, 100, 100, 100); 
  background(0); 
  
  //Initialize mouse position variables
  mousePos = new PVector(mouseX, mouseY);
  
  //Initialize flow field
  flowField = new FlowField(flowFieldScale, noiseScale, noiseStrength);
  
  //Initialize particle system
  particles = new ArrayList<Particle>();
  for (int i = 0; i < particleCount; i++) {
    particles.add(new Particle());  //Create particle objects one by one
  }
  
  smooth();//Anti-aliasing
}

//Main Drawing Loop
void draw() {
  //State 1: Program not started, display pure black screen
  if (!programStarted) {
    background(0);
    return;
  }
  
  //State 2: Fully black screen, stop drawing particle effects
  if (!fullyFaded) {
    //Draw trail - translucent rectangle overlay for trailing effect
    fill(210, 70, 15, trailAlpha);
    noStroke();
    rect(0, 0, width, height);
    
    //Update flow field
    flowField.updateNoiseOffset(frameCount * 0.002);
    
    for (Particle p : particles) {
      float angle = flowField.getAngle(p.pos.x, p.pos.y);
      PVector force = new PVector(cos(angle), sin(angle));
      force.mult(particleSpeed);
      
      p.applyForce(force);//Apply flow field force
      applyMouseForce(p);//Apply mouse attraction force
      p.update();  //Update particle position and velocity
      p.edgesWrap();//Edge wrapping handling
      p.display();  //Draw particle on canvas
    }
    
    //Check if 10-second runtime reached, trigger fade effect
    if (!fading && (millis() - startTime >= 10000)) {
      fading = true;
      fadeStartTime = millis();
      println("10 seconds reached, starting fade effect...");
    }
  }
  
  //Draw fade layer
  if (fading && !fullyFaded) {
    float elapsed = millis() - fadeStartTime;
    if (elapsed >= fadeDuration) {
      fill(0, 0, 0, 255);
      noStroke();
      rect(0, 0, width, height);
      fullyFaded = true;
      canExit = true;//Click to exit
      println("Fade complete, click screen to exit program");
    } else {
      //Calculate current transparency during fade
      fadeAlpha = (elapsed / fadeDuration) * 255;
      fill(0, 0, 0, fadeAlpha);
      noStroke();
      rect(0, 0, width, height);
    }
  }
}

//Mouse Click Event
void mousePressed() {
  // State 1: Program not started, first click to launch
  if (!programStarted) {
    programStarted = true;
    startTime = millis();//Record start time for 10-second countdown
    background(210, 70, 15);//Clear black screen, display dark blue background
    println("Program started running...");
    return;
  }
  
  //State 2: Fully black screen and exit allowed, click to exit program
  if (fullyFaded && canExit) {
    println("Exiting program");
    exit();                      
  }
  
  // State 3: Normal interaction mode, start drag marking
  mouseDragging = true;
  mousePos.set(mouseX, mouseY);
}

//Mouse Release Event
// Stop drag state when mouse button is released
void mouseReleased() {
  mouseDragging = false;
}

// ==================== Mouse Drag Event ====================
// Update mouse position coordinates in real-time during drag
void mouseDragged() {
  mousePos.set(mouseX, mouseY);
}

// Mouse Influence Application
// Apply mouse attraction force to specified particle
// Particles that are attracted will be permanently marked as orange
void applyMouseForce(Particle p) {
  if (!mouseDragging) return;
  
  float d = PVector.dist(p.pos, mousePos);  //Calculate distance from particle to mouse
  if (d < mouseInfluenceRadius) {
    // Calculate attraction: particle pulled toward mouse position, stronger when closer
    PVector force = PVector.sub(mousePos, p.pos);
    float strength = map(d, 0, mouseInfluenceRadius, 0.8, 0);
    force.normalize();
    force.mult(strength * 0.5);
    p.applyForce(force);
    
    //Once attracted by mouse, permanently mark particle as orange (color change remains permanent)
    p.setToOrange();
  }
}


// Flow Field Class
// Generates dynamic vector field based on Perlin Noise to provide movement direction for particles

class FlowField {
  int cols, rows;// Number of grid columns and rows
  float[][] angles;// Angle value for each grid cell
  float resolution; // Grid resolution
  float noiseScale;// Noise sampling scale
  float noiseStrength;// Noise intensity
  float noiseZ;//Z-axis offset of noise
  
  //Constructor: Initialize flow field
  FlowField(float res, float nScale, float nStrength) {
    this.resolution = res;
    this.noiseScale = nScale;
    this.noiseStrength = nStrength;
    this.noiseZ = 0;
    
    //Calculate grid count (ensure full screen coverage)
    cols = ceil(width / resolution) + 1;
    rows = ceil(height / resolution) + 1;
    angles = new float[cols][rows];
    
    updateAngles();  //Initial calculation of all angles
  }
  
  //Update time offset
  void updateNoiseOffset(float offset) {
    noiseZ = offset;
    updateAngles();//Recalculate angles
  }
  
  //Recalculate angle values for all cells in grid
  void updateAngles() {
    for (int i = 0; i < cols; i++) {
      for (int j = 0; j < rows; j++) {
        float x = i * resolution;          
        float y = j * resolution;  
        float noiseVal = noise(x * noiseScale, y * noiseScale, noiseZ);//Sample Perlin Noise
        angles[i][j] = noiseVal * TWO_PI * noiseStrength;//Map noise value to angle
      }
    }
  }
  
  // Get corresponding flow field angle based on pixel position
  float getAngle(float px, float py) {
    px = constrain(px, 0, width);//Boundary constraint
    py = constrain(py, 0, height);
    
    float fx = px / resolution;//Grid floating coordinates
    float fy = py / resolution;
    int gx = floor(fx);//Grid integer coordinates
    int gy = floor(fy);
    
    //Boundary clamping to prevent array out of bounds
    gx = constrain(gx, 0, cols - 1);
    gy = constrain(gy, 0, rows - 1);
    int gxNext = constrain(gx + 1, 0, cols - 1);
    int gyNext = constrain(gy + 1, 0, rows - 1);
    
    float tx = fx - gx;// X-direction interpolation factor
    float ty = fy - gy; // Y-direction interpolation factor
    
    //Get angle values of four adjacent grids
    float angleTL = angles[gx][gy];
    float angleTR = angles[gxNext][gy];
    float angleBL = angles[gx][gyNext];
    float angleBR = angles[gxNext][gyNext];
    
    //Bilinear interpolation to calculate final angle
    float angleTop = lerp(angleTL, angleTR, tx);
    float angleBottom = lerp(angleBL, angleBR, tx);
    return lerp(angleTop, angleBottom, ty);
  }
}


// Particle Class
// Represents a moving particle in the flow field with position, velocity, acceleration and lifespan
// Orange color remains permanently after mouse touch
class Particle {
  PVector pos;       // Current position
  PVector vel;       // Current velocity
  PVector acc;       // Current acceleration (cumulative force per frame)
  float life;        // Lifespan (decreases over time, resets at zero)
  float maxSpeed = 2.5;   // Maximum speed limit
  
  // Color state: false = blue mode (default original effect), true = orange mode (touched by mouse)
  boolean isOrange = false;
  
  // Constructor: Randomly initialize particle starting position and lifespan
  Particle() {
    pos = new PVector(random(width), random(height));
    vel = new PVector(0, 0);
    acc = new PVector(0, 0);
    life = random(200, 300);
  }
  
  // Apply force (Euler integration, force added directly to acceleration)
  void applyForce(PVector force) {
    acc.add(force);
  }
  
  // Update particle physical state (velocity, position, lifespan)
  void update() {
    vel.add(acc);// Acceleration changes velocity
    vel.limit(maxSpeed);// Limit maximum speed
    pos.add(vel);// Velocity changes position
    acc.mult(0); // Reset acceleration after each frame
    
    life -= 0.15;               
    if (life < 0) {
      reset(); //Reset particle
    }
  }
  
  // Permanently mark as orange
  void setToOrange() {
    isOrange = true;
  }
  
  // Reset particle
  void reset() {
    pos.set(random(width), random(height));
    vel.set(0, 0);
    life = random(80, 120);
    //Marked particles remain orange after respawn
  }
  
  //Edge wrapping: Particles reappear on opposite side when exiting screen bounds
  void edgesWrap() {
    if (pos.x > width) pos.x = 0;
    if (pos.x < 0) pos.x = width;
    if (pos.y > height) pos.y = 0;
    if (pos.y < 0) pos.y = height;
  }
  
  // Draw particle
  void display() {
    float hue, sat, bri, alphaVal;
    
    // Select different color schemes based on color mode
    if (isOrange) {
      //Orange mode
      hue = 30 + sin(frameCount * 0.05 + pos.x * 0.01) * 5;
      hue = constrain(hue, 20, 45);
      sat = map(life, 0, 100, 70, 95);//Saturation changes with lifespan
      float speed = vel.mag();
      bri = map(speed, 0, maxSpeed, 60, 100); //Brightness changes with speed
      alphaVal = map(life, 0, 100, 30, 85);//Transparency changes with lifespan
    } else {
      //Blue mode
      hue = map(pos.x / width, 0, 1, 190, 230);//Hue gradients with X coordinate
      hue += sin(pos.y * 0.01) * 10; //Add sine wave fluctuation
      hue = constrain(hue, 180, 250);
      sat = map(life, 0, 100, 40, 85);//Saturation changes with lifespan
      float speed = vel.mag();
      bri = map(speed, 0, maxSpeed, 40, 95);//Brightness changes with speed
      alphaVal = map(life, 0, 100, 20, 80);//Transparency changes with lifespan
    }
    
    // Draw thin lines to simulate particle movement trails
    strokeWeight(0.4);//Thin line width
    stroke(hue, sat, bri, alphaVal);
    
    //Draw small line segments for trailing visual effect
    PVector prev = PVector.sub(pos, vel.copy().normalize().mult(2));
    line(pos.x, pos.y, prev.x, prev.y);
  }
}
