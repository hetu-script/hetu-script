enum HTResourceType {
  hetuModule,
  hetuScript,
  hetuLiteralCode,
  hetuValue,
  binary,
  unkown,
}

abstract class HTResource {
  static const hetuInternalModulePrefix = 'hetu:';
  static const hetuModule = '.ht';
  static const hetuScript = '.hts';
  static const json = '.json';
  static const jsonWithComments = '.jsonc';
}
