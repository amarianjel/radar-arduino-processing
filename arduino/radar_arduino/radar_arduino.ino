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
