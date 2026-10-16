//4. Click to eliminate pollution: first eliminate air pollution on the left, then water pollution on the right
import java.util.Iterator;

PImage img;// Original image object
ArrayList<Particle> particles; // Stores all current particle objects
int sampleStep = 3;// Sampling step size, controls particle density (sample one particle every 3 pixels)

//Dissipation phase control
// Phase 0: Dissipation not started, display complete image
// Phase 1: Left 2/3 area dissipation (particles drift left)
// Phase 2: Full image dissipation (right 1/3 area particles drift right)
// Phase 3: Full screen black (fade effect)
int dissipatePhase = 0;
boolean isFadingToBlack = false;  // Whether blackening effect is in progress

//Dissipation speed parameters
float normalDissipateSpeed = 0.008;  // Normal dissipation speed (used in phase 1)
float fastDissipateSpeed = 0.02;     // Fast dissipation speed (used in phase 2)

//Blackening effect parameters
float blackness = 0;// Transparency of black mask 0-255
float fadeToBlackSpeed = 3; // Blackening speed

//Interaction state
int clickCount = 0;// Record mouse clicks, maximum 3 times

// Save a copy of the right 1/3 area of the image
PImage rightPartImage = null;

boolean leftPartDissipated = false;// Mark whether left particles have completely dissipated

//Exit control
boolean fullyBlack = false;// Whether fully black screen (blackening effect completed)
boolean canExit = false;// Whether program exit is allowed (only allowed after black screen completes)

//Initialization settings
void setup() {
  size(800, 600);
  
  //Load image
  img = loadImage("pollute.png");
  if (img == null) {
    println("Failed to load image! Please check the image path");
    exit();
  }
  img.resize(width, height);// Adjust image size to fit canvas
  
  //Pre-crop the right 1/3 area of the image
  rightPartImage = img.get(int(img.width * 2.0 / 3.0), 0, 
                           img.width - int(img.width * 2.0 / 3.0), img.height);
  
  // Initialize particle system
  initParticlesByPhase();
}

//Initialize particle system based on phase
// Generate particles only for specified areas based on current dissipatePhase value
// Phase 0: No particles generated (display complete image)
// Phase 1: Only generate particles for left 2/3 area
// Phase 2: Only generate particles for right 1/3 area
// Phase 3: No particles generated (direct blackening)
void initParticlesByPhase() {
  particles = new ArrayList<Particle>();
  img.loadPixels();// Load image pixel array for color reading
  
  for (int y = 0; y < img.height; y += sampleStep) {
    for (int x = 0; x < img.width; x += sampleStep) {
      int pixelColor = img.pixels[y * img.width + x];
      
      // Determine if current pixel should generate a particle
      boolean shouldCreateParticle = false;
      
      if (dissipatePhase == 0) {
        // Phase 0: Dissipation not started, no particles generated
        shouldCreateParticle = false;
      } else if (dissipatePhase == 1) {
        // Phase 1: Only generate particles for left 2/3 area
        if (x < img.width * 2.0 / 3.0) {
          shouldCreateParticle = true;
        }
      } else if (dissipatePhase == 2) {
        // Phase 2: Only generate particles for right 1/3 area
        if (x >= img.width * 2.0 / 3.0) {
          shouldCreateParticle = true;
        }
      } else if (dissipatePhase == 3) {
        // Phase 3: No new particles generated
        shouldCreateParticle = false;
      }
      
      // Only keep non-fully black (brightness >10) and non-transparent pixels as particles
      if (shouldCreateParticle && alpha(pixelColor) > 0 && brightness(pixelColor) > 10) {
        particles.add(new Particle(x, y, pixelColor));
      }
    }
  }
}

//Main drawing loop

void draw() {
  // Draw black background first
  background(0);
  
  if (dissipatePhase == 0) {
    // Phase 0: Display complete original image, no particles shown
    image(img, 0, 0);
  } else {
    // Phases 1, 2, 3: Display non-particle area of original image + particle effects
    
    // Draw non-particle areas (preserved original image areas)
    if (dissipatePhase == 1) {
      // Phase 1: Only draw right 1/3 of original image
      image(rightPartImage, img.width * 2.0 / 3.0, 0);
    } else if (dissipatePhase == 2) {
      // Phase 2: Left area completely dissipated, right area dissipating
      // No original image drawn, only particle effects displayed
    }
    // Phase 3: All areas turned to particles or blackening, no original image drawn
    
    //Update and display all particles
    Iterator<Particle> it = particles.iterator();
    while (it.hasNext()) {
      Particle p = it.next();
      p.update();    
      p.display();  
      if (p.isDead()) {
        it.remove();
      }
    }
  }
  
  //Phase 3: Apply black mask
  if (isFadingToBlack) {
    // Increase transparency of black mask frame by frame
    blackness += fadeToBlackSpeed;
    if (blackness > 255) {
      blackness = 255;  // Upper limit 255
    }
    
    // Draw black translucent mask
    fill(0, 0, 0, blackness);
    noStroke();
    rect(0, 0, width, height);
    
    // If completely black, mark state and wait for user click to exit
    if (blackness >= 255 && !fullyBlack) {
      fullyBlack = true;
      canExit = true;
      isFadingToBlack = false;
      println("Fully black screen, click screen to exit program");
    }
  }
  
  //Check if current phase is completed
  checkPhaseCompletion();
}

