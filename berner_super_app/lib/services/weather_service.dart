import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';

class WeatherData {
  final String cityName;
  final String region;
  final String country;
  final double temperature;
  final double feelsLike;
  final int humidity;
  final int pressure;
  final double windSpeed;
  final int visibility;
  final String description;
  final String iconUrl;
  final int cloudCover;
  final double uvIndex;
  final DateTime timestamp;

  WeatherData({
    required this.cityName,
    required this.region,
    required this.country,
    required this.temperature,
    required this.feelsLike,
    required this.humidity,
    required this.pressure,
    required this.windSpeed,
    required this.visibility,
    required this.description,
    required this.iconUrl,
    required this.cloudCover,
    required this.uvIndex,
    required this.timestamp,
  });

  factory WeatherData.fromJson(Map<String, dynamic> json) {
    final location = json['location'];
    final current = json['current'];

    return WeatherData(
      cityName: location['name'] ?? 'Unknown Location',
      region: location['region'] ?? '',
      country: location['country'] ?? '',
      temperature: (current['temp_c'] as num).toDouble(),
      feelsLike: (current['feelslike_c'] as num).toDouble(),
      humidity: current['humidity'],
      pressure: (current['pressure_mb'] as num).toInt(),
      windSpeed: (current['wind_kph'] as num).toDouble() / 3.6, // Convert to m/s
      visibility: ((current['vis_km'] as num).toDouble() * 1000).toInt(),
      description: current['condition']['text'],
      iconUrl: 'https:${current['condition']['icon']}',
      cloudCover: current['cloud'],
      uvIndex: (current['uv'] as num).toDouble(),
      timestamp: DateTime.now(),
    );
  }
}

class ForecastData {
  final DateTime dateTime;
  final double temperature;
  final double minTemp;
  final double maxTemp;
  final int humidity;
  final String description;
  final String iconUrl;
  final double chanceOfRain;
  final double maxWindSpeed;

  ForecastData({
    required this.dateTime,
    required this.temperature,
    required this.minTemp,
    required this.maxTemp,
    required this.humidity,
    required this.description,
    required this.iconUrl,
    required this.chanceOfRain,
    required this.maxWindSpeed,
  });

  factory ForecastData.fromJson(Map<String, dynamic> json) {
    final day = json['day'];
    return ForecastData(
      dateTime: DateTime.parse(json['date']),
      temperature: (day['avgtemp_c'] as num).toDouble(),
      minTemp: (day['mintemp_c'] as num).toDouble(),
      maxTemp: (day['maxtemp_c'] as num).toDouble(),
      humidity: (day['avghumidity'] as num).toInt(),
      description: day['condition']['text'],
      iconUrl: 'https:${day['condition']['icon']}',
      chanceOfRain: (day['daily_chance_of_rain'] as num).toDouble(),
      maxWindSpeed: (day['maxwind_kph'] as num).toDouble() / 3.6,
    );
  }
}

class HourlyWeatherData {
  final DateTime dateTime;
  final double temperature;
  final int humidity;
  final double windSpeed;
  final String description;
  final String iconUrl;
  final double precipitationProbability;
  final double precipitationMM;

  HourlyWeatherData({
    required this.dateTime,
    required this.temperature,
    required this.humidity,
    required this.windSpeed,
    required this.description,
    required this.iconUrl,
    required this.precipitationProbability,
    required this.precipitationMM,
  });

  factory HourlyWeatherData.fromJson(Map<String, dynamic> json) {
    return HourlyWeatherData(
      dateTime: DateTime.parse(json['time']),
      temperature: (json['temp_c'] as num).toDouble(),
      humidity: json['humidity'],
      windSpeed: (json['wind_kph'] as num).toDouble() / 3.6,
      description: json['condition']['text'],
      iconUrl: 'https:${json['condition']['icon']}',
      precipitationProbability: (json['chance_of_rain'] as num).toDouble(),
      precipitationMM: (json['precip_mm'] as num).toDouble(),
    );
  }
}

class WeatherService {
  // WeatherAPI.com API Key
  static const String _apiKey = '1dc7e18384754237bbd151618250210';
  static const String _baseUrl = 'https://api.weatherapi.com/v1';

