#include "bme280.h"
// #pragma once

#include "Arduino.h"
#include <Adafruit_Sensor.h>
#include <Adafruit_BME280.h>
#include <SPI.h>

#define BME_SCK 18   // SCK(spi clock to GPIO 18  wellow wire
#define BME_MISO 19  // SDO  to GPIO19  ornge wire
#define BME_MOSI 23  //SDI (MOSI) to GPIO23 to blue wire
#define BME_CS 5   //CS (chip select to GPOI 5 green wire


/////////////////////// elements to send server ////
 struct WEATHER{
    float Fahrenheit ;
    float dewpoint ;
    float temperature; 
    float humidity;
    float pressure;
    float altitude;
    float wind_speed;
};

extern struct WEATHER weather;
//////////////////////////////////////////////////
void bme_setup() ;
 #define SEALEVELPRESSURE_HPA (1013.25)
 float Fahrenheit = 0;
 float dewpoint = 0;
 int logof = 0;
 float temp;
 float temperature= 0;

//////////////////////////////////////////////////////////
Adafruit_BME280 bme(BME_CS, BME_MOSI, BME_MISO, BME_SCK);

///////////////////////////////////////
 void bme_setup() 
  {
    bme.begin();
  }

void webPagebme()  // 
{
  weather.temperature = bme.readTemperature();
  temp = bme.readTemperature();
  weather.Fahrenheit = 9.0 / 5.0 * temperature + 32;
  weather.humidity = bme.readHumidity();
  weather.pressure = bme.readPressure() / 100.0F;
  weather.altitude = bme.readAltitude(SEALEVELPRESSURE_HPA);
  logof = log(weather.humidity / 100);
  dewpoint = (temp - (14.55 + 0.114 * temp) * (1 - (0.01 * weather.humidity)) - pow(((2.5 + 0.007 * temp) * (1 - (0.01 * weather.humidity))),3) - (15.9 + 0.117 * temp) * pow((1 - (0.01 * weather.humidity)), 14));
  }


