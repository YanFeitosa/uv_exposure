# SunSense — UV Exposure Monitoring App

<p align="center">
  <strong>Versão 3.0.1</strong> · Flutter · Dart ^3.5.1
</p>

Aplicativo Flutter para **monitoramento de exposição solar UV em tempo real**, integrado a um dispositivo IoT (sensor UV). Calcula o tempo seguro de exposição com base no **fototipo de pele (escala Fitzpatrick)** e **fator de proteção solar (FPS)**, alertando o usuário ao atingir limites perigosos de radiação ultravioleta.

O projeto foi desenvolvido como parte de um **Trabalho de Conclusão de Curso (TCC)** com foco em saúde digital, IoT e proteção dermatológica.

---

## Funcionalidades Principais

| Funcionalidade | Descrição |
|----------------|-----------|
| **Monitoramento em tempo real** | Índice UV, tempo decorrido, tempo seguro restante e % de exposição acumulada — atualizados a cada segundo |
| **Cálculo científico de exposição** | Tempo seguro = `SPF × TEP / UV`, onde TEP é o tempo mínimo de eritema por fototipo Fitzpatrick |
| **Comunicação IoT** | Busca dados UV via HTTP do sensor SunSense (mDNS `sunsense.local` com fallback para IP fixo) |
| **Alarme e notificações** | Aviso sonoro (loop de áudio) e notificações locais ao atingir 75% (aviso) e 100% (crítico) de exposição |
| **Foreground Service (Android)** | Mantém o monitoramento ativo com notificação persistente mostrando % de exposição e tempo decorrido |
| **Detecção e compensação de gap** | Detecta suspensão do app pelo OS e compensa a exposição perdida com o último UV conhecido (até 20 min) |
| **Resiliência de conexão** | Fallback para cache de 5 min quando o sensor fica inacessível, com banner de countdown e reconexão automática |
| **Histórico de sessões** | Estatísticas agregadas, gráfico de barras diário (fl_chart) e lista detalhada com filtros por período |
| **Tela de configurações** | Seleção de fototipo de pele, toggle de alarme sonoro e modo demo |
| **Modo Demo** | Dados UV simulados (senóide com período de 120s) para testes e demonstrações sem hardware |
| **Persistência e restauração** | Salva progresso a cada 30s e oferece restauração de sessões interrompidas ao reabrir o app |
| **Multiplataforma** | Suporte a Android, iOS, Web, Linux, macOS e Windows (com adaptações por plataforma) |

---

## Arquitetura do Sistema

O projeto segue uma arquitetura **feature-first** com camada `core` compartilhada e gerenciamento de estado via **Provider (ChangeNotifier)**.

```
lib/
├── main.dart                              # Ponto de entrada, MultiProvider, rotas
├── core/
│   ├── constants/
│   │   ├── app_colors.dart                # Paleta de cores (UV WHO, exposição, tema)
│   │   ├── app_constants.dart             # Constantes globais (URLs, TEP, thresholds, cache)
│   │   └── app_strings.dart               # Strings centralizadas em pt-BR
│   ├── models/
│   │   └── exposure_model.dart            # UVReading, ExposureSession, ExposureModel (cálculos)
│   ├── providers/
│   │   ├── exposure_provider.dart         # Provider principal — timer, UV, alarme, persistência
│   │   └── history_provider.dart          # Provider do histórico — filtros, estatísticas, gráficos
│   ├── services/
│   │   ├── foreground_service.dart        # Foreground Service Android (manter app vivo)
│   │   ├── notification_service.dart      # Notificações locais (Android/iOS)
│   │   ├── storage_service.dart           # Persistência via SharedPreferences (JSON)
│   │   └── uv_data_service.dart           # Cliente HTTP para sensor IoT (mDNS + IP fallback)
│   └── theme/
│       └── app_theme.dart                 # Tema Material 3 (claro)
├── features/
│   ├── home/
│   │   └── home_screen.dart               # Tela inicial — logo, seleção SPF, restauração de sessão
│   ├── monitor/
│   │   └── monitor_screen.dart            # Dashboard de monitoramento em tempo real
│   ├── history/
│   │   └── history_screen.dart            # Histórico com gráficos e estatísticas
│   └── settings/
│       └── settings_screen.dart           # Configurações (fototipo, alarme, modo demo)
└── shared/
    └── widgets/
        ├── connection_status_badge.dart   # Badge de status de conexão (4 estados visuais)
        └── info_box.dart                  # Caixa de métrica reutilizável
```

### Fluxo de Navegação

```
HomeScreen (/)
  ├── [Ícone engrenagem] → SettingsScreen (/settings)
  ├── [Ícone relógio]    → HistoryScreen (/history)
  └── [Botão Iniciar]    → Popup SPF → MonitorScreen (push)
                                          ├── [Voltar] → Diálogo de confirmação → pop
                                          └── [Finalizar] → Salva sessão → pop
```

### Padrões e Tecnologias

| Aspecto | Tecnologia |
|---------|------------|
| **Gerenciamento de estado** | Provider (ChangeNotifier) |
| **Persistência local** | SharedPreferences (serialização JSON) |
| **Comunicação IoT** | HTTP (mDNS + IP fallback, cache em memória) |
| **UI** | Material Design 3 |
| **Gráficos** | fl_chart (barras) |
| **Background** | Android Foreground Service + detecção de gap |

