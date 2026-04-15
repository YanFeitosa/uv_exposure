class AppStrings {
  AppStrings._();

  // App
  static const String appName = 'SunSense';
  static const String appTitle = 'SUNSENSE';

  // Tela Inicial
  static const String spfLabel = 'Fator de Proteção Solar';
  static const String skinTypeLabel = 'Fototipo de Pele';
  static const String startMonitoring = 'Iniciar Monitoramento';
  static const String endMonitoring = 'Finalizar Monitoramento';
  static const String noSunscreen = 'Sem protetor solar';

  // Configurações
  static const String settings = 'Configurações';
  static const String demoModeLabel = 'Modo Demo (dados UV simulados)';
  static const String soundAlarmLabel = 'Alarme sonoro de exposição';
  static const String soundAlarmDescription =
      'Toca sirene ao atingir 100% de exposição';

  // Popup de fototipo (primeira abertura)
  static const String skinTypePopupTitle = 'Selecione seu Fototipo de Pele';
  static const String skinTypePopupBody =
      'Para calcular o tempo seguro de exposição solar, '
      'precisamos saber seu fototipo de pele.\n\n'
      'Você pode alterar essa opção depois em Configurações.';
  static const String save = 'Salvar';

  // Popup de iniciar monitoramento
  static const String startMonitoringTitle = 'Iniciar Monitoramento';
  static const String selectSpfMessage =
      'Selecione o fator de proteção solar que está usando:';
  static const String start = 'Iniciar';

  // Tela de Monitoramento
  static const String elapsedTime = 'Tempo Decorrido';
  static const String safeExposureTime = 'Tempo Seguro';
  static const String accumulatedExposure = 'Exposição Acumulada';
  static const String globalUVIndex = 'Índice UV Global';
  static const String confirm = 'Confirmar';
  static const String cancel = 'Cancelar';
  static const String confirmBackMessage =
      'O monitoramento será reiniciado. Tem certeza que deseja voltar?';
  static const String stopAlarm = 'Parar Alarme';
  static const String demoBannerText = 'MODO DEMO — Dados UV simulados';
  static const String monitoringPaused = 'Monitoramento Pausado';
  static const String retryReconnect = 'Tentar Reconectar';
  static const String connectionLostUsingCache =
      'Conexão perdida - Usando cache';

  // Descrições de Índice UV (escala OMS)
  static const String uvLow = 'Baixo';
  static const String uvModerate = 'Moderado';
  static const String uvHigh = 'Alto';
  static const String uvVeryHigh = 'Muito Alto';
  static const String uvExtreme = 'Extremo';

  // Status de Conexão
  static const String connected = 'Conectado';
  static const String disconnected = 'Desconectado';
  static const String connecting = 'Conectando';
  static const String cached = 'Cache';
  static const String offline = 'Offline';
  static const String deviceNotFound =
      'Dispositivo não encontrado. Verifique se está conectado à mesma rede WiFi do dispositivo SunSense.';
  static const String retryConnection = 'Tentar reconectar';
  static const String cachedDataMessage =
      'Usando dados em cache. Dispositivo inacessível.';

  // Diálogo de Permissão de Notificação
  static const String notificationsDialogTitle = 'Notificações';
  static const String notificationsDialogBody =
      'Para sua segurança, o SunSense precisa enviar notificações '
      'quando você atingir limites de exposição solar.\n\n'
      'Isso ajuda a proteger sua pele de queimaduras.';
  static const String later = 'Depois';
  static const String allow = 'Permitir';
  static const String demoMode = 'Modo Demo';
  static const String wifiInfoMessage =
      'Certifique-se de que seu celular está conectado à mesma rede WiFi do dispositivo SunSense.';
  static const String spfPrefix = 'FPS';

  // Fototipos de Pele
  static const List<String> skinTypes = [
    'Tipo 0 - Demo',
    'Tipo I - Muito Clara',
    'Tipo II - Clara',
    'Tipo III - Média Clara',
    'Tipo IV - Média Escura',
    'Tipo V - Escura',
    'Tipo VI - Muito Escura',
  ];

  // Valores de FPS
  static const List<String> spfValues = ['0', '15', '30', '50', '70'];

  // Notificações
  static const String notificationChannelId = 'uv_exposure_alerts';
  static const String notificationChannelName = 'Alertas de Exposição UV';
  static const String notificationChannelDescription =
      'Alertas de níveis de exposição UV';
  static const String exposureWarningTitle = 'Aviso de Exposição UV';
  static const String exposureCriticalTitle = 'Exposição UV Crítica!';
  static const String exposureWarningBody =
      'Você atingiu {percent}% do tempo seguro de exposição.';
  static const String exposureCriticalBody =
      'Procure sombra imediatamente! Exposição máxima segura atingida.';

  // Notificações de Conexão/Cache
  static const String cacheNotificationTitle = 'Conexão Perdida com o Sensor';
  static const String cacheNotificationBody =
      'O SunSense perdeu a conexão com o sensor UV. '
      'Usando dados em cache temporariamente.';
  static const String stoppedNotificationTitle = 'Monitoramento Pausado';
  static const String stoppedNotificationBody =
      'O monitoramento foi pausado após {minutes} minutos sem conexão com o sensor. '
      'Reconecte-se à rede WiFi do SunSense para continuar.';

  // Histórico
  static const String exposureHistory = 'Histórico de Exposição';
  static const String noHistoryData = 'Nenhum dado de exposição registrado.';
  static const String today = 'Hoje';
  static const String yesterday = 'Ontem';
  static const String atTime = 'às';
  static const String last7Days = 'Últimos 7 Dias';
  static const String last30Days = 'Últimos 30 Dias';
  static const String statistics = 'Estatísticas';
  static const String sessions = 'Sessões';
  static const String averageExposure = 'Exp. Média';
  static const String maxUV = 'UV Máx.';
  static const String totalTime = 'Tempo Total';
  static const String dailyExposure = 'Exposição Diária';
  static const String tryAgain = 'Tentar Novamente';
  static const String durationLabel = 'Duração';

  // Mensagens de Erro e Status
  static const String monitoringStoppedNoConnection =
      'Monitoramento pausado: sem conexão por {minutes} minutos';
  static const String monitoringWillPauseIn =
      'O monitoramento será pausado em {minutes}m {seconds}s';
  static const String noConnectionRetryMessage =
      'Sem conexão com o dispositivo por mais de {minutes} minutos.\n'
      'Reconecte-se à rede WiFi do SunSense e tente novamente.';
  static const String unexpectedError = 'Erro inesperado';
  static const String networkError =
      'Erro de rede: impossível conectar ao dispositivo SunSense. '
      'Verifique se você está conectado à mesma rede WiFi.';
  static const String failedToLoadUVData = 'Falha ao carregar dados UV';
  static const String failedToLoadHistory = 'Falha ao carregar histórico';
  static const String failedToLoadSessions = 'Falha ao carregar sessões';

  // Compensação de Gap (suspensão do sistema)
  static const String gapNotificationTitle = 'Exposição Simulada';
  static const String gapNotificationBody =
      'O sistema suspendeu o SunSense por {minutes}. '
      'A exposição foi estimada com o último índice UV conhecido.';
  static const String gapDialogTitle = 'Atenção — Exposição Simulada';
  static const String gapDialogBody =
      'O sistema operacional suspendeu o SunSense por {duration}.\n\n'
      'A exposição durante esse período foi estimada usando o último '
      'índice UV conhecido ({uvIndex}). O resultado pode não ser 100% preciso.';
  static const String gapDialogBodyExceeded =
      'O sistema operacional suspendeu o SunSense por {duration}.\n\n'
      'Apenas os primeiros {maxMinutes} minutos foram simulados '
      '(limite máximo de compensação). O tempo restante foi descartado.';
  static const String gapDialogBatteryHint =
      '\nPara evitar isso, desative a economia de bateria '
      'para o SunSense nas configurações do Android.';
  static const String gapDismiss = 'Entendi';
  static const String gapOpenBatterySettings = 'Config. Bateria';

  // Exportação de dados
  static const String exportData = 'Exportar Dados';
  static const String exportCSV = 'Exportar CSV';
  static const String exportJSON = 'Exportar JSON';
  static const String exportSuccess = 'Dados exportados com sucesso';
  static const String exportError = 'Erro ao exportar dados';
  static const String exportNoData = 'Nenhum dado para exportar';
  static const String exportFileSaved = 'Arquivo salvo em:';

  // Tela Sobre
  static const String about = 'Sobre';
  static const String aboutTitle = 'Sobre o SunSense';
  static const String aboutVersion = 'Versão';
  static const String aboutDescription =
      'O SunSense é uma ferramenta educacional e experimental para monitoramento '
      'de exposição à radiação ultravioleta.';
  static const String aboutDisclaimer =
      'AVISO: Este aplicativo NÃO substitui orientação médica profissional. '
      'Os cálculos de tempo seguro de exposição são estimativas baseadas em '
      'modelos simplificados e não consideram todos os fatores individuais.\n\n'
      'Consulte sempre um dermatologista para orientações sobre proteção solar.';
  static const String aboutTechnology =
      'Tecnologias: Flutter, ESP32, Sensor VEML6075';

  // Popup de sessão (fototipo + FPS)
  static const String sessionConfigTitle = 'Configurar Sessão';
  static const String sessionConfigBody =
      'Selecione o fototipo de pele e o fator de proteção solar para esta sessão:';

  // Foreground Service
  static const String foregroundNotificationTitle = 'SunSense — Monitorando';
  static const String foregroundNotificationText =
      'Exposição: {percent}% • Tempo: {time}';
  static const String foregroundNotificationInitial =
      'Monitoramento UV ativo — 0.0%';
}
