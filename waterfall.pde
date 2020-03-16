// based on sketch from Etienne JACOB
// motion blur template by beesandbombs
// opensimplexnoise code in another tab might be necessary
// --> code here : https://gist.github.com/Bleuje/fce86ef35b66c4a2b6a469b27163591e
//ffmpeg settings  -> 
//ffmpeg -r 25 -f image2 -i %05d.jpeg -vcodec libx264  test1.mp4

int[][] result;
int numFrames = 7500;  
float t;
float sassoX = 600, 
  sassoY = 3200, 
  raggio = 250, 
  distanzaX, 
  distanza;
float posX, posY;
int n = 120;  //numero di linee verticali
int bounceCount=0,
    bounceStop=10;


float ease(float p) {
  return 3*p*p - 2*p*p*p;
}

float ease(float p, float g) {

    return 0.5 * pow(2*p, g);

}

// push() per traslazioni di sistemi di coordinate (pushMatrix)
// e applicazioni di stile (pushStyle)
//  per poi tornare alle impostazioni precedenti con pop()

void push() {
  pushMatrix();
  pushStyle();
}

void pop() {
  popStyle();
  popMatrix();
}

void draw() {

  posX = mouseX*1.0/width;
  posY = mouseY*1.0/height;

  if (!recording) {
    if (mousePressed)
      println(posX);
    draw_();
  } else {
    for (int i=0; i<width*height; i++)
      for (int a=0; a<3; a++)
        result[i][a] = 0;


    for (int sa=0; sa<samplesPerFrame; sa++) {
      t = map(frameCount-1 + sa*shutterAngle/samplesPerFrame, 0, numFrames, 0, numFrames/125);
      //lo spazio di destinazione della mappatura era (0,1)
      //ho cambiato in (0,numFrames/100) per avere una animazione più lunga
      // a seconda dei numeri di frames

      draw_();
      loadPixels();
      for (int i=0; i<pixels.length; i++) {
        result[i][0] += pixels[i] >> 16 & 0xff;
        result[i][1] += pixels[i] >> 8 & 0xff;
        result[i][2] += pixels[i] & 0xff;
      }
    }

    loadPixels();
    for (int i=0; i<pixels.length; i++)
      pixels[i] = 0xff << 24 | 
        int(result[i][0]*1.0/samplesPerFrame) << 16 | 
        int(result[i][1]*1.0/samplesPerFrame) << 8 | 
        int(result[i][2]*1.0/samplesPerFrame);
    updatePixels();

    saveFrame("#####.jpeg");  //cambiato da .gif a .jpg
    //per importare sequenza in after effects rimuovere gli zeri davanti all'indice


    println(frameCount, "/", numFrames);
    if (frameCount==numFrames)
      exit();
  }
}

//////////////////////////////////////////////////////////////////////////////

//ORIGINAL
//int samplesPerFrame = 5;
//int numFrames = 80;        
//float shutterAngle = .6;

int samplesPerFrame = 5;      
float shutterAngle = .6;
boolean recording = true;

OpenSimplexNoise noise; 

class Thing {

  float x0;

  Thing(int i) {
    x0 = map(i, 0, n-1, width/2-500, width/2+500);   // mappa la quantità di linee vert dentro uno spazio di 300px
  }

  // pos costruttore di punti chiamato sia per i singoli punti che linee allungate
 
  PVector pos(float p, float tt) {  
    float y = map(p, 0, 1, 0, height);

    // VARIABILI NOISE
    float rad = 0.035;  // ampiezza laterale delle oscillazioni di  ogni singola particella
    float change = 18.5;  // se si ingrandisce il canvas bisogna aumentare change e freq
    float freq = 5.5;
    float variation = 0.003; // se uguale a 0 le linee sono tutte parallele

    distanza = sqrt(pow((x0-sassoX), 2)+pow((y-sassoY), 2));
    distanzaX = abs((x0-sassoX));
    float widthRadio = 1.2;  // fattore larghezza sasso
    float heightRadio = 0.9;  // fattore altezza sasso


    float cosAlfa = (sqrt(pow((x0-sassoX), 2)))/distanza;
    float sinAlfa = (sqrt(pow((sassoY-y), 2)))/distanza;
    //println(distanza);

    //GIRA INTORNO AL SASSO
    float xs = sassoX+(((x0-sassoX)/abs(x0-sassoX))*cosAlfa*raggio*widthRadio);
    float ys = sassoY+(((y-sassoY)/abs(y-sassoY))*sinAlfa*raggio*heightRadio);



    // il penultimo valore crea dei bordi tranquilli in alto e in basso
    // perchè fa un easing del valore alla seconda pow(...,2)
    float intensity = ease(pow(sin(PI*constrain(p, 0, 1)), 2.0), 0.01)+0;
    
    // noise distortion of the lines
    // per cambio dei parametri in base alla risoluzione 
    //  cambiare i fattori che moltiplicano intensity
    // 220 or 20
    float dx = 0.7*intensity*100*(float)noise.eval(100*SEED + rad*cos(TWO_PI*(freq*p - tt)), rad*sin(TWO_PI*(freq*p - tt)), change*p, variation*x0);
    float dy = 0.7*intensity*120*(float)noise.eval(2*SEED + rad*cos(TWO_PI*(freq*p - tt)), rad*sin(TWO_PI*(freq*p - tt)), change*p, variation*x0);

    //TODO: NOISE CHANGE WITH TIME
    //float dx =1;
    //float dy =1;
    


    if (y> sassoY+raggio-40 && distanzaX<0.8*raggio) {
      //nascondi questi punti
      return new PVector(-1, -1);
    }  
    
      // disegna gli sprizzi d'acqua
      if ((distanza < raggio) && (bounceCount < bounceStop)) {
         bounceCount =bounceCount+ 1;
         float xl = lerp(x0+dx,xs+dx,(distanzaX/70)*(bounceStop/3)*(distanza/raggio)*pow(sin(PI*constrain(p,0,1)),3.0)); 
         float yl = lerp(y+dy,ys+dy,3*(bounceStop/3)*(distanza/raggio)*pow(sin(PI*constrain(p,0,1)),3.0)); 
      return new PVector(xl, yl);       
     } else  if ((distanza < raggio) && (bounceCount >= bounceStop)){return new PVector(-1, -1);}  //nascondi questi punti

    float xl = lerp(x0+dx, xs+dx, pow(raggio/distanza, 4)); 
    float yl = lerp(y+dy, ys+dy, pow(raggio/distanza, 3)); 

    return new PVector(xl, yl);
  }
  
  


