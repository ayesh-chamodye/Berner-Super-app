import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';

class WeatherData {
  final String cityName;
  final double temperature;
  final double feelsLike;
  final int humidity;
  final int pressure;
  final double windSpeed;
  final int visibility;
  final String description;
  final String iconCode;
  final DateTime timestamp;

  WeatherData({
    required this.cityName,
    required this.temperature,
    required this.feelsLike,
    required this.humidity,
    required this.pressure,
    required this.windSpeed,
    required this.visibility,
    required this.description,
    required this.iconCode,
    required this.timestamp,
  });

  factory WeatherData.fromJson(Map<String, dynamic> json) {
    return WeatherData(
      cityName: json['name'] ?? 'Unknown Location',
      temperature: (json['main']['temp'] as num).toDouble(),
      feelsLike: (json['main']['feels_like'] as num).toDouble(),
      humidity: json['main']['humidity'],
      pressure: json['main']['pressure'],
      windSpeed: (json['wind']['speed'] as num).toDouble(),
      visibility: json['visibility'] ?? 10000,
      description: json['weather'][0]['description'],
      iconCode: json['weather'][0]['icon'],
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
  final String iconCode;

  ForecastData({
    required this.dateTime,
    required this.temperature,
    required this.minTemp,
    required this.maxTemp,
    required this.humidity,
    required this.description,
    required this.iconCode,
  });

  factory ForecastData.fromJson(Map<String, dynamic> json) {
    return ForecastData(
      dateTime: DateTime.fromMillisecondsSinceEpoch(json['dt'] * 1000),
      temperature: (json['main']['temp'] as num).toDouble(),
      minTemp: (json['main']['temp_min'] as num).toDouble(),
      maxTemp: (json['main']['temp_max'] as num).toDouble(),
      humidity: json['main']['humidity'],
      description: json['weather'][0]['description'],
      iconCode: json['weather'][0]['icon'],
    );
  }
}

class HourlyWeatherData {
  final DateTime dateTime;
  final double temperature;
  final int humidity;
  final double windSpeed;
  final String description;
  final String iconCode;
  final double precipitationProbability;

  HourlyWeatherData({
    required this.dateTime,
    required this.temperature,
    required this.humidity,
    required this.windSpeed,
    required this.description,
    required this.iconCode,
    required this.precipitationProbability,
  });

  factory HourlyWeatherData.fromJson(Map<String, dynamic> json) {
    return HourlyWeatherData(
      dateTime: DateTime.fromMillisecondsSinceEpoch(json['dt'] * 1000),
      temperature: (json['main']['temp'] as num).toDouble(),
      humidity: json['main']['humidity'],
      windSpeed: (json['wind']?['speed'] as num?)?.toDouble() ?? 0.0,
      description: json['weather'][0]['description'],
      iconCode: json['weather'][0]['icon'],
      precipitationProbability: (json['pop'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class WeatherService {
  // Get your free API key from https://openweathermap.org/api
  static const String _apiKey = '7c4601d5ccf87b43c5f3a884c3ae9e47'; // Demo key - replace with your own
  static const String _baseUrl = 'https://api.openweathermap.org/data/2.5';

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

      final url = '$_baseUrl/weather?lat=${position.latitude}&lon=${position.longitude}&appid=$_apiKey&units=metric';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return WeatherData.fromJson(data);
      } else {
        throw Exception('Failed to load weather data: ${response.statusCode}');
      }
    } catch (e) {
      // Fallback to mock data for demo purposes
      return _getMockCurrentWeather();
    }
  }

  Future<List<ForecastData>> getForecast() async {
    try {
      final position = await _getCurrentPosition();

      final url = '$_baseUrl/forecast?lat=${position.latitude}&lon=${position.longitude}&appid=$_apiKey&units=metric';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> forecastList = data['list'];

        // Get next 7 days of forecast (taking one forecast per day at noon)
        final List<ForecastData> forecast = [];
        final Set<String> addedDays = {};

        for (var item in forecastList) {
          final forecastData = ForecastData.fromJson(item);
          final dayKey = '${forecastData.dateTime.year}-${forecastData.dateTime.month}-${forecastData.dateTime.day}';

          if (!addedDays.contains(dayKey) && forecast.length < 7) {
            forecast.add(forecastData);
            addedDays.add(dayKey);
          }
        }

        return forecast;
      } else {
        throw Exception('Failed to load forecast data: ${response.statusCode}');
      }
    } catch (e) {
      // Fallback to mock data for demo purposes
      return _getMockForecast();
    }
  }

  Future<List<HourlyWeatherData>> getHourlyForecast() async {
    try {
      final position = await _getCurrentPosition();

      final url = '$_baseUrl/forecast?lat=${position.latitude}&lon=${position.longitude}&appid=$_apiKey&units=metric';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> forecastList = data['list'];

        // Get next 24 hours of forecast data
        final List<HourlyWeatherData> hourlyForecast = [];
        final now = DateTime.now();

        for (var item in forecastList) {
          final hourlyData = HourlyWeatherData.fromJson(item);

          // Only include data for the next 24 hours
          if (hourlyData.dateTime.isAfter(now) &&
              hourlyData.dateTime.isBefore(now.add(const Duration(hours: 24))) &&
              hourlyForecast.length < 8) { // Show every 3 hours for next 24 hours
            hourlyForecast.add(hourlyData);
          }
        }

        return hourlyForecast;
      } else {
        throw Exception('Failed to load hourly forecast data: ${response.statusCode}');
      }
    } catch (e) {
      // Fallback to mock data for demo purposes
      return _getMockHourlyForecast();
    }
  }

  WeatherData _getMockCurrentWeather() {
    return WeatherData(
      cityName: 'Demo City',
      temperature: 24.5,
      feelsLike: 26.2,
      humidity: 65,
      pressure: 1013,
      windSpeed: 3.2,
      visibility: 10000,
      description: 'Clear sky',
      iconCode: '01d',
      timestamp: DateTime.now(),
    );
  }

  List<ForecastData> _getMockForecast() {
    final List<ForecastData> mockForecast = [];
    final now = DateTime.now();

    for (int i = 0; i < 7; i++) {
      final date = now.add(Duration(days: i));
      final baseTemp = 22.0 + (i * 2) + (i % 3) * 3;

      mockForecast.add(ForecastData(
        dateTime: date,
        temperature: baseTemp,
        minTemp: baseTemp - 5,
        maxTemp: baseTemp + 5,
        humidity: 60 + (i * 5),
        description: i % 3 == 0 ? 'Sunny' : i % 3 == 1 ? 'Partly cloudy' : 'Cloudy',
        iconCode: i % 3 == 0 ? '01d' : i % 3 == 1 ? '02d' : '03d',
      ));
    }

    return mockForecast;
  }

  List<HourlyWeatherData> _getMockHourlyForecast() {
    final List<HourlyWeatherData> mockHourlyForecast = [];
    final now = DateTime.now();

    for (int i = 1; i <= 8; i++) {
      final time = now.add(Duration(hours: i * 3));
      final baseTemp = 20.0 + (i * 2) + (i % 2) * 3;

      mockHourlyForecast.add(HourlyWeatherData(
        dateTime: time,
        temperature: baseTemp,
        humidity: 55 + (i * 3),
        windSpeed: 2.5 + (i * 0.5),
        description: i % 4 == 0 ? 'Clear' : i % 4 == 1 ? 'Partly cloudy' : i % 4 == 2 ? 'Cloudy' : 'Light rain',
        iconCode: i % 4 == 0 ? '01d' : i % 4 == 1 ? '02d' : i % 4 == 2 ? '03d' : '10d',
        precipitationProbability: i % 4 == 3 ? 0.8 : i % 4 == 2 ? 0.3 : 0.1,
      ));
    }

    return mockHourlyForecast;
  }
}