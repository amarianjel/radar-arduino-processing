# 📡 Radar ultrasónico con Arduino Uno y Processing

Proyecto de radar de **180°** que combina un **Arduino Uno**, un sensor ultrasónico **HC-SR04** y un servomotor para detectar obstáculos y representarlos en tiempo real en la computadora mediante una interfaz visual creada con **Processing**.

> **Versión oficial de visualización:** segundo código de Processing (interfaz oscura con radar verde, puntos rojos y panel lateral de información). Se reproduce aquí sin reemplazarlo por la primera interfaz.

## ✨ Funcionalidades

- Barrido del servo de **0° a 180°** y regreso continuo (solo si el servo admite físicamente ese recorrido).
- Medición de distancia por ultrasonido, hasta **100 cm en la visualización**.
- Comunicación serie Arduino → computadora a **9600 baudios**.
- Visualización semicircular con arcos, divisiones angulares, barrido verde y puntos rojos.
- Panel de estado con ángulo, distancia y alertas según cercanía.

## 🧰 Componentes

| Cantidad | Componente |
|---|---|
| 1 | Arduino Uno y cable USB de datos |
| 1 | Sensor HC-SR04 |
| 1 | Servomotor de posición, presumiblemente de 180° (revisar modelo exacto: etiqueta indicada como «AOO90») |
| 1 | Protoboard y cables jumper |
| 1 | Soporte liviano para fijar el HC-SR04 sobre el brazo del servo |
| 1 | Computadora con Arduino IDE y Processing instalados |

## 🔌 Conexiones

### Servomotor

| Cable del servo | Arduino Uno |
|---|---|
| Blanco (señal, **confirmar en el modelo**) | D9 |
| Rojo (V+) | 5V regulados* |
| Negro (GND) | GND |

### Sensor HC-SR04

| HC-SR04 | Arduino Uno |
|---|---|
| VCC | 5V |
| TRIG | D6 |
| ECHO | D7 |
| GND | GND |

\* **Alimentación:** para una prueba breve con un microservo pequeño y sin carga, la salida de 5 V puede resultar suficiente; si el motor vibra, causa reinicios o lleva una carga apreciable, utiliza una **fuente externa regulada de 5 V adecuada al servo** y conecta el GND de esa fuente al GND del Arduino. **No apliques 6 V al pin 5V del Arduino.** No cambies el cableado basándote solo en los colores sin comprobar la etiqueta/ficha del servo.

## 📁 Estructura sugerida para GitHub

```text
radar-arduino-processing/
├── README.md
├── arduino/
│   └── radar_arduino/
│       └── radar_arduino.ino
└── processing/
    └── radar_visual/
        └── radar_visual.pde
```

Los bloques siguientes son el contenido de los archivos `.ino` y `.pde`.

## 1. Programa de Arduino (`arduino/radar_arduino/radar_arduino.ino`)

Este sketch mueve el servo y envía líneas con el formato `angulo,distancia` mediante USB. El valor `0` indica que no se detectó un eco válido dentro del límite configurado.

```cpp
#include <Servo.h>

Servo radarServo;

const int PIN_SERVO = 9;
const int PIN_TRIG = 6;
const int PIN_ECHO = 7;
const int DISTANCIA_MAX = 100;

int medirDistancia() {
  digitalWrite(PIN_TRIG, LOW);
  delayMicroseconds(2);
  digitalWrite(PIN_TRIG, HIGH);
  delayMicroseconds(10);
  digitalWrite(PIN_TRIG, LOW);

  unsigned long duracion = pulseIn(PIN_ECHO, HIGH, 25000UL);
  if (duracion == 0) return 0;

  int distancia = duracion / 58;
  if (distancia > DISTANCIA_MAX) return 0;
  return distancia;
}

void explorar(int inicio, int fin, int paso) {
  if (paso == 0) return;

  for (int angulo = inicio;
       (paso > 0) ? angulo <= fin : angulo >= fin;
       angulo += paso) {
    radarServo.write(angulo);
    delay(45);

    int distancia = medirDistancia();
    Serial.print(angulo);
    Serial.print(",");
    Serial.println(distancia);
  }
}

void setup() {
  Serial.begin(9600);
  pinMode(PIN_TRIG, OUTPUT);
  pinMode(PIN_ECHO, INPUT);
  radarServo.attach(PIN_SERVO);
  radarServo.write(90);
  delay(1000);
}

void loop() {
  explorar(0, 180, 2);
  explorar(180, 0, -2);
}
```

