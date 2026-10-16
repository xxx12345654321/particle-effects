// Realistic Glass Crack Effect + Dark Red Artistic Text Slogan
// Black screen at start, click to begin + Black screen at end, click to exit
// Use Minim Library to play sound effects

import java.util.ArrayList;
import ddf.minim.*;

//Sound Effects Related (Minim Library)
Minim minim;              
AudioPlayer glassSound1; 
AudioPlayer glassSound2;
AudioPlayer glassSound3;   
boolean soundLoaded = false;  //Flag for successful sound effect loading

//Crack Related
ArrayList<GlassCrack> allCracks = new ArrayList<GlassCrack>();  //Store all crack objects
int clickCount = 0;//Record first 4 mouse clicks to generate cracks, 4th click triggers phase switch

//Phase Control
int stage = -1;// Current stage: -1=Black screen waiting, 0=Crack generation + text display, 1=Fade out, 2=Text fade in, 3=Text breathing effect, 4=Fade to black exit
float fadeAlpha = 0;// Transparency for fade out/black effect (0-255)
float brightAlpha = 0; // Brightness value for text fade in (0-255)
int textDisplayStart = 0; // Timestamp when text display starts (ms)
boolean textDisplayed = false;  //Flag for completed text display

//Artistic Font
PFont artFont; 

//Other Flags
boolean earlyEndTriggered = false;  //Whether early end has been triggered
boolean canExit = false; //Whether program exit is allowed

public void settings() {
    size(800, 600);
}

//Initialization Settings

public void setup() {
    background(0); // Initial background is black
    strokeWeight(1); // Default line thickness 1 pixel
    noFill(); // Default no fill
    textAlign(CENTER, CENTER);  // Text center alignment (horizontal + vertical)
    
    // Initialize Minim and load sound effects
    try {
        minim = new Minim(this);
        glassSound1 = minim.loadFile("glassbroken1.wav"); 
        glassSound2 = minim.loadFile("glassbroken2.wav"); 
        glassSound3 = minim.loadFile("glassbroken3.wav"); 
        soundLoaded = true;
        println("Minim sound effects loaded successfully");
    } catch (Exception e) {
        println("Minim sound effects loading failed: " + e);
        soundLoaded = false;
    }
    
    //Load artistic font
    String[] fontList = PFont.list(); 
    String selectedFont = "Georgia"; 
    String[] artisticFonts = {"Zapfino", "Georgia Italic", "Times New Roman", "Adobe Garamond Pro", "Palatino Linotype", "Georgia"};
    
    for (String preferred : artisticFonts) {
        for (String available : fontList) {
            if (available.toLowerCase().contains(preferred.toLowerCase())) {
                selectedFont = available;
                break;
            }
        }
    }
    
    artFont = createFont(selectedFont, 60, true);// Create font object, size 60, anti-aliasing enabled
    textFont(artFont);//Set as current active font
}

//Main Drawing Loop

