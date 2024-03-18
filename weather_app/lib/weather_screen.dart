import 'dart:convert';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:weather_app/additional_info_item.dart';
import 'package:weather_app/hourly_forecast_item.dart';
import 'package:http/http.dart' as http;
import 'package:weather_app/secrets.dart';


class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  //creating global var to store weather data
  late Future<Map<String, dynamic>> weather;
  Future<Map<String, dynamic>> getWeatherData() async {
    try {
      String cityName = "Saint Petersburg";
      final res = await http.get(
        Uri.parse(
          'http://api.openweathermap.org/data/2.5/forecast?q=$cityName,RU&APPID=$openWeatherAPIKey'
        ),
      );

      final data = jsonDecode(res.body);

      if (int.parse(data['cod']) !=200 ) {
        throw 'An unexpected error occurred';
      }

      return data;
      //data['list'][0]['main']['temp'];

    } catch (e) {
      throw e.toString();
    }
  }

  // function for normal temperature
  String toCelcius(temp) => (temp - 273.15).toStringAsFixed(2);


  @override
  void initState() {
    super.initState();
    weather = getWeatherData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Pogodka',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () {
              setState(() {
                weather = getWeatherData();
              });
            }, 
            icon: const Icon(Icons.refresh),
          )
        ],
      ),
      body: FutureBuilder(
        future: weather,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator.adaptive(),
            );
          }
          if (snapshot.hasError) {
            return Center(child: Text(snapshot.error.toString()));
          }

          // ! means that the data is not null NEVER EVER EVER EVER 
          final data = snapshot.data!;

          final currentWeatherData = data['list'][0];

          final currentTemp = currentWeatherData['main']['temp'];
          final currentSky = currentWeatherData['weather'][0]['main'];
          final currentPressure = currentWeatherData['main']['pressure'];
          final currentHumidity = currentWeatherData['main']['humidity'];
          final currentWindSpeed = currentWeatherData['wind']['speed'];

          return Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  //main card
                  SizedBox(
                    width: double.infinity,
                    child: Card(
                      elevation: 15,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: Column(
                              children: [
                                Text(
                                  '${toCelcius(currentTemp)} °C',
                                  style: const TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 1,),
                                Icon(
                                  currentSky == 'Clouds' || currentSky == 'Clear' ? Icons.cloud : Icons.sunny, 
                                  size: 64
                                  ),
                                Text(
                                  currentSky,
                                  style: const TextStyle(
                                    fontSize: 20,
                                  ),
                                )
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20,),
                  const Text(
                    'Weather forecast', 
                    style: TextStyle(
                      fontSize: 24, 
                      fontWeight: FontWeight.bold
                    ),
                  ),
                  const SizedBox(height: 8,),
                  //weather forecast cards
                  // SingleChildScrollView(
                  //   scrollDirection: Axis.horizontal,
                  //   child: Row(
                  //     children: [
                  //       for (int i = 0; i < 5; i++)
                  //       HourlyForecastItem(
                  //         icon: data['list'][i+1]['weather'][0]['main'] == 'Clouds' || data['list'][i+1]['weather'][0]['main'] == 'Sunny' ? Icons.cloud : Icons.sunny,
                  //         time: data['list'][i+1]['dt'].toString(),
                  //         temp: data['list'][i+1]['main']['temp'].toString(),
                  //       ),
                  //     ],
                  //   ),
                  // ),
                  SizedBox(
                    height: 120,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: 5,
                      itemBuilder: (context, index) {
                        final hourlyForecast = data['list'][index+1];
                        final hourlyIcon = hourlyForecast['weather'][0]['main'];
                        final hourlyTemp = toCelcius(hourlyForecast['main']['temp']);
                        final time = DateTime.parse(hourlyForecast['dt_txt']);
                        return HourlyForecastItem(
                          icon: hourlyIcon == 'Clouds' || hourlyIcon == 'Sunny' ? Icons.cloud : Icons.sunny,
                          time: DateFormat.Hm().format(time),
                          temp: hourlyTemp,
                        );
                      }
                    ),
                  ),
                  const SizedBox(height: 20,),
                  //additional info
                  const Text(
                    'Additional information', 
                    style: TextStyle(
                      fontSize: 24, 
                      fontWeight: FontWeight.bold
                    ),
                  ),
                  const SizedBox(height: 8,),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      AdditionalInfoItem(
                        icon: Icons.water_drop,
                        label: 'Humidity',
                        value: '$currentHumidity',
                      ),
                      AdditionalInfoItem(
                        icon: Icons.air,
                        label: 'Wind speed',
                        value: '$currentWindSpeed',
                      ),
                      AdditionalInfoItem(
                        icon: Icons.beach_access,
                        label: 'Pressure',
                        value: '$currentPressure',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}