  int N = 200;                //lunghezza delle linee  
  int K = 5+floor(3*pow(random(1), 2.0));  // numero di volte in cui è suddivisa la linea di punti
  // ritorna valori tra primo valore davanti all'equazione(5)
  // e valore 3*pow(..
  float[] inizioP = new float[n];
  float[] fineP = new float[n];


  void show_dots(float tt, int linea) {
 
    // TODO: BRILLARE
    bounceCount = 0;
    if (linea % 2 == 0) bounceStop = 11;
    else bounceStop = 5;
    
    for (int i=0; i<K; i++) {
      for (int q=0; q<N; q++) {

        float p = map(-2+i+tt+0.01*q, -1, K, -0.7, 1.5);  // p compreso tra 0 e 1.1
        // cambiato da -1 a -0.6 per
        // correggere l'ingresso delle linee

        
        // BEGIN SEQUENCE
        if (frameCount < 500) {
          float rrr = map (frameCount, 0, 500, 0.0, 1.5);
          if (inizioP[linea] == 0 && i==0 && q == (N-1)) inizioP[linea] = rrr-p;      
          if ( rrr-p<inizioP[linea])
         {
            break;
           }
        }

        // END SEQUENCE
        if (frameCount >  numFrames-600) {
          float rrr = map (frameCount, 0, 500, 0.0, 1.3);
          if (fineP[linea] == 0 && i==0 && q == 0) fineP[linea] = rrr-p;
          if ( rrr-p>fineP[linea])
          {
            break;
          }
        }

        //COLORE LINEE
        //float hhh = map(q,0,N-20,250, 190); 
        float hhh =0;
        //float sss =  map(q,0.9*N,N,100, 0);
        float sss =0;
        //float bbb =  map(q,0,N,0, 100);
        //float bbb =80;
        float bbb =  map(q, 0+30, N, 0, 95);
        //float alpha = 100;
        float alpha =  map(q, 0+30, N, 0, 100);
        float e = map(q, 0, N, 5, 6);                    //spessore della linea


        PVector dot = pos(p, tt);  //non cambia molto se si passa t o tt

        //DISEGNO LINEA
        strokeWeight(e);
        stroke(hhh, sss, bbb, alpha);
        //DEBUG LINEA
        //if (linea == 20 && p<0.5) stroke(8, 100, 100, alpha);
        point(dot.x, dot.y);


        //DISEGNO TESTA DELLA LINEA
        if ( N - q < 5) {
          for (int radius = 1; radius > 0; --radius) {
            if ( q == N-1) ellipse(dot.x, dot.y+2, 0.1, 0.1);
            strokeWeight(e+4-(N-q));
            stroke(0, 0, 100, 50);
            point(dot.x, dot.y+2);
          }
        }
      }
    }
  }

  float offset = random(1);

  void show(int linea) {
    float tt = (t+offset)%1; // tt  = numeri random tra 0 e 1
    show_dots(tt, linea);  // particelle allungate
  }
}


Thing[] array = new Thing[n];

float SEED;

void setup() {
  // DIMENSIONI FINALI
  // 1200px x 3840px
  size(1200, 3840, P3D);
  colorMode(HSB, 360, 100, 100, 100);
  hint(ENABLE_DEPTH_SORT);
  //hint(DISABLE_DEPTH_TEST);
  result = new int[width*height][3];
  noise = new OpenSimplexNoise();
  SEED = random(10, 1000);

  for (int i=0; i<n; i++) {
    array[i] = new Thing(i);
  }
}

void draw_() {
  background(0);
  push();
  for (int i=0; i<n; i++) {
    array[i].show(i);
  }
  pop();
}
