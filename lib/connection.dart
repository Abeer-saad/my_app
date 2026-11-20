// One API address for App1 and App2. Default: Android emulator -> this PC.
const apiUrl = String.fromEnvironment(
  'API_URL',
  defaultValue: 'http://10.0.2.2:63728',
);
