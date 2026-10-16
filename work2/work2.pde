//5. Convert multiple images into a particle system. Particles start in a random scattered state,
//triggered by a mouse click to converge into the shape of the image.
//After completion, automatically switch to the next image, and finally fade out to exit.

//First click: Start the program, particles are in a random scattered state
//Click the screen: Trigger the composition effect, all particles move to target positions

import java.util.Iterator;

//Image and particle system variables
PImage[] images; //Store multiple images (as target shapes)
ArrayList<Particle> particles; //Store all particle objects for the current image
int sampleStep = 3; //Sampling step size, controls particle density

//Program startup control variables
boolean programStarted = false; //Whether the program has started running

//Composition mode related variables
boolean composing = false; //Whether in composition mode
boolean waitingForClick = true; //Waiting for mouse click to start composition
float globalComposeSpeed = 5000; //Composition speed
int currentImageIndex = 0; //Index of the current image to compose
boolean allImagesDone = false; //Whether all images have been composed

//Particle target position storage
ArrayList<PVector> targetPositions; //Store target positions for each particle

//Particle initial spread parameters
int particleCount = 0; //Number of particles calculated from the current image
float randomSpreadRadius = 300; //Radius for particles to randomly spread

//Fade effect related variables
boolean fading = false; //Whether fading is in progress
float fadeAlpha = 0; //Fade transparency (0-255)
int fadeDuration = 2000; //Fade duration (milliseconds)
int fadeStartTime; //Timestamp when fade starts (milliseconds)
boolean fastFading = false; //Whether fast fading is enabled

//Initialization settings
void setup() {
  size(800, 600);
  
  //Define the array of image filenames to load
  String[] imageNames = {"zhuaermu.jpg", "daimao.jpg", "feixiongyingwu.jpg"};
  images = new PImage[imageNames.length];
  
  //Loop to load all images
  for (int i = 0; i < imageNames.length; i++) {
    images[i] = loadImage(imageNames[i]);
    if (images[i] == null) {  //Check if image loaded successfully
      println("Failed to load image: " + imageNames[i]);
      exit();  //Exit if loading fails
    }
    images[i].resize(width, height);
  }
  
  //Initialize particle system for the first image (particles in random scattered state with target positions)
  initParticlesWithTargets(images[currentImageIndex]);
  println("Image " + (currentImageIndex + 1) + "/" + images.length + ", Particle count: " + particles.size());
  println("Program started, click the screen to begin...");
}

//Main drawing loop
//Executes automatically every frame, responsible for updating particle states, drawing the screen,
//checking composition completion, and handling fade effects
void draw() {
  //If program hasn't started, show pure black screen
  if (!programStarted) {
    background(0);
    return;
  }
  
  background(0);
  
  //Update and draw all particles (stop displaying when last image is done and fading)
  if (!allImagesDone || (allImagesDone && !fading)) {
    Iterator<Particle> it = particles.iterator();
    while (it.hasNext()) {
      Particle p = it.next();
      p.update();
      p.display();
    }
  } else if (allImagesDone && fading) {
    //Continue displaying particles when fading after last image completes
    Iterator<Particle> it = particles.iterator();
    while (it.hasNext()) {
      Particle p = it.next();
      p.update();
      p.display();
    }
  }
  
  //Check if all particles have approached their target positions
  if (composing && !allImagesDone) {
    boolean allArrived = true;
    for (Particle p : particles) {
      if (!p.isArrived()) {
        allArrived = false;
        break;
      }
    }
    
    if (allArrived) {
      //Current image composition complete, auto switch to next image
      println("Image " + (currentImageIndex + 1) + " composition completed!");
      switchToNextImage();
    }
  }
  
  //Draw fade layer
  if (fading && allImagesDone) {
    float elapsed = millis() - fadeStartTime; //Calculate elapsed fade time
    float targetDuration = fastFading ? 500 : fadeDuration; //Fast fade 0.5s, normal 2s
    
    if (elapsed >= targetDuration) {
      //Fade complete, full black screen
      fill(0, 0, 0, 255);
      noStroke();
      rect(0, 0, width, height);
    } else {
      //Calculate current transparency (linear interpolation from 0 to 255)
      fadeAlpha = (elapsed / targetDuration) * 255;
      fill(0, 0, 0, fadeAlpha);
      noStroke();
      rect(0, 0, width, height);
    }
  }
}

//Mouse click interaction
void mousePressed() {
  //State 1: Program not started: First click to start program
  if (!programStarted) {
    programStarted = true;
    println("Program started running...");
    println("Click mouse to start composition effect (particles will converge into image shape)...");
    println("Click again to force switch to next image");
    return;
  }
  
  //State 2: All images done and fading: Click again to trigger fast fade
  if (allImagesDone && fading && !fastFading) {
    fastFading = true;
    println("Triggering fast fade effect...");
    return;
  }
  
  //State 3: All images done and not fading: Start fade effect
  if (allImagesDone && !fading) {
    fading = true;
    fadeStartTime = millis();  //Record start time
    fastFading = false;
    println("All images completed, starting fade effect (click to speed up)...");
    return;
  }
  
  //If all images completed, ignore other clicks
  if (allImagesDone) return;
  
  //State 4: Waiting for click state: Start composition effect
  if (waitingForClick && particles.size() > 0) {
    composing = true;
    waitingForClick = false;
    println("Starting composition effect (particles converging into image shape)...");
  } 
  //State 5: Already composing: Force switch to next image
  else if (composing && !allImagesDone) {
    println("Forcing switch to next image...");
    switchToNextImage();
  }
}