//Check phase completion status
//Determine if particles in current phase have completely dissipated, and decide whether to enter next phase
void checkPhaseCompletion() {
  // Conditions: current phase has particles, all particles dissipated, and not in blackening process
  if (particles.size() == 0 && dissipatePhase > 0 && dissipatePhase < 3 && !isFadingToBlack) {
    
    // Phase 1 completed: mark left dissipated, wait for user's second click
    if (dissipatePhase == 1) {
      leftPartDissipated = true;
      //Phase 1 completed, do not auto-enter phase 2, wait for user's second click to trigger
    }
    
    // Phase 2 completed: auto-enter phase 3
    if (dissipatePhase == 2) {
      dissipatePhase = 3;
      isFadingToBlack = true;
      particles.clear();  //No particles needed for phase 3, clear particle list
    }
  }
}

// Mouse click event
// Handle three clicks: first starts left dissipation, second starts right dissipation, third triggers blackening
// Click to exit program after blackening completes
void mousePressed() {
  // State 1: Fully black screen and exit allowed, click to exit program
  if (fullyBlack && canExit) {
    println("Exiting program");
    exit(); 
  }
  
  //Maximum 3 clicks handled
  if (clickCount >= 3) {
    return;
  }
  
  clickCount++;
  
  //Execute different operations based on click count
  switch(clickCount) {
    case 1:
      // First click: start particle dissipation for left 2/3 area
      dissipatePhase = 1;
      initParticlesByPhase();//Reinitialize particles, left 2/3 area
      break;
      
    case 2:
      // Second click: start particle dissipation for right 1/3 area
      // Clear all existing particles
      particles.clear();
      
      dissipatePhase = 2;
      initParticlesByPhase(); //Reinitialize particles, right 1/3 area
      break;
      
    case 3:
      // Third click: directly enter blackening phase
      particles.clear();
      
      dissipatePhase = 3;
      isFadingToBlack = true;
      blackness = 0;//Reset black mask transparency, start fading from 0
      break;
  }
}


// Particle class
// Represents a sampling point particle in the image, with properties: position, velocity, color, lifespan
// Drifts left in phase 1, drifts right in phase 2, with gravity and friction effects
class Particle {
  PVector pos;// Current position of particle
  PVector vel;// Current velocity of particle
  color col;// Color of particle
  float life; // Particle lifespan
  float friction;// Friction coefficient
  
  // Constructor: create new particle
  // x, y: initial particle position
  // c: particle color
  Particle(float x, float y, color c) {
    pos = new PVector(x, y);
    
    //Set initial particle velocity (drift direction) based on dissipation phase
    if (dissipatePhase == 1) {
      // Phase 1: Left particles drift left
      vel = new PVector(random(-2, -0.5), random(-1, 1));
    } else if (dissipatePhase == 2) {
      // Phase 2: Right particles drift right
      vel = new PVector(random(0.5, 2), random(-1, 1));
    } else {
      float centerX = width / 2;
      float directionX = (x < centerX) ? random(-1.5, -0.5) : random(0.5, 1.5);
      vel = new PVector(directionX, random(-1, 1));
    }
    
    col = c;
    life = 1.0;// Full initial lifespan
    friction = 0.98; // Friction coefficient
  }
  
  // Update particle state (position, velocity, lifespan)
  void update() {
    pos.add(vel);        // Update position based on velocity
    vel.mult(friction);  // Apply friction to gradually decelerate
    
    // Determine lifespan decay speed based on current dissipation phase
    if (dissipatePhase == 1) {
      // Phase 1: Use normal dissipation speed
      life -= normalDissipateSpeed;
    } else if (dissipatePhase == 2) {
      // Phase 2: Use fast dissipation speed
      life -= fastDissipateSpeed;
    } else if (dissipatePhase == 3) {
      // Phase 3: Use faster dissipation speed
      life -= fastDissipateSpeed * 1.5;
    }
    
    life = constrain(life, 0, 1);  //Restrict lifespan between 0 and 1
    
    // Add gravity effect to make particles fall slowly
    vel.y += 0.1;
  }
  
  // Draw particle on canvas
  void display() {
    int alphaVal = int(life * 255);  //Transparency proportional to lifespan
    fill(red(col), green(col), blue(col), alphaVal);
    noStroke();
    //Particle size decreases as lifespan decreases
    float particleSize = map(life, 0, 1, 1, 3);
    ellipse(pos.x, pos.y, particleSize, particleSize);
  }
  
  // Determine if particle is dead: lifespan and boundary check
  boolean isDead() {
    return life <= 0.01 ||                   
           pos.x < -50 ||                    
           pos.x > width + 50 ||            
           pos.y < -50 ||                   
           pos.y > height + 50;             
  }
}
