import 'package:easyorder/bloc/auth_bloc.dart';
import 'package:easyorder/bloc/cart_bloc.dart';
import 'package:easyorder/bloc/category_bloc.dart';
import 'package:easyorder/bloc/customer_bloc.dart';
import 'package:easyorder/bloc/order_bloc.dart';
import 'package:easyorder/bloc/product_bloc.dart';
import 'package:easyorder/bloc/user_bloc.dart';
import 'package:easyorder/models/config.dart';
import 'package:easyorder/models/product_model.dart';
import 'package:easyorder/models/user_model.dart';
import 'package:easyorder/repository/auth_repository.dart';
import 'package:easyorder/repository/category_repository.dart';
import 'package:easyorder/repository/configuration_repository.dart';
import 'package:easyorder/repository/customer_repository.dart';
import 'package:easyorder/repository/order_repository.dart';
import 'package:easyorder/repository/product_repository.dart';
import 'package:easyorder/repository/user_repository.dart';
import 'package:easyorder/service/configuration_service.dart';
import 'package:easyorder/service/local_cache_service.dart';
import 'package:easyorder/service/local_storage_service.dart';
import 'package:easyorder/state/category_list_state_notifier.dart';
import 'package:easyorder/state/category_paginated_list_state.dart';
import 'package:easyorder/state/customer_list_state_notifier.dart';
import 'package:easyorder/state/customer_paginated_list_state.dart';
import 'package:easyorder/state/product_list_state_notifier.dart';
import 'package:easyorder/state/product_paginated_list_state.dart';
import 'package:easyorder/state/service_locator.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

// Authentication
final Provider<AuthBloc> authBlocProvider = Provider<AuthBloc>(
  (Ref<AuthBloc> ref) => AuthBlocImpl(
    authRepository: AuthRepositoryFirebaseImpl(),
  ),
);

final StreamProvider<UserModel?> user$Provider = StreamProvider<UserModel?>(
  (Ref<AsyncValue<UserModel?>> ref) => ref.watch(authBlocProvider).user$,
);

// User
final Provider<UserBloc> userBlocProvider = Provider<UserBloc>(
  (Ref<UserBloc> ref) => UserBlocImpl(
    userRepository: UserRepositoryFirebaseImpl(),
  ),
);

// Category
final FutureProvider<CategoryBloc?> categoryBlocProvider =
    FutureProvider<CategoryBloc?>(
  (Ref<AsyncValue<CategoryBloc?>> ref) async {
    final UserModel? user = await ref.watch(user$Provider.future);
    if (user == null) {
      return null;
    }
    final CategoryBloc categoryBloc = CategoryBlocImpl(
        user: user, categoryRepository: CategoryRepositoryFirebaseImpl());
    ref.onDispose(() {
      categoryBloc.dispose();
    });
    return categoryBloc;
  },
);

final StateNotifierProvider<CategoryListStateNotifier,
        CategoryPaginatedListState> categoryListStateNotifierProvider =
    StateNotifierProvider<CategoryListStateNotifier,
        CategoryPaginatedListState>(
  (StateNotifierProviderRef<CategoryListStateNotifier,
          CategoryPaginatedListState>
      ref) {
    final AsyncValue<CategoryBloc?> categoryBloc$ =
        ref.watch(categoryBlocProvider);

    return categoryBloc$.when(
      data: (CategoryBloc? categoryBloc) {
        final CategoryListStateNotifier categoryListStateNotifier =
            CategoryListStateNotifier(categoryBloc);

        ref.onDispose(() {
          categoryListStateNotifier.dispose();
        });

        return categoryListStateNotifier;
      },
      loading: () => CategoryListStateNotifier(null),
      error: (Object error, StackTrace? stackTrace) =>
          throw Exception('Error while getting categoryBloc'),
    );
  },
);

// Product
final FutureProvider<ProductBloc?> productBlocProvider =
    FutureProvider<ProductBloc?>(
  (Ref<AsyncValue<ProductBloc?>> ref) async {
    final UserModel? user = await ref.watch(user$Provider.future);
    if (user == null) {
      return null;
    }
    final ProductBloc productBloc = ProductBlocImpl(
        user: user, productRepository: ProductRepositoryFirebaseImpl());
    ref.onDispose(() {
      productBloc.dispose();
    });
    return productBloc;
  },
);

final StreamProvider<List<ProductModel>> activeProducts$Provider =
    StreamProvider<List<ProductModel>>(
        (Ref<AsyncValue<List<ProductModel>>> ref) {
  final AsyncValue<ProductBloc?> productBloc$ = ref.watch(productBlocProvider);
  return productBloc$.when(
    data: (ProductBloc? productBloc) {
      if (productBloc == null) {
        return Stream<List<ProductModel>>.error(
            Exception('ProductBloc is null'));
      }
      return productBloc.activeProducts$;
    },
    loading: () {
      return const Stream<List<ProductModel>>.empty();
    },
    error: (Object error, _) {
      return Stream<List<ProductModel>>.error(error);
    },
  );
});

final StateNotifierProvider<ProductListStateNotifier, ProductPaginatedListState>
    productListStateNotifierProvider =
    StateNotifierProvider<ProductListStateNotifier, ProductPaginatedListState>(
  (StateNotifierProviderRef<ProductListStateNotifier, ProductPaginatedListState>
      ref) {
    final AsyncValue<ProductBloc?> productBloc$ =
        ref.watch(productBlocProvider);

    return productBloc$.when(
      data: (ProductBloc? productBloc) {
        final ProductListStateNotifier productListStateNotifier =
            ProductListStateNotifier(productBloc);

        ref.onDispose(() {
          productListStateNotifier.dispose();
        });

        return productListStateNotifier;
      },
      loading: () => ProductListStateNotifier(null),
      error: (Object error, StackTrace? stackTrace) =>
          throw Exception('Error while getting productBloc'),
    );
  },
);