---

## Modelo de Cálculo de Exposição UV

O app utiliza um modelo baseado na **escala de fototipos de Fitzpatrick** e na dose eritematosa mínima (MED).

### Fórmulas Principais

- **Tempo seguro inicial** (segundos):

$$T_{seguro} = \frac{SPF \times TEP}{UV} \times 60$$

- **Acúmulo de exposição** por tick (percentual):

$$\Delta E = \frac{UV \times \Delta t}{TEP \times SPF \times 60} \times 100$$

- **Tempo seguro restante**:

$$T_{restante} = \frac{T_{decorrido} \times 100}{E_{acumulada}} - T_{decorrido}$$

### Tabela TEP por Fototipo (Fitzpatrick)

| Fototipo | Descrição | TEP (min) |
|----------|-----------|-----------|
| Tipo I | Muito Clara | 7,5 |
| Tipo II | Clara | 15,0 |
| Tipo III | Morena Clara | 30,0 |
| Tipo IV | Morena Moderada | 45,0 |
| Tipo V | Morena Escura | 60,0 |
| Tipo VI | Negra | 75,0 |
| Demo | Demonstração | 0,1 |

### Escala UV (OMS)

| Índice UV | Classificação | Cor |
|-----------|--------------|-----|
| 0–2 | Baixo | Verde |
| 3–5 | Moderado | Amarelo |
| 6–7 | Alto | Laranja |
| 8–10 | Muito Alto | Vermelho |
| 11+ | Extremo | Roxo |

---

## Dependências

| Pacote | Versão | Função |
|--------|--------|--------|
| `http` | ^1.2.2 | Requisições HTTP para o sensor IoT |
| `provider` | ^6.1.2 | Gerenciamento de estado (ChangeNotifier) |
| `shared_preferences` | ^2.3.3 | Persistência local chave-valor |
| `path_provider` | ^2.1.5 | Caminhos do sistema de arquivos |
| `audioplayers` | ^6.1.0 | Reprodução de alarme sonoro |
| `flutter_local_notifications` | ^18.0.1 | Notificações locais (Android/iOS) |
| `fl_chart` | ^0.69.2 | Gráficos de barras no histórico |
| `flutter_foreground_task` | ^9.2.1 | Foreground Service Android |
| `cupertino_icons` | ^1.0.8 | Ícones estilo iOS |

### Dependências de Desenvolvimento

| Pacote | Versão | Função |
|--------|--------|--------|
| `flutter_test` | SDK | Framework de testes |
| `flutter_lints` | ^4.0.0 | Regras de lint recomendadas |
| `flutter_launcher_icons` | ^0.14.3 | Geração automática de ícones do app |

---

## Requisitos

- **Flutter SDK** ^3.5.1 / **Dart** ^3.5.1
- **Android**: compileSdk 36, targetSdk 36, minSdk 21
- **Dispositivo IoT SunSense** na mesma rede WiFi (ou utilizar o **Modo Demo**)

---

## Como Executar

### Instalar dependências

```bash
flutter pub get
```

### Executar em modo debug

```bash
flutter run
```

### Build APK (release)

```bash
flutter build apk --release
```

O APK gerado estará em `build/app/outputs/flutter-apk/app-release.apk`.

### Gerar ícones do launcher

```bash
dart run flutter_launcher_icons
```

---

## Testes

```bash
flutter test
```

### Cobertura dos Testes

| Arquivo de Teste | O que Testa |
|-----------------|-------------|
| `test/exposure_model_test.dart` | Modelo de exposição: TEP, tempo seguro, acúmulo, thresholds, serialização JSON |
| `test/app_colors_test.dart` | Cores dinâmicas: escala UV (5 faixas WHO) e cores de exposição por percentual |
| `test/constants_test.dart` | Constantes globais: tabela TEP, thresholds, timeouts, URLs, strings |
| `test/widget_test.dart` | Widget da HomeScreen: renderização do título e elementos de UI |

---

## Permissões Android

| Permissão | Finalidade |
|-----------|-----------|
| `INTERNET` | Comunicação HTTP com o sensor IoT |
| `FOREGROUND_SERVICE` | Manter o app ativo em segundo plano |
| `FOREGROUND_SERVICE_SPECIAL_USE` | Tipo de serviço conforme política do Google Play |
| `WAKE_LOCK` | Impedir suspensão do dispositivo durante o monitoramento |
| `REQUEST_IGNORE_BATTERY_OPTIMIZATIONS` | Solicita exclusão de otimização de bateria |
| `POST_NOTIFICATIONS` | Notificações de alerta de exposição (Android 13+) |
| `VIBRATE` | Vibração nas notificações |

---

## Estrutura de Assets

| Asset | Uso |
|-------|-----|
| `assets/images/image.png` | Logo/ilustração na tela inicial |
| `assets/images/logo.png` | Ícone do launcher |
| `assets/audio/alarm.mp3` | Som de alarme ao atingir 100% de exposição |

---

## Licença

Projeto acadêmico — **Trabalho de Conclusão de Curso (TCC)** — uso interno.
