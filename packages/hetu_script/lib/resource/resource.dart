enum ResourceType {
  hetuModule,
  hetuScript,
  hetuExpression,
  binary,
  unkown,
}

abstract class HTResource {
  static const hetuModule = '.ht';
  static const hetuScript = '.hts';
  static const json = '.json';
}