// Customer
final FutureProvider<CustomerBloc?> customerBlocProvider =
    FutureProvider<CustomerBloc?>(
  (Ref<AsyncValue<CustomerBloc?>> ref) async {
    final UserModel? user = await ref.watch(user$Provider.future);
    if (user == null) {
      return null;
    }
    final CustomerBloc customerBloc = CustomerBlocImpl(
        user: user, customerRepository: CustomerRepositoryFirebaseImpl());
    ref.onDispose(() {
      customerBloc.dispose();
    });
    return customerBloc;
  },
);

final StateNotifierProvider<CustomerListStateNotifier,
        CustomerPaginatedListState> customerListStateNotifierProvider =
    StateNotifierProvider<CustomerListStateNotifier,
        CustomerPaginatedListState>(
  (StateNotifierProviderRef<CustomerListStateNotifier,
          CustomerPaginatedListState>
      ref) {
    final AsyncValue<CustomerBloc?> customerBloc$ =
        ref.watch(customerBlocProvider);

    return customerBloc$.when(
      data: (CustomerBloc? customerBloc) {
        final CustomerListStateNotifier customerListStateNotifier =
            CustomerListStateNotifier(customerBloc);

        ref.onDispose(() {
          customerListStateNotifier.dispose();
        });

        return customerListStateNotifier;
      },
      loading: () => CustomerListStateNotifier(null),
      error: (Object error, StackTrace? stackTrace) =>
          throw Exception('Error while getting customerBloc'),
    );
  },
);

// Order
final FutureProvider<OrderBloc?> orderBlocProvider = FutureProvider<OrderBloc?>(
  (Ref<AsyncValue<OrderBloc?>> ref) async {
    final UserModel? user = await ref.watch(user$Provider.future);
    if (user == null) {
      return null;
    }
    final OrderRepository orderRepository = OrderRepositoryFirebaseImpl();
    final OrderBlocImpl orderBloc =
        OrderBlocImpl(user: user, orderRepository: orderRepository);
    ref.onDispose(() {
      orderBloc.dispose();
    });
    return orderBloc;
  },
);

// Cart
final Provider<CartBloc> cartBlocProvider = Provider<CartBloc>(
  (Ref<CartBloc> ref) {
    final CartBloc cartBloc = CartBlocImpl();
    ref.onDispose(() {
      cartBloc.dispose();
    });
    return cartBloc;
  },
);

// Config
final FutureProvider<ConfigurationRepository> configurationRepositoryProvider =
    FutureProvider<ConfigurationRepository>(
  (Ref<AsyncValue<ConfigurationRepository>> ref) async {
    final ConfigurationRepository configurationRepository =
        await ConfigurationRepositoryImpl.getInstance();
    ref.onDispose(() {
      configurationRepository.dispose();
    });
    return configurationRepository;
  },
);

final FutureProvider<ConfigurationService> configurationServiceProvider =
    FutureProvider<ConfigurationService>(
  (Ref<AsyncValue<ConfigurationService>> ref) async {
    final ConfigurationRepository configurationRepository =
        await ref.watch(configurationRepositoryProvider.future);
    final ConfigurationService configurationService = ConfigurationServiceImpl(
        configurationRepository: configurationRepository);
    ref.onDispose(() {
      configurationService.dispose();
    });
    return configurationService;
  },
);

final Provider<Config?> configProvider = Provider<Config?>(
  (Ref<Config?> ref) {
    final AsyncValue<ConfigurationService> configurationService$ =
        ref.watch(configurationServiceProvider);

    final Config defaultConfig = Config(
      pageSize: defaultPageSize,
      minAppVersion: defaultMinAppVersion,
      latestAppVersion: defaultLatestAppVersion,
      appcastURL: defaultAppcastURL,
      countryCodeCacheTtlInSeconds: defaultCountryCodeCacheTtlInSeconds,
    );

    return configurationService$.when(
      data: (ConfigurationService configurationService) {
        final String minAppVersion =
            configurationService.getString(key: minAppVersionConfigKey);
        final String latestAppVersion =
            configurationService.getString(key: latestAppVersionConfigKey);
        final String appcastURL =
            configurationService.getString(key: appcastURLConfigKey);
        final int pageSize = int.tryParse(
                configurationService.getString(key: pageSizeConfigKey)) ??
            defaultPageSize;
        final int countryCodeCacheTtlInSeconds = int.tryParse(
                configurationService.getString(
                    key: countryCodeCacheTtlInSecondsConfigKey)) ??
            defaultCountryCodeCacheTtlInSeconds;

        ref.onDispose(() {
          configurationService.dispose();
        });

        return Config(
          pageSize: pageSize,
          minAppVersion: minAppVersion,
          latestAppVersion: latestAppVersion,
          appcastURL: appcastURL,
          countryCodeCacheTtlInSeconds: countryCodeCacheTtlInSeconds,
        );
      },
      loading: () => null,
      error: (Object error, StackTrace? stackTrace) => defaultConfig,
    );
  },
);

final Provider<LocalCacheService?> localCacheServiceProvider =
    Provider<LocalCacheService?>(
  (Ref<LocalCacheService?> ref) {
    final LocalStorageService localStorageService =
        getIt<LocalStorageService>();
    return LocalCacheService(localStorageService: localStorageService);
  },
);
