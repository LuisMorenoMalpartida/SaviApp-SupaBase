enum LogLevel { debug, info, error }

class Logger {
  LogLevel level = LogLevel.debug;

  void debug(String msg) {
    if (level.index <= LogLevel.debug.index) {
      // ignore: avoid_print
      print('[DEBUG] $msg');
    }
  }

  void info(String msg) {
    if (level.index <= LogLevel.info.index) {
      // ignore: avoid_print
      print('[INFO] $msg');
    }
  }

  void error(String msg) {
    if (level.index <= LogLevel.error.index) {
      // ignore: avoid_print
      print('[ERROR] $msg');
    }
  }
}

final logger = Logger();

void initLogger({LogLevel level = LogLevel.debug}) {
  logger.level = level;
}
