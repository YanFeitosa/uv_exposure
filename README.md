# SunSense — UV Exposure Monitoring App

Aplicativo Flutter para monitoramento de exposição solar UV em tempo real, integrado a um sensor IoT. Calcula o tempo seguro de exposição com base no fototipo de pele (escala Fitzpatrick) e fator de proteção solar (FPS), alertando o usuário ao atingir limites perigosos.

## Funcionalidades

- **Monitoramento em tempo real**: índice UV, tempo decorrido, tempo seguro restante e % de exposição acumulada, atualizados a cada segundo
- **Cálculo científico**: tempo seguro = `SPF × TEP / UV`, onde TEP é o tempo de eritema por fototipo Fitzpatrick
- **Comunicação IoT**: busca dados UV via HTTP do sensor SunSense (mDNS com fallback IP)
- **Alarme e notificações**: aviso sonoro e notificações locais ao atingir 75% e 100% de exposição
- **Execução em segundo plano (Android)**: Foreground Service mantém o monitoramento ativo quando o app é minimizado, com notificação persistente mostrando progresso
- **Detecção e compensação de gap**: quando o OS suspende o app, detecta automaticamente o tempo perdido e compensa a exposição com o último UV conhecido (até 20 min)
- **Resiliência de conexão**: fallback para cache de 5 minutos quando o sensor fica inacessível, com banner de countdown e reconexão automática
- **Histórico de sessões**: estatísticas, gráfico de barras diário e lista detalhada com filtros por período
- **Modo Demo**: dados UV simulados (senóide) para testes sem hardware
- **Persistência**: salva progresso a cada 30s e restaura sessões interrompidas

## Arquitetura

```
lib/
├── main.dart
├── core/
│   ├── constants/     (cores, constantes, strings pt-BR)
│   ├── models/        (ExposureModel, UVReading, ExposureSession)
│   ├── providers/     (ExposureProvider, HistoryProvider)
│   ├── services/      (UV HTTP, Storage, Notifications, Foreground Service)
│   └── theme/         (Material 3)
├── features/
│   ├── home/          (seleção SPF/fototipo)
│   ├── monitor/       (monitoramento em tempo real)
│   └── history/       (histórico com gráficos)
└── shared/widgets/    (InfoBox, ConnectionStatusBadge)
```

**Padrão de estado**: Provider (ChangeNotifier)  
**Persistência**: SharedPreferences (JSON)  
**Comunicação**: HTTP (mDNS + IP fallback)

## Dependências

| Pacote | Função |
|--------|--------|
| `provider` | Gerenciamento de estado |
| `http` | Requisições HTTP para o sensor IoT |
| `shared_preferences` | Persistência local |
| `audioplayers` | Alarme sonoro |
| `flutter_local_notifications` | Notificações locais |
| `fl_chart` | Gráficos de barras (histórico) |
| `flutter_foreground_task` | Foreground Service Android |

## Requisitos

- Flutter SDK ^3.5.1 / Dart ^3.5.1
- Android: compileSdk 36, targetSdk 36
- Dispositivo IoT SunSense na mesma rede WiFi (ou usar Modo Demo)

## Como rodar

```bash
flutter pub get
flutter run
```

### Build APK

```bash
flutter build apk --release
```

O APK gerado estará em `build/app/outputs/flutter-apk/app-release.apk`.

## Testes

```bash
flutter test
```

Cobertura: modelo de exposição, cores dinâmicas, constantes e widget da HomeScreen.

## Permissões Android

- `INTERNET` — comunicação com sensor
- `FOREGROUND_SERVICE` / `FOREGROUND_SERVICE_SPECIAL_USE` — manter app ativo em background
- `WAKE_LOCK` — impedir suspensão durante monitoramento
- `REQUEST_IGNORE_BATTERY_OPTIMIZATIONS` — solicitar desativação de economia de bateria
- `POST_NOTIFICATIONS` — notificações de alerta

## Licença

Projeto acadêmico — uso interno.