public void draw() {
    if (stage == -1) {
        // Stage -1: Program startup waiting state, display pure black screen
        background(0);
        
    } else if (stage == 0) {
        // Stage 0: Crack generation + Dark red artistic text display
        background(0);
        
        // Draw all glass cracks
        for (GlassCrack c : allCracks) {
            c.display();
        }
        
        // First line text content (display in lines)
        String message = "They are extinct\nor endangered";
        
        pushMatrix();// Save current transformation matrix
        translate(width/2, height/2);  // Move to canvas center
        
        // Shadow effect (dark offset)
        fill(80, 0, 0, 180);
        text(message, 3, 3);
        
        // Main text (dark red)
        fill(139, 0, 0);
        text(message, 0, 0);
        
        // Stroke effect (semi-transparent red stroke)
        stroke(180, 50, 50, 100);
        strokeWeight(1.5);
        noFill();
        text(message, 0, 0);
        noStroke();  // Restore no stroke state
        
        // Slight motion blur effect (multiple subtle offset overlays)
        for (int i = 0; i < 3; i++) {
            fill(139, 0, 0, 30);
            text(message, random(-1, 1), random(-1, 1));
        }
        
        popMatrix();  //Restore transformation matrix
        
    } else if (stage == 1) {
        // Stage 1: Fade out from cracks & text to black screen
        fill(0, fadeAlpha);  // Black translucent mask
        noStroke();
        rect(0, 0, width, height);
        
        fadeAlpha += 6;  // Increase transparency per frame for fade out
        if (fadeAlpha >= 255) {
            fadeAlpha = 255;
            stage = 2;// Enter next stage
            brightAlpha = 0;// Reset brightness value
        }
        
    } else if (stage == 2) {
        // Stage 2: New text fades in from black screen
        background(0);
        
        float brightness = brightAlpha / 255.0;// Calculate current brightness ratio (0-1)
        int r = (int)(139 * brightness); // Red component increases from 0 to 139
        
        String message = "Will you protect them?"; // Second paragraph text content
        
        pushMatrix();
        translate(width/2, height/2);
        
        // Shadow effect
        fill(80 * brightness, 0, 0, 180 * brightness);
        text(message, 3, 3);
        
        // Main text
        fill(r, 0, 0);
        text(message, 0, 0);
        
        // Stroke effect
        stroke(180 * brightness, 50 * brightness, 50 * brightness, 100 * brightness);
        strokeWeight(1.5);
        noFill();
        text(message, 0, 0);
        noStroke();
        
        popMatrix();
        
        brightAlpha += 8;  // Increase brightness per frame for fade in
        if (brightAlpha >= 255) {
            brightAlpha = 255;
            stage = 3;                      
            textDisplayStart = millis(); // Record text display start time
            textDisplayed = true;// Mark text display completed
        }
        
    } else if (stage == 3) {
        // Stage 3: Auto enter end after displaying for 3 seconds
        background(0);
        
        String message = "Will you protect them?";
        
        pushMatrix();
        translate(width/2, height/2);
        
        // Fixed shadow
        fill(80, 0, 0, 180);
        text(message, 3, 3);
        
        // Fixed main text
        fill(139, 0, 0);
        text(message, 0, 0);
        
        // Fixed stroke
        stroke(180, 50, 50, 100);
        strokeWeight(1.5);
        noFill();
        text(message, 0, 0);
        noStroke();
        
        //Extra overlay text with transparency varying by sine wave
        float breath = 0.8f + 0.2f * sin(millis() * 0.002f);  // Breathing coefficient (fluctuates between 0.6-1.0)
        fill(139, 0, 0, 50 * breath);
        text(message, random(-1, 1), random(-1, 1));
        
        popMatrix();
        
        // Auto enter end stage after 3 seconds
        if (textDisplayed && millis() - textDisplayStart > 3000) {
            stage = 4;  // Enter end stage
            fadeAlpha = 0;// Reset transparency
            canExit = false;// Exit not allowed temporarily
        }
        
    } else if (stage == 4) {
        // Stage 4: Fade to black effect and wait for user click to exit
        fill(0, fadeAlpha);
        noStroke();
        rect(0, 0, width, height);
        
        fadeAlpha += 4;  // Increase transparency per frame
        if (fadeAlpha >= 255) {
            fadeAlpha = 255;
            fill(0);
            rect(0, 0, width, height);
            canExit = true;
        }
    }
}

//Mouse Click Event
public void mousePressed() {
    // State 1: Program not started (Stage -1), first click starts animation
    if (stage == -1) {
        stage = 0;
        println("Starting animation...");
        return;
    }
    
    // State 2: Stage 0 and click count < 4 times, generate cracks and play sound effects
    if (stage == 0 && clickCount < 4) {
        // Play sound effects for first 3 clicks
        if (clickCount < 3 && soundLoaded) {
            // Play corresponding glass break sound effect based on click count
            switch(clickCount + 1) {
                case 1:
                    glassSound1.rewind(); // Reset audio stream to start
                    glassSound1.play(); // Play sound effect
                    println("Playing sound 1");
                    break;
                case 2:
                    glassSound2.rewind();
                    glassSound2.play();
                    println("Playing sound 2");
                    break;
                case 3:
                    glassSound3.rewind();
                    glassSound3.play();
                    println("Playing sound 3");
                    break;
            }
        }
        
        generateGlassBreak(mouseX, mouseY);  // Generate glass crack at click position
        clickCount++;  
        
        // Enter Stage 1 (fade out effect) after 4th click
        if (clickCount == 4) {
            stage = 1;
            fadeAlpha = 0;
        }
        return;
    }
    
    // State 3: Click in Stage 3 triggers quick end
    if (stage == 3 && !earlyEndTriggered) {
        earlyEndTriggered = true;
        stage = 4; // Directly enter end stage
        fadeAlpha = 0;
        canExit = false; // Wait for fade to black completion
        println("Triggering quick fade to end...");
        return;
    }
    
    // State 4: Exit allowed in Stage 4, click to exit program
    if (stage == 4 && canExit) {
        println("Exiting program");
        // Release sound resources to avoid memory leaks
        if (soundLoaded) {
            glassSound1.close();
            glassSound2.close();
            glassSound3.close();
            minim.stop();
        }
        exit(); 
    }
}

