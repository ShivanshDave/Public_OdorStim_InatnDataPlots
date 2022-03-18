int airR = 12;
int airL = 11;
int sigR = 10;
int sigL = 9;
int sigE = 8;
int LED = 13;


void setup() {
  pinMode(airR, OUTPUT);
  pinMode(airL, OUTPUT);
  pinMode(sigR, OUTPUT);
  pinMode(sigL, OUTPUT);
  pinMode(sigE, OUTPUT);
  pinMode(LED, OUTPUT);

  digitalWrite(airR,  0);
  digitalWrite(airL,  0);
  digitalWrite(sigR,  0);
  digitalWrite(sigL,  0);
  digitalWrite(sigE, 0);
  digitalWrite(LED,  0);

  Serial.begin(9600);
}

void loop() {
  digitalWrite(airR, 0); // Turn off flow
  digitalWrite(airL, 0);
  digitalWrite(sigR, 0);
  digitalWrite(sigL, 0);
}

void serialEvent() {
  char cmd = Serial.read();

  if (cmd == 'E') {  // Enable
    flow_control(cmd, sigR, sigL);
    digitalWrite(sigE, 1);
    digitalWrite(LED, 1); // Show enable status
  }
  else if (cmd == 'X') {  // Disable
    digitalWrite(sigE, 0);
    flow_control(cmd, sigR, sigL);
    digitalWrite(LED, 0);
  }
  else if (cmd == 'L') {
    flow_control(cmd, airL, sigL);
  }
  else if (cmd == 'R') {
    flow_control(cmd, airR, sigR);
  }
}

void flow_control(char cmd, int sig, int air) {
  long val1 = Serial.parseInt();
  long val2 = Serial.parseInt();

  delay(val1);             // Signal
  digitalWrite(air, 1);
  digitalWrite(sig, 1);
  delay(val2);
  digitalWrite(air, 0);
  digitalWrite(sig, 0);

  Serial.print(cmd);      // Ack
  Serial.print(' ');
  Serial.print(val1);
  Serial.print(' ');
  Serial.println(val2);
}
