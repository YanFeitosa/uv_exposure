class Model {
  late double tep;
  late double _spf;
  double acumulatedExposurePercent = 00.0;

  Model(spf, skinType) {
    setTEP(skinType);
    _spf = spf;
  }

  void setTEP(String skinType) {
    switch (skinType) {
      case 'Type 0 - Test':
        tep = 0.1;
        break;
      case 'Type I - Very Fair':
        tep = 7.5;
        break;
      case 'Type II - Fair':
        tep = 15;
        break;
      case 'Type III - Medium Fair':
        tep = 25;
        break;
      case 'Type IV - Medium Dark':
        tep = 35;
        break;
      case 'Type V - Dark':
        tep = 50;
        break;
      case 'Type VI - Very Dark':
        tep = 75;
        break;
    }
  }

  int toSeconds(int hours, int minutes, int seconds) {
    return (hours * 3600) + (minutes * 60) + seconds;
  }

  int initialSafeExposureTime(double uvIndex) {
    late int safeTime;
    safeTime = ((_spf * tep) / uvIndex).toInt();

    safeTime = toSeconds(0, safeTime, 0);
    return safeTime;
  }

  void exposureAcumulator(double uvIndex, int time) {
    acumulatedExposurePercent += (uvIndex * time) / (tep * _spf);
  }

  double getAcumulatedExposure() {
    return acumulatedExposurePercent;
  }

  void setAcumulatedExposure(double value) {
    acumulatedExposurePercent = value;
  }

  int safeExposureTime(int secondsElapsed, double uvIndex) {
    late int safeTime;
    safeTime = ((secondsElapsed * 100) / acumulatedExposurePercent).toInt();

    return safeTime;
  }
}