// Generate Realistic Glass Cracks
// Generate multi-layer crack system at specified click position, simulating real glass shattering effect
// Includes: Radial main cracks, connecting cracks, fine debris cracks, spiderweb closed areas
// Center X coordinate of crack
// Center Y coordinate of crack
void generateGlassBreak(float cx, float cy) {
    // 1. Radial main cracks (radiate outward from center)
    int radialCount = (int) random(6, 10);  // Main crack count (6-10)
    for (int i = 0; i < radialCount; i++) {
        float angle = (TWO_PI / radialCount) * i + random(-PI/12, PI/12); 
        float length = random(120, 220);  // Crack length (120-220 pixels)
        
        float endX = cx + cos(angle) * length;
        float endY = cy + sin(angle) * length;
        allCracks.add(new GlassCrack(cx, cy, endX, endY, 0, true));  // Add main crack
        
        // Add branch cracks for each main crack
        int branches = (int) random(1, 3);  // Branch count (1-2)
        for (int b = 0; b < branches; b++) {
            float branchAngle = angle + random(-PI/3, PI/3);  // Branch angle offset
            float branchLen = length * random(0.4f, 0.7f);    // Branch length (40%-70% of main crack)
            float branchStartX = cx + cos(angle) * random(30, length * 0.6f);
            float branchStartY = cy + sin(angle) * random(30, length * 0.6f);
            float branchEndX = branchStartX + cos(branchAngle) * branchLen;
            float branchEndY = branchStartY + sin(branchAngle) * branchLen;
            allCracks.add(new GlassCrack(branchStartX, branchStartY, branchEndX, branchEndY, 1, false));
        }
    }
    
    //2. Connecting cracks (arcs connecting different main cracks)
    int connectorCount = (int) random(20, 35);
    for (int i = 0; i < connectorCount; i++) {
        float angle1 = random(TWO_PI);
        float angle2 = angle1 + random(PI/6, PI/3);
        float radius1 = random(40, 100);
        float radius2 = radius1 + random(-20, 30);
        
        float x1 = cx + cos(angle1) * radius1;
        float y1 = cy + sin(angle1) * radius1;
        float x2 = cx + cos(angle2) * radius2;
        float y2 = cy + sin(angle2) * radius2;
        
        allCracks.add(new GlassCrack(x1, y1, x2, y2, 2, false));
    }
    
    // 3. Fine debris cracks (small random cracks, simulating fragment details)
    int debrisCount = (int) random(50, 80);
    for (int i = 0; i < debrisCount; i++) {
        float angle = random(TWO_PI);
        float dist = random(20, 160);
        float x = cx + cos(angle) * dist;
        float y = cy + sin(angle) * dist;
        
        float smallAngle = angle + random(-PI/3, PI/3);
        float smallLen = random(15, 45);
        float x2 = x + cos(smallAngle) * smallLen;
        float y2 = y + sin(smallAngle) * smallLen;
        
        allCracks.add(new GlassCrack(x, y, x2, y2, 3, false));
    }
    
    //4. Spiderweb closed areas (concentric arc cracks, simulating spiderweb structure)
    int webCount = (int) random(20, 35);
    for (int i = 0; i < webCount; i++) {
        float angle1 = random(TWO_PI);
        float angle2 = angle1 + random(PI/8, PI/4);
        float rad = random(50, 130);
        
        float x1 = cx + cos(angle1) * rad;
        float y1 = cy + sin(angle1) * rad;
        float x2 = cx + cos(angle2) * rad;
        float y2 = cy + sin(angle2) * rad;
        
        allCracks.add(new GlassCrack(x1, y1, x2, y2, 2, false));
    }
}


// Glass Crack Class
// Represents a single glass crack segment with start point, end point, type, main attribute, color
// Different crack types have different line widths and transparency, simulating real glass shattering effect

class GlassCrack {
    float x1, y1, x2, y2; // Start and end coordinates of crack segment
    int type;// Crack type: 0=Main crack branch, 1=Normal branch, 2=Connecting crack, 3=Fine debris
    boolean isMain; // Whether it's a main crack (radial main crack)
    int crackColor;// Crack color
    
    // Constructor: Create new glass crack
    // x1, y1 Start coordinates of crack
    // x2, y2 End coordinates of crack
    // Crack type (0-3)
    // Whether it's a main crack
    GlassCrack(float x1, float y1, float x2, float y2, int type, boolean isMain) {
        this.x1 = x1;
        this.y1 = y1;
        this.x2 = x2;
        this.y2 = y2;
        this.type = type;
        this.isMain = isMain;
        
        // Set color and transparency based on crack type (main cracks brightest & whitest, fine debris darker & more transparent)
        if (isMain) {
            crackColor = color(255, 230);    
        } else if (type == 0) {
            crackColor = color(255, 210);   
        } else if (type == 1) {
            crackColor = color(255, 190);     
        } else if (type == 2) {
            crackColor = color(255, 165);      
        } else {
            crackColor = color(255, 135);     
        }
    }
    
    //Draw crack segment
    void display() {
        stroke(crackColor); // Set crack color
        
        // Set line width based on crack type
        float strokeW;
        if (isMain) {
            strokeW = 2.5;   // Main crack: thickest
        } else if (type == 0) {
            strokeW = 1.8; // Main crack branch: thicker
        } else if (type == 1) {
            strokeW = 1.5; // Normal branch: medium
        } else if (type == 2) {
            strokeW = 1.2; // Connecting crack: thinner
        } else {
            strokeW = 0.8; // Fine debris: thinnest
        }
        
        strokeWeight(strokeW);
        line(x1, y1, x2, y2);  //Draw crack segment
        
        // Add subtle highlight effect to main cracks
        if (isMain) {
            stroke(255, 255, 255, 60);
            strokeWeight(strokeW + 0.5);
            line(x1, y1, x2, y2);
        }
    }
}