> **Advertencia mecánica:** si el servo fuerza los topes o hace ruido en 0°/180°, cambia las dos llamadas a `explorar(10, 170, 2);` y `explorar(170, 10, -2);` hasta confirmar su rango real. El servo debe mover el sensor sin forzar cables ni articulaciones.

## 2. Visualización oficial: código 2 de Processing (`processing/radar_visual/radar_visual.pde`)

Esta es la **segunda interfaz elegida**: fondo oscuro, radar semicircular con líneas y arcos verdes, barrido luminoso, detecciones rojas y panel lateral.

```java
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
```

## ▶️ Cómo replicar el proyecto

1. Instala el [Arduino IDE](https://www.arduino.cc/en/software) y [Processing](https://processing.org/download/).
2. Monta el HC-SR04 sobre el brazo del servo, con los transductores apuntando hacia afuera, y realiza las conexiones de la tabla anterior.
3. Crea la carpeta `radar_arduino`, guarda el sketch con el nombre `radar_arduino.ino` y ábrelo en Arduino IDE.
4. Selecciona **Arduino Uno** y el puerto USB correcto; carga el sketch.
5. Para verificar los datos, abre temporalmente el **Monitor Serie a 9600 baudios**. Debes ver líneas como `90,25` o `92,0`. Luego **cierra el Monitor Serie**.
6. Crea en Processing un sketch llamado `radar_visual` y guarda el segundo código como `radar_visual.pde`.
7. Ejecuta el sketch en Processing (botón ▶). La consola indicará qué puerto se utilizó y se abrirá la interfaz gráfica.
8. Coloca objetos frente al sensor y observa las marcas rojas, la línea de barrido y el panel de lectura.

## 📨 Formato de los datos

Arduino transmite una línea por medición:

```text
angulo,distancia
```

Ejemplo:

```text
88,45
90,25
92,0
```

- **Ángulo:** posición enviada al servo, en grados.
- **Distancia:** medida calculada en centímetros; **0** significa que no hubo detección válida dentro de 100 cm.
- **Velocidad de comunicación:** 9600 baudios.

## 🛠️ Problemas frecuentes

| Problema | Qué revisar |
|---|---|
| El servo no se mueve | Pin D9, alimentación, GND común, conexión correcta del cable de señal y modelo de servo. |
| El servo se traba en los extremos | Reduce el barrido a 10°–170° y evita forzarlo. |
| Processing no encuentra el puerto | Consulta `Serial.list()` en la consola; en Mac suele tener nombre `usbserial`, `usbmodem` o similar. En placas con otros conversores puede requerirse seleccionar manualmente. |
| Processing dice que el puerto está ocupado | Cierra el Monitor Serie, Plotter Serie y cualquier aplicación que tenga abierto el mismo puerto. |
| La pantalla abre, pero no aparecen datos | Comprueba el puerto correcto, 9600 baudios y que Arduino envía `angulo,distancia` terminado en salto de línea. |
| Aparecen valores 0 | Puede no haber eco o el objeto estar fuera del máximo configurado de 100 cm. |
| Los puntos permanecen después de mover un objeto | El código 2 guarda la **última lectura de cada ángulo** hasta el siguiente barrido de ese sector. |
| Processing selecciona otro dispositivo | Sustituye la selección automática por `puerto = new Serial(this, "/dev/cu.usbserial-XXXX", 9600);` usando el nombre **real** mostrado por `Serial.list()`. |

## 📌 Notas sobre la versión 2

- La pantalla se configura a **1200 × 760 píxeles**.
- La distancia representada en el radar es **0–100 cm**, aunque el HC-SR04 puede tener otras especificaciones de alcance según condiciones.
- **Todos los puntos detectados son rojos**. Los colores de las alertas del panel dependen de la distancia: roja (`<20 cm`), amarilla (`20–49 cm`) y verde (`50–100 cm`).
- La estela verde del barrido se calcula hacia ángulos menores; es un efecto visual y no representa necesariamente la dirección previa al regresar el servo.
- El proyecto muestra un radar de proximidad: **no es un radar de radiofrecuencia**; mide ecos ultrasónicos.

## 🔗 Referencias

- [Arduino IDE](https://www.arduino.cc/en/software)
- [Biblioteca Servo de Arduino](https://docs.arduino.cc/libraries/servo/)
- [Processing](https://processing.org/download/)
- [Biblioteca Serial de Processing](https://processing.org/reference/libraries/serial/)

---

**Estado del proyecto:** documentación de la implementación propuesta; el funcionamiento final debe validarse en el montaje físico, especialmente el modelo/rango real del servomotor y la selección del puerto USB.
