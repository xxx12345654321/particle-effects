//1. Convert multiple images into a particle system, users control the particle dissipation process by clicking the mouse

//First click: Start the program, the current image particles begin to dissipate slowly
//Click during dissipation: Accelerate the dissipation speed
//Automatically switch to the next image after all particles of the current image disappear
//Click to exit the program after all images are displayed

import java.util.Iterator;

//Image and particle system variables

PImage[] images;//Array storing all images to be displayed
ArrayList<Particle> particles;//ArrayList storing all particle objects generated from the current image
int sampleStep = 3; //Sample one particle every 3 pixels, smaller value means denser particles

//Dissipation state control

boolean dissipating = false;//Whether to dissipate slowly
float globalDissipateSpeed = 0.008; //Slow dissipation speed

boolean fastDissipating = false;//Whether to dissipate rapidly
float fastDissipateSpeed = 0.04;//Rapid dissipation speed

//Program flow control

int currentImageIndex = 0;//Index of the displayed image
boolean waitingForClick = true;//Wait for user click to start image dissipation
boolean programStarted = false;//Whether the program has started (black screen at the beginning)
boolean waitingForExitClick = false;// Whether waiting for user click to exit the program
boolean allImagesDone = false;//Whether all images have been completely dissipated

// ==================== Initialization Settings ====================
// Executed once when the program starts, responsible for setting the canvas, loading images, and initializing the particle system
void setup() {
  size(800, 600);  // Set canvas width 800 pixels, height 600 pixels
  
  //Loaded images
  String[] imageNames = {"zhuaermu.jpg", "daimao.jpg", "feixiongyingwu.jpg"};
  images = new PImage[imageNames.length];
  
  for (int i = 0; i < imageNames.length; i++) {
    images[i] = loadImage(imageNames[i]);
    if (images[i] == null) {
      println("Failed to load image: " + imageNames[i]);
      exit();
    }
    images[i].resize(width, height);
  }
  
  initParticles(images[currentImageIndex]);//Initialize the particle system based on the first image
}

//Initialize the particle system
//Convert image pixels into particle objects, each particle represents a sampling point
void initParticles(PImage img) {
  particles = new ArrayList<Particle>();
  img.loadPixels();
  
  //Traverse each pixel of the image with a step size, skip some pixels to control the number of particles
  for (int y = 0; y < img.height; y += sampleStep) {
    for (int x = 0; x < img.width; x += sampleStep) {
      int pixelColor = img.pixels[y * img.width + x];  //Get the current pixel color
      if (alpha(pixelColor) > 0 && brightness(pixelColor) > 10) {//Only keep non-fully black (brightness > 10) pixels as particles to avoid sampling black background
        particles.add(new Particle(x, y, pixelColor));
      }
    }
  }
}

//Main drawing loop
void draw() {
  background(0);
  if (!programStarted) {
    return;
  }
  
  if (allImagesDone) {
    return;
  }
  
  //Traverse all particles using an iterator
  Iterator<Particle> it = particles.iterator();
  while (it.hasNext()) {
    Particle p = it.next();
    p.update();//Update particle position and lifespan
    p.display();//Draw the particle on the canvas
    if (p.isDead()) {//Remove the particle from the list if its lifespan is exhausted
      it.remove();
    }
  }
  
  // Check if all particles of the current image have disappeared
  if (particles.size() == 0 && !allImagesDone) {
    //Switch to the next image if there is one
    if (currentImageIndex + 1 < images.length) {
      currentImageIndex++;
      initParticles(images[currentImageIndex]);
      //Reset states
      dissipating = false;
      fastDissipating = false;
      waitingForClick = true;
    } else {
      //All images displayed, mark as completed and wait for click to exit
      allImagesDone = true;
      waitingForExitClick = true;
    }
  }
}

//Mouse click interaction
void mousePressed() {
  // State 1: Program not started: First click to start the program
  if (!programStarted) {
    programStarted = true;
    dissipating = true;
    waitingForClick = false;
    return;
  }
  
  //State 2: All images completed: Click to exit the program
  if (allImagesDone && waitingForExitClick) {
    exit();
    return;
  }
  
  //State 3: During slow dissipation: Accelerate dissipation
  if (dissipating && !fastDissipating && particles.size() > 0 && programStarted && !allImagesDone) {
    fastDissipating = true;
    return;
  }
  
  //State 4: Waiting for click to dissipate: Push particles around the mouse
  if (waitingForClick && particles.size() > 0 && programStarted && !allImagesDone) {
    float radius = 80;//Influence radius
    float strength = 1.5;//Push strength
    
    //Traverse all particles, apply force to particles within the radius around the mouse
    for (Particle p : particles) {
      float d = dist(mouseX, mouseY, p.pos.x, p.pos.y);
      if (d < radius) {
        float forceMag = (1 - d/radius) * strength;
        PVector dir = PVector.sub(p.pos, new PVector(mouseX, mouseY));
        dir.normalize();
        p.vel.add(PVector.mult(dir, forceMag));//Add velocity to the particle and directly reduce particle lifespan
        p.life = max(0, p.life - forceMag * 0.3);
      }
    }
    
    //Start dissipation mode
    dissipating = true;
    waitingForClick = false;
  }
}

//Particle class, represents a sampling point in the image, with properties such as position, velocity, color, and lifespan
class Particle {
  PVector pos;//Current position of the particle
  PVector vel;//Current velocity of the particle
  float friction;//Friction coefficient
  
  color col;//Color of the particle
  float life;//Particle lifespan
  
  //Create a new particle
  //x, y: Initial particle position
  //c: Particle color
  Particle(float x, float y, color c) {
    pos = new PVector(x, y);//Initial position
    vel = new PVector(random(-0.5, 0.5), random(-0.5, 0.5)); //Random initial velocity
    col = c;//Color
    life = 1.0;//Full initial lifespan
    friction = 0.98;//Friction coefficient
  }
  
  //Update the particle's state
  void update() {
    pos.add(vel);//Update position based on velocity
    vel.mult(friction);//Apply friction to decelerate
    
    //Determine the lifespan reduction speed based on the program's global dissipation state
    if (fastDissipating) {
      life -= fastDissipateSpeed;//Rapid dissipation mode
    } else if (dissipating) {
      life -= globalDissipateSpeed;//Slow dissipation mode
    } else {
      life -= 0.0005;//Extremely slow decay in standby mode
    }
    life = constrain(life, 0, 1);//Restrict lifespan between 0 and 1
  }
  
  //Draw the particle on the canvas
  void display() {
    int alphaVal = int(life * 255);//Transparency is proportional to lifespan (higher life = more opaque)
    fill(red(col), green(col), blue(col), alphaVal);//Set fill color (keep original color, adjust transparency)
    noStroke();
    ellipse(pos.x, pos.y, 2, 2);//Draw a circular particle with 2-pixel radius
  }
  
  //Determine if the particle is dead (based on lifespan)
  boolean isDead() {
    return life <= 0.01;//Considered dead if lifespan is below 1%
  }
}