//Switch images
void switchToNextImage() {
  if (currentImageIndex + 1 < images.length) {
    currentImageIndex++;
    initParticlesWithTargets(images[currentImageIndex]);
    composing = false; 
    waitingForClick = true;
    println("Switched to image " + (currentImageIndex + 1) + "/" + images.length + ", Particle count: " + particles.size());
    println("Click mouse to start composition effect...");
  } else {
    //All images composed, prepare for fade effect
    allImagesDone = true;
    composing = false;
    println("All images composition completed! Click the screen to start fade effect...");
  }
}

//Initialize particle system
// 1. Calculate target positions for each particle based on target image
// 2. Create same number of particles with initial positions at random locations
// 3. Store target position for each particle for subsequent movement

// Parameter img: Target image to convert
void initParticlesWithTargets(PImage img) {
  particles = new ArrayList<Particle>();
  targetPositions = new ArrayList<PVector>();
  
  img.loadPixels();  //Load image pixel data into memory
  
  // 1. Collect all valid sampling points as target positions
  for (int y = 0; y < img.height; y += sampleStep) {
    for (int x = 0; x < img.width; x += sampleStep) {
      int pixelColor = img.pixels[y * img.width + x];
      //Only sample non-transparent and sufficiently bright pixels (these form the key shape of the image)
      if (alpha(pixelColor) > 0 && brightness(pixelColor) > 10) {
        targetPositions.add(new PVector(x, y));
      }
    }
  }
  
  particleCount = targetPositions.size(); //Record total particle count
  
  // 2. Create one particle for each target position
  // Set particle initial position to random location
  // Particle color is based on the color of the target position in the original image
  for (int i = 0; i < particleCount; i++) {
    PVector target = targetPositions.get(i);
    //Get color of target position (read from original image)
    int pixelColor = img.pixels[int(target.y) * img.width + int(target.x)];
    color col = pixelColor;
    
    float randX = random(width);
    float randY = random(height);
    
    //Create particle
    particles.add(new Particle(randX, randY, target, col));
  }
}

//Particle class
//Represents one sampling point in the image, with properties: current position, target position, velocity, color
//Particles wander randomly when waiting, converge to target position when composing
class Particle {
  //Position and motion properties
  PVector pos;   
  PVector vel;        
  PVector target; 
  
  //Visual properties
  color col; //Particle color
  
  //Behavior parameters
  float arrivalDist; //Distance threshold for reaching target
  float speedFactor; //Movement speed factor
  float friction; //Friction coefficient for smoother motion
  
  //Constructor: Create a new particle
  //Parameters x, y: Initial particle position
  //Parameter t: Target position of the particle
  //Parameter c: Color of the particle
  Particle(float x, float y, PVector t, color c) {
    pos = new PVector(x, y);                              
    vel = new PVector(random(-1, 1), random(-1, 1));       
    target = t.copy();                                       
    col = c;                                               
    arrivalDist = 1.5;                                      
    speedFactor = 0.9;                                       
    friction = 0.92;                                        
  }
  
  //Update particle state
  void update() {
    if (composing) {
      //Particle moves toward target with inertia for natural motion
      PVector dir = PVector.sub(target, pos);
      float distance = dir.mag(); //Calculate distance to target
      if (distance > 0.1) {
        dir.normalize();                       
        vel.add(PVector.mult(dir, speedFactor));
        if (vel.mag() > 3.0) {
          vel.limit(3.0); //Limit max speed to prevent excessive movement
        }
      }
      //Snap directly to target when very close to prevent tiny jitter
      if (distance < arrivalDist) {
        pos = target.copy();                   
        vel.mult(0.9);                    
      }
    } else {
      //Particles do Brownian motion/random wander when not composing
      //Stay scattered, avoid natural clustering
      vel.add(new PVector(random(-0.3, 0.3), random(-0.3, 0.3))); //Random acceleration
      if (vel.mag() > 2.0) {
        vel.limit(2.0); //Limit max speed
      }
    }
    
    //Apply velocity and update position
    pos.add(vel);
    vel.mult(friction); //Apply friction to slow down
    
    //Boundary constraint: Keep particles within screen
    pos.x = constrain(pos.x, 0, width);
    pos.y = constrain(pos.y, 0, height);
  }
  
  //Draw particle on canvas
  void display() {
    float alphaVal = 255;
    if (composing) {
      float distToTarget = PVector.dist(pos, target);
      //More opaque when closer to target, semi-transparent far away for fade-in effect
      alphaVal = map(distToTarget, 0, 100, 255, 80);
      alphaVal = constrain(alphaVal, 80, 255);
    } else {
      alphaVal = 180;
    }
    fill(red(col), green(col), blue(col), alphaVal); //Set fill color
    noStroke();
    ellipse(pos.x, pos.y, 2.5, 2.5); //Draw circular particle with 2.5px radius
  }
  
  //Check if particle has reached target position
  boolean isArrived() {
    return PVector.dist(pos, target) < arrivalDist;
  }
}
