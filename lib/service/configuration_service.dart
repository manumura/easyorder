import 'package:easyorder/repository/configuration_repository.dart';
import 'package:easyorder/widgets/helpers/logger.dart';
import 'package:logger/logger.dart';

abstract class ConfigurationService {
  String getString({required String key});

  void dispose();
}

class ConfigurationServiceImpl implements ConfigurationService {
  ConfigurationServiceImpl({
    required this.configurationRepository,
  }) {
    logger.d('----- Building ConfigurationServiceImpl -----');
  }

  ConfigurationRepository configurationRepository;
  final Logger logger = getLogger();

  @override
  String getString({required String key}) {
    return configurationRepository.getString(key: key);
  }

  @override
  void dispose() {
    logger.d('*** DISPOSE ConfigurationService ***');
  }
}
