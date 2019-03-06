#include <Wire.h>
#include <Adafruit_AMG88xx.h>

Adafruit_AMG88xx amg;

int pin_led = 13;

float temps[AMG88xx_PIXEL_ARRAY_SIZE];

float mean(float values[], int len){
  float sum = 0;
  for(int i=0; i<len; i++){
    sum += values[i];
  }
  return sum / len;
}

float variance(float values[], int len, float mean = 0){

  float actual_mean = 0;
  if(mean == 0){
    for(int i=0; i<len; i++){
      actual_mean += values[i];
    }
    actual_mean /= len;
  }
  else{
    actual_mean = mean;
  }
  
  float ret = 0;
  for(int i=0; i<len; i++){
    float diff = values[i] - actual_mean;
    ret += diff*diff;
  }
  return ret;
}


void setup() {
    Serial.begin(9600);
    //Serial.println(F("AMG88xx pixels"));

    bool status;
    
    // default settings
    status = amg.begin();
    if (!status) {
        //Serial.println("Could not find a valid AMG88xx sensor, check wiring!");
        while (1);
    }
    
    //Serial.println("-- Pixels Test --");

    //Serial.println();

    pinMode(pin_led, OUTPUT);
    delay(100); // let sensor boot up
}

float room_temp;
float heat[AMG88xx_PIXEL_ARRAY_SIZE];

void loop() { 
    amg.readPixels(heat);
 
    float sums[8];

    // select the min reading as room temp, as approximation
    // also compute the avg
    float avg = 0;
    for(int i=0; i<AMG88xx_PIXEL_ARRAY_SIZE; i++){
        if(heat[i] < room_temp){
            room_temp = heat[i];
        }
        avg += heat[i];
    }
    avg /= AMG88xx_PIXEL_ARRAY_SIZE;

    //Serial.print("ambient: ");
    //Serial.print(room_temp);
    //Serial.println();
    //Serial.print("avg: ");
    //Serial.print(avg);
    //Serial.println();
    

    for(int i=0; i<AMG88xx_PIXEL_ARRAY_SIZE; i++){
        heat[i] = heat[i] - room_temp;
    }

    // sum up along an axis
    // also check if target criterion is met
    //  defined as: count of pixels y
    
    memset(sums,0,sizeof(sums)); // clear the array
    int count = 0;
    int count_thresh = 4; // 10% heat above delta
    int heat_delta = 3;

    for (int i = 0; i<8; i++){
      int offst = i * 8;
      for (int j = 0; j<8; j++){
        sums[i] += heat[j + offst];  
      }
    }
    boolean detected_target = false;
    for(int i=0; i<AMG88xx_PIXEL_ARRAY_SIZE; i++){
        
        float heat_thresh = avg + heat_delta;
        if(heat[i]> heat_thresh){
          count += 1;
        }
        if(count > count_thresh){
          detected_target = true;
          break;
        }
    }
//    Serial.print("variance: ");
//    Serial.print(variance(heat, AMG88xx_PIXEL_ARRAY_SIZE, avg));
//    Serial.println();


    float target_index = 0;
    float total_sum = 0;
    float sums_mean = mean(sums, 8);
    for(int i=0; i<8; i++){
      sums[i] -= sums_mean;
      sums[i] = abs(sums[i]);
//      Serial.print(sums[i]);
//      Serial.print(", ");
      target_index += sums[i] * (i+1);
      total_sum += sums[i];
    }
//    Serial.println();

    target_index /= total_sum;
    float target_angle = ((target_index - 3.2)/(5.8 - 3.2))*60-30;
    
//    int highest_sum = 0;
//    for(int i=0; i<8; i++){
//      if(sums[i] > highest_sum){
//        highest_sum = sums[i];
//        target_index = i;
//      }
//    }
    
    
    if(detected_target){
        digitalWrite(pin_led, HIGH);
        Serial.print("Detected Target at angle: ");
        Serial.print(target_angle);
        Serial.println();
        
    }
    else{
        digitalWrite(pin_led, LOW);
        Serial.print("No Target detected");
        Serial.println();
    }


    
    
    // for(int i=0; i<8; i++){
    //   Serial.print(sums[i]);
    //   Serial.print(", ");
    // }
    // Serial.println();


    //Serial.print("[");
    // for(int i=0; i<AMG88xx_PIXEL_ARRAY_SIZE; i++){
        //Serial.print(heat[i]);
        //Serial.print(", ");
    //     if( (i+1)%8 == 0 ) //Serial.println();
    // }
    //Serial.println("]");
    //Serial.println();

    //delay a second
//    delay(1000);
}