  Future<Position> _getCurrentPosition() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions are permanently denied');
    }

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.medium,
    );
  }

  Future<WeatherData> getCurrentWeather() async {
    try {
      final position = await _getCurrentPosition();

      final url = '$_baseUrl/current.json?key=$_apiKey&q=${position.latitude},${position.longitude}&aqi=no';

      print('🌤️ Fetching weather from: $url');

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('🟢 Weather data fetched successfully');
        return WeatherData.fromJson(data);
      } else {
        print('❌ Failed to load weather data: ${response.statusCode}');
        print('Response: ${response.body}');
        throw Exception('Failed to load weather data: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error fetching weather: $e');
      // Fallback to mock data
      return _getMockCurrentWeather();
    }
  }

  Future<List<ForecastData>> getForecast() async {
    try {
      final position = await _getCurrentPosition();

      // Get 7-day forecast
      final url = '$_baseUrl/forecast.json?key=$_apiKey&q=${position.latitude},${position.longitude}&days=7&aqi=no&alerts=no';

      print('🌤️ Fetching forecast from: $url');

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> forecastDays = data['forecast']['forecastday'];

        print('🟢 Forecast data fetched: ${forecastDays.length} days');

        return forecastDays
            .map((item) => ForecastData.fromJson(item))
            .toList();
      } else {
        print('❌ Failed to load forecast data: ${response.statusCode}');
        throw Exception('Failed to load forecast data: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error fetching forecast: $e');
      // Fallback to mock data
      return _getMockForecast();
    }
  }

  Future<List<HourlyWeatherData>> getHourlyForecast() async {
    try {
      final position = await _getCurrentPosition();

      // Get today's hourly forecast
      final url = '$_baseUrl/forecast.json?key=$_apiKey&q=${position.latitude},${position.longitude}&days=1&aqi=no&alerts=no';

      print('🌤️ Fetching hourly forecast from: $url');

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> hourlyData = data['forecast']['forecastday'][0]['hour'];

        final now = DateTime.now();
        final List<HourlyWeatherData> hourlyForecast = [];

        // Get next 24 hours
        for (var item in hourlyData) {
          final hourlyWeather = HourlyWeatherData.fromJson(item);

          if (hourlyWeather.dateTime.isAfter(now) && hourlyForecast.length < 8) {
            hourlyForecast.add(hourlyWeather);
          }
        }

        print('🟢 Hourly forecast fetched: ${hourlyForecast.length} hours');

        return hourlyForecast;
      } else {
        print('❌ Failed to load hourly forecast data: ${response.statusCode}');
        throw Exception('Failed to load hourly forecast data: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error fetching hourly forecast: $e');
      // Fallback to mock data
      return _getMockHourlyForecast();
    }
  }

  WeatherData _getMockCurrentWeather() {
    return WeatherData(
      cityName: 'Demo City',
      region: 'Demo Region',
      country: 'Sri Lanka',
      temperature: 28.5,
      feelsLike: 31.2,
      humidity: 75,
      pressure: 1011,
      windSpeed: 4.2,
      visibility: 10000,
      description: 'Partly cloudy',
      iconUrl: 'https://cdn.weatherapi.com/weather/64x64/day/116.png',
      cloudCover: 25,
      uvIndex: 7.0,
      timestamp: DateTime.now(),
    );
  }

  List<ForecastData> _getMockForecast() {
    final List<ForecastData> mockForecast = [];
    final now = DateTime.now();

    for (int i = 0; i < 7; i++) {
      final date = now.add(Duration(days: i));
      final baseTemp = 26.0 + (i * 1.5);

      mockForecast.add(ForecastData(
        dateTime: date,
        temperature: baseTemp,
        minTemp: baseTemp - 3,
        maxTemp: baseTemp + 5,
        humidity: 70 + (i * 2),
        description: i % 3 == 0 ? 'Sunny' : i % 3 == 1 ? 'Partly cloudy' : 'Cloudy',
        iconUrl: 'https://cdn.weatherapi.com/weather/64x64/day/${i % 3 == 0 ? '113' : i % 3 == 1 ? '116' : '119'}.png',
        chanceOfRain: i % 3 == 2 ? 40.0 : 10.0,
        maxWindSpeed: 3.5 + (i * 0.5),
      ));
    }

    return mockForecast;
  }

  List<HourlyWeatherData> _getMockHourlyForecast() {
    final List<HourlyWeatherData> mockHourlyForecast = [];
    final now = DateTime.now();

    for (int i = 1; i <= 8; i++) {
      final time = now.add(Duration(hours: i * 3));
      final baseTemp = 25.0 + (i * 1.5);

      mockHourlyForecast.add(HourlyWeatherData(
        dateTime: time,
        temperature: baseTemp,
        humidity: 65 + (i * 2),
        windSpeed: 3.0 + (i * 0.4),
        description: i % 4 == 0 ? 'Clear' : i % 4 == 1 ? 'Partly cloudy' : i % 4 == 2 ? 'Cloudy' : 'Light rain',
        iconUrl: 'https://cdn.weatherapi.com/weather/64x64/day/${i % 4 == 0 ? '113' : i % 4 == 1 ? '116' : i % 4 == 2 ? '119' : '176'}.png',
        precipitationProbability: i % 4 == 3 ? 60.0 : i % 4 == 2 ? 20.0 : 5.0,
        precipitationMM: i % 4 == 3 ? 2.5 : 0.0,
      ));
    }

    return mockHourlyForecast;
  }
}
