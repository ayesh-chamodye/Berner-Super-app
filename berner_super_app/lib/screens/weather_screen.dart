import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../services/weather_service.dart';

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  bool _isLoading = true;
  WeatherData? _currentWeather;
  List<ForecastData>? _forecast;
  List<HourlyWeatherData>? _hourlyForecast;
  String? _errorMessage;
  final WeatherService _weatherService = WeatherService();

  @override
  void initState() {
    super.initState();
    _fetchWeatherData();
  }

  Future<void> _fetchWeatherData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final currentWeather = await _weatherService.getCurrentWeather();
      final forecast = await _weatherService.getForecast();
      final hourlyForecast = await _weatherService.getHourlyForecast();

      setState(() {
        _currentWeather = currentWeather;
        _forecast = forecast;
        _hourlyForecast = hourlyForecast;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Widget _buildWeatherIcon(String iconUrl, {double size = 48}) {
    return Image.network(
      iconUrl,
      width: size,
      height: size,
      errorBuilder: (context, error, stackTrace) {
        return Icon(
          Icons.wb_sunny,
          size: size,
          color: AppColors.primaryOrange,
        );
      },
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return SizedBox(
          width: size,
          height: size,
          child: Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                  : null,
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Weather'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchWeatherData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: AppColors.error,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Error',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppColors.error,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _fetchWeatherData,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _buildWeatherContent(),
    );
  }

  Widget _buildWeatherContent() {
    if (_currentWeather == null) return const Center(child: Text('No data available'));

    return RefreshIndicator(
      onRefresh: _fetchWeatherData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Current weather card
            _buildCurrentWeatherCard(),

            const SizedBox(height: 16),

            // Weather details
            _buildWeatherDetailsCard(),

            const SizedBox(height: 16),

            // Hourly forecast
            if (_hourlyForecast != null && _hourlyForecast!.isNotEmpty) _buildHourlyForecast(),

            const SizedBox(height: 16),

            // Forecast chart
            if (_forecast != null && _forecast!.isNotEmpty) _buildForecastChart(),

            const SizedBox(height: 16),

            // 7-day forecast
            if (_forecast != null && _forecast!.isNotEmpty) _buildForecastList(),

            const SizedBox(height: 16),

            // Last updated
            _buildLastUpdatedCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentWeatherCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  Icons.location_on,
                  color: AppColors.primaryOrange,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  _currentWeather!.cityName,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth > 400) {
                  // Wide layout - side by side
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${_currentWeather!.temperature.round()}°C',
                            style: Theme.of(context).textTheme.displayMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryOrange,
                            ),
                          ),
                          Text(
                            'Feels like ${_currentWeather!.feelsLike.round()}°C',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                      Column(
                        children: [
                          _buildWeatherIcon(_currentWeather!.iconUrl, size: 64),
                          const SizedBox(height: 8),
                          Text(
                            _currentWeather!.description.toUpperCase(),
                            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.secondaryBlue,
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                } else {
                  // Narrow layout - stacked vertically
                  return Column(
                    children: [
                      _buildWeatherIcon(_currentWeather!.iconUrl, size: 80),
                      const SizedBox(height: 12),
                      Text(
                        '${_currentWeather!.temperature.round()}°C',
                        style: Theme.of(context).textTheme.displayLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryOrange,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Feels like ${_currentWeather!.feelsLike.round()}°C',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _currentWeather!.description.toUpperCase(),
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.secondaryBlue,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeatherDetailsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Details',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth > 600) {
                  // Desktop/tablet layout - 4 items in a single row
                  return Row(
                    children: [
                      Expanded(
                        child: _buildDetailItem(
                          Icons.water_drop,
                          'Humidity',
                          '${_currentWeather!.humidity}%',
                        ),
                      ),
                      Expanded(
                        child: _buildDetailItem(
                          Icons.speed,
                          'Wind',
                          '${_currentWeather!.windSpeed} m/s',
                        ),
                      ),
                      Expanded(
                        child: _buildDetailItem(
                          Icons.compress,
                          'Pressure',
                          '${_currentWeather!.pressure} hPa',
                        ),
                      ),
                      Expanded(
                        child: _buildDetailItem(
                          Icons.visibility,
                          'Visibility',
                          '${(_currentWeather!.visibility / 1000).toStringAsFixed(1)} km',
                        ),
                      ),
                    ],
                  );
                } else {
                  // Mobile layout - 2x2 grid
                  return Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _buildDetailItem(
                              Icons.water_drop,
                              'Humidity',
                              '${_currentWeather!.humidity}%',
                            ),
                          ),
                          Expanded(
                            child: _buildDetailItem(
                              Icons.speed,
                              'Wind',
                              '${_currentWeather!.windSpeed} m/s',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildDetailItem(
                              Icons.compress,
                              'Pressure',
                              '${_currentWeather!.pressure} hPa',
                            ),
                          ),
                          Expanded(
                            child: _buildDetailItem(
                              Icons.visibility,
                              'Visibility',
                              '${(_currentWeather!.visibility / 1000).toStringAsFixed(1)} km',
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForecastChart() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '7-Day Temperature Forecast',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 5,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: Theme.of(context).dividerColor.withValues(alpha: 0.2),
                        strokeWidth: 1,
                      );
                    },
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        interval: 1,
                        getTitlesWidget: (double value, TitleMeta meta) {
                          final index = value.toInt();
                          if (index >= 0 && index < _forecast!.length) {
                            return SideTitleWidget(
                              axisSide: meta.axisSide,
                              child: Text(
                                DateFormat('E').format(_forecast![index].dateTime),
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 5,
                        reservedSize: 40,
                        getTitlesWidget: (double value, TitleMeta meta) {
                          return Text(
                            '${value.toInt()}°',
                            style: Theme.of(context).textTheme.bodySmall,
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border.all(
                      color: Theme.of(context).dividerColor.withValues(alpha: 0.2),
                    ),
                  ),
                  minX: 0,
                  maxX: (_forecast!.length - 1).toDouble(),
                  minY: _forecast!.map((e) => e.minTemp).reduce((a, b) => a < b ? a : b) - 5,
                  maxY: _forecast!.map((e) => e.maxTemp).reduce((a, b) => a > b ? a : b) + 5,
                  lineBarsData: [
                    // Max temperature line
                    LineChartBarData(
                      spots: _forecast!.asMap().entries.map((entry) {
                        return FlSpot(entry.key.toDouble(), entry.value.maxTemp);
                      }).toList(),
                      isCurved: true,
                      color: AppColors.error,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(show: false),
                    ),
                    // Min temperature line
                    LineChartBarData(
                      spots: _forecast!.asMap().entries.map((entry) {
                        return FlSpot(entry.key.toDouble(), entry.value.minTemp);
                      }).toList(),
                      isCurved: true,
                      color: AppColors.secondaryBlue,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(show: false),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: AppColors.error,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                const SizedBox(width: 8),
                Text('Max', style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(width: 20),
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: AppColors.secondaryBlue,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                const SizedBox(width: 8),
                Text('Min', style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForecastList() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '7-Day Forecast',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ..._forecast!.map((forecast) => _buildForecastItem(forecast)),
          ],
        ),
      ),
    );
  }

  Widget _buildForecastItem(ForecastData forecast) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 60,
            child: Text(
              DateFormat('EEE').format(forecast.dateTime),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 16),
          _buildWeatherIcon(forecast.iconUrl, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              forecast.description,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          Text(
            '${forecast.minTemp.round()}°',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.secondaryBlue,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${forecast.maxTemp.round()}°',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.error,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLastUpdatedCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              Icons.access_time,
              size: 16,
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppColors.darkTextSecondary
                  : AppColors.textSecondary,
            ),
            const SizedBox(width: 8),
            Text(
              'Last updated: ${DateFormat('MMM dd, HH:mm').format(_currentWeather!.timestamp)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(
          icon,
          color: AppColors.primaryOrange,
          size: 32,
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: Theme.of(context).brightness == Brightness.dark
                ? AppColors.darkTextSecondary
                : AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildHourlyForecast() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '24-Hour Forecast',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _hourlyForecast!.length,
                itemBuilder: (context, index) {
                  final hourlyData = _hourlyForecast![index];
                  return Container(
                    width: 80,
                    margin: const EdgeInsets.only(right: 12),
                    child: Column(
                      children: [
                        Text(
                          DateFormat('HH:mm').format(hourlyData.dateTime),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).brightness == Brightness.dark
                                ? AppColors.darkTextSecondary
                                : AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildWeatherIcon(hourlyData.iconUrl, size: 32),
                        const SizedBox(height: 4),
                        Text(
                          '${hourlyData.temperature.round()}°',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryOrange,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Container(
                          width: 4,
                          height: 20,
                          decoration: BoxDecoration(
                            color: AppColors.secondaryBlue.withValues(
                              alpha: hourlyData.precipitationProbability,
                            ),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${(hourlyData.precipitationProbability * 100).round()}%',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontSize: 10,
                            color: Theme.of(context).brightness == Brightness.dark
                                ? AppColors.darkTextSecondary
                                : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}