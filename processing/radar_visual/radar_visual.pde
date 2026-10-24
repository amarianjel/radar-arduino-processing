import processing.serial.*;

Serial puerto;

int angulo = 90;
int distancia = 0;
int[] lecturas = new int[181];

float cx, cy;
float radioMax = 380;

PFont fuenteTitulo;
PFont fuenteInfo;

void setup() {
  size(1200, 760);
  smooth(8);

  cx = width * 0.42;
  cy = height * 0.82;

  fuenteTitulo = createFont("Arial Bold", 28);
  fuenteInfo = createFont("Arial", 18);

  println("Puertos disponibles:");
  printArray(Serial.list());

  String[] puertos = Serial.list();
  String seleccionado = null;

  for (String p : puertos) {
    if (p.contains("usbserial") || p.contains("usbmodem") || p.contains("COM")) {
      seleccionado = p;
      break;
    }
  }

  if (seleccionado != null) {
    puerto = new Serial(this, seleccionado, 9600);
    puerto.bufferUntil('\n');
    println("Conectado a: " + seleccionado);
  } else {
    println("No se encontró el puerto del Arduino.");
  }
}

void draw() {
  dibujarFondo();
  dibujarRadar();
  dibujarLecturas();
  dibujarBarrido();
  dibujarPanelInfo();
}

void dibujarFondo() {
  background(5, 12, 18);

  // efecto sutil decorativo
  for (int i = 0; i < height; i += 4) {
    stroke(8, 18, 24, 35);
    line(0, i, width, i);
  }
}

void dibujarRadar() {
  pushMatrix();
  translate(cx, cy);

  noFill();

  // Arcos
  strokeWeight(2);
  for (int i = 1; i <= 5; i++) {
    float r = radioMax * i / 5.0;
    stroke(0, 180, 90, 90);
    arc(0, 0, r*2, r*2, PI, TWO_PI);
  }

  // Líneas radiales
  for (int a = 0; a <= 180; a += 30) {
    float x = cos(PI - radians(a)) * radioMax;
    float y = -sin(PI - radians(a)) * radioMax;
    stroke(0, 140, 70, 70);
    line(0, 0, x, y);
  }

  // Línea base
  stroke(0, 255, 120, 160);
  strokeWeight(2);
  line(-radioMax, 0, radioMax, 0);

  // Etiquetas de distancia
  fill(120, 255, 170);
  textAlign(CENTER);
  textFont(fuenteInfo);

  for (int d = 20; d <= 100; d += 20) {
    float r = map(d, 0, 100, 0, radioMax);
    text(d + " cm", r - 15, -10);
    text(d + " cm", -r + 15, -10);
  }

  // Etiquetas de ángulo
  for (int a = 0; a <= 180; a += 30) {
    float x = cos(PI - radians(a)) * (radioMax + 28);
    float y = -sin(PI - radians(a)) * (radioMax + 28);
    fill(90, 220, 130);
    text(a + "°", x, y);
  }

  popMatrix();
}

void dibujarLecturas() {
  pushMatrix();
  translate(cx, cy);

  for (int a = 0; a <= 180; a++) {
    int d = lecturas[a];

    if (d > 0 && d <= 100) {
      float r = map(d, 0, 100, 0, radioMax);
      float x = cos(PI - radians(a)) * r;
      float y = -sin(PI - radians(a)) * r;

      // brillo
      noStroke();
      fill(255, 40, 40, 60);
      ellipse(x, y, 18, 18);

      // punto central
      fill(255, 80, 80);
      ellipse(x, y, 8, 8);
    }
  }

  popMatrix();
}

void dibujarBarrido() {
  pushMatrix();
  translate(cx, cy);

  float x = cos(PI - radians(angulo)) * radioMax;
  float y = -sin(PI - radians(angulo)) * radioMax;

  // barrido principal
  stroke(0, 255, 140);
  strokeWeight(3);
  line(0, 0, x, y);

  // efecto de barrido anterior
  for (int i = 1; i <= 12; i++) {
    float a2 = angulo - i * 2;
    if (a2 >= 0) {
      float x2 = cos(PI - radians(a2)) * radioMax;
      float y2 = -sin(PI - radians(a2)) * radioMax;
      stroke(0, 255, 140, 120 - i * 8);
      strokeWeight(2);
      line(0, 0, x2, y2);
    }
  }

  // centro
  noStroke();
  fill(0, 255, 160);
  ellipse(0, 0, 12, 12);

  popMatrix();
}

void dibujarPanelInfo() {
  float panelX = width * 0.72;
  float panelY = 80;
  float panelW = 280;
  float panelH = 280;

  // panel
  noStroke();
  fill(10, 24, 30, 220);
  rect(panelX, panelY, panelW, panelH, 20);

  // borde
  noFill();
  stroke(0, 220, 120, 120);
  strokeWeight(2);
  rect(panelX, panelY, panelW, panelH, 20);

  fill(0, 255, 150);
  textFont(fuenteTitulo);
  textAlign(LEFT);
  text("RADAR HC-SR04", panelX + 20, panelY + 40);

  fill(180, 255, 210);
  textFont(fuenteInfo);
  text("Estado del sistema", panelX + 20, panelY + 80);

  fill(220);
  text("Ángulo actual: " + angulo + "°", panelX + 20, panelY + 125);

  if (distancia > 0) {
    text("Distancia: " + distancia + " cm", panelX + 20, panelY + 160);

    if (distancia < 20) {
      fill(255, 80, 80);
      text("Objeto muy cerca", panelX + 20, panelY + 200);
    } else if (distancia < 50) {
      fill(255, 200, 80);
      text("Objeto detectado", panelX + 20, panelY + 200);
    } else {
      fill(100, 255, 140);
      text("Objeto lejano", panelX + 20, panelY + 200);
    }
  } else {
    fill(140, 220, 255);
    text("Sin objeto en rango", panelX + 20, panelY + 160);
  }

  fill(160, 200, 190);
  text("Rango visible: 0 a 100 cm", panelX + 20, panelY + 245);

  // título superior general
  fill(0, 255, 160);
  textFont(fuenteTitulo);
  text("Visualización de radar en tiempo real", 40, 45);
}

void serialEvent(Serial p) {
  String dato = p.readStringUntil('\n');

  if (dato == null) return;

  dato = trim(dato);
  String[] valores = split(dato, ',');

  if (valores.length == 2) {
    try {
      int a = Integer.parseInt(valores[0]);
      int d = Integer.parseInt(valores[1]);

      if (a >= 0 && a <= 180) {
        angulo = a;
        distancia = d;
        lecturas[a] = d;
      }
    }
    catch(Exception e) {
      println("Dato inválido: " + dato);
    }
  }
}
