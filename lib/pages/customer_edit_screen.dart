import 'package:easyorder/exceptions/already_in_use_exception.dart';
import 'package:easyorder/exceptions/not_unique_exception.dart';
import 'package:easyorder/models/alert_type.dart';
import 'package:easyorder/models/config.dart';
import 'package:easyorder/models/customer_model.dart';
import 'package:easyorder/models/local_cache_model.dart';
import 'package:easyorder/service/local_cache_service.dart';
import 'package:easyorder/shared/constants.dart';
import 'package:easyorder/shared/location_utils.dart';
import 'package:easyorder/state/customer_list_state_notifier.dart';
import 'package:easyorder/state/providers.dart';
import 'package:easyorder/widgets/helpers/form_helper.dart';
import 'package:easyorder/widgets/helpers/logger.dart';
import 'package:easyorder/widgets/helpers/ui_helper.dart';
import 'package:easyorder/widgets/helpers/validator.dart';
import 'package:easyorder/widgets/ui_elements/adapative_progress_indicator.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';
import 'package:loading_overlay/loading_overlay.dart';
import 'package:logger/logger.dart';

class CustomerEditScreen extends ConsumerStatefulWidget {
  const CustomerEditScreen({super.key, CustomerModel? currentCustomer})
      : _currentCustomer = currentCustomer;

  static const String routeName = '/customer-edit';

  final CustomerModel? _currentCustomer;

  @override
  ConsumerState<CustomerEditScreen> createState() => _CustomerEditScreenState();
}

class _CustomerEditScreenState extends ConsumerState<CustomerEditScreen> {
  final Logger logger = getLogger();

  late CustomerListStateNotifier _customerListStateNotifier;

  bool _isLoading = false;
  bool _isPhoneNumberValid = true;
  final _FormData _formData = _FormData();

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final FocusNode _nameFocusNode = FocusNode();
  final FocusNode _addressFocusNode = FocusNode();

  final TextEditingController _nameTextController = TextEditingController();
  final TextEditingController _addressTextController = TextEditingController();
  final TextEditingController _phoneNumberTextController =
      TextEditingController();
  bool _isNameClearVisible = false;
  bool _isAddressClearVisible = false;
  bool _isPhoneNumberClearVisible = false;
  PhoneNumber? _initialPhoneNumber;

  @override
  void initState() {
    super.initState();

    _customerListStateNotifier =
        ref.read(customerListStateNotifierProvider.notifier);

    _nameTextController.addListener(_toggleNameClearVisible);
    _nameTextController.text =
        (widget._currentCustomer == null) ? '' : widget._currentCustomer!.name;

    _addressTextController.addListener(_toggleAddressClearVisible);
    _addressTextController.text = (widget._currentCustomer != null &&
            widget._currentCustomer!.address != null)
        ? widget._currentCustomer!.address!
        : '';

    _phoneNumberTextController.addListener(_togglePhoneNumberClearVisible);
    _initPhoneNumber();
  }

  void _initPhoneNumber() async {
    if (widget._currentCustomer != null &&
        widget._currentCustomer!.phoneNumber != null) {
      final PhoneNumber number = await PhoneNumber.getRegionInfoFromPhoneNumber(
          widget._currentCustomer!.phoneNumber!);
      setState(() => _initialPhoneNumber = number);
    } else {
      String? countryCode;
      final Config? config = ref.read(configProvider);
      final LocalCacheService? localCacheService =
          ref.read(localCacheServiceProvider);
      if (localCacheService != null) {
        final Object? cacheObject =
            await localCacheService.get(key: CacheKey.countryCode);
        countryCode = cacheObject == null ? null : cacheObject as String;
      }

      if (countryCode == null) {
        try {
          countryCode = await LocationUtils.getIsoCountryCode();
        } catch (e) {
          logger.e('Error $e');
        }

        if (countryCode != null && localCacheService != null) {
          final int countryCodeCacheTtlInSeconds =
              config?.countryCodeCacheTtlInSeconds ??
                  defaultCountryCodeCacheTtlInSeconds;
          final LocalCacheModel localCache = LocalCacheModel(
              value: countryCode,
              timeToLiveInSeconds: countryCodeCacheTtlInSeconds);
          await localCacheService.put(
              key: CacheKey.countryCode, localCache: localCache);
        }
      }

      if (mounted && countryCode != null) {
        setState(() => _initialPhoneNumber = PhoneNumber(isoCode: countryCode));
      }
    }
  }

  @override
  void dispose() {
    _nameTextController.dispose();
    _addressTextController.dispose();
    _phoneNumberTextController.dispose();

    _nameFocusNode.dispose();
    _addressFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final String pageTitle =
        widget._currentCustomer == null ? 'Create Customer' : 'Edit Customer';
    return _buildScreen(pageTitle);
  }

  Widget _buildScreen(String pageTitle) {
    final Widget pageContent =
        _buildPageContent(context, widget._currentCustomer);

    return LoadingOverlay(
      isLoading: _isLoading,
      progressIndicator: AdaptiveProgressIndicator(),
      child: SafeArea(
        child: Scaffold(
          appBar: AppBar(
            title: Text(pageTitle),
            elevation:
                Theme.of(context).platform == TargetPlatform.iOS ? 0.0 : 4.0,
            actions: <Widget>[
              _buildSubmitButton(),
            ],
          ),
          body: pageContent,
        ),
      ),
    );
  }

  Widget _buildNameTextField(CustomerModel? customer) {
    return TextFormField(
      maxLength: Constants.maxCustomerNameLength,
      controller: _nameTextController,
      focusNode: _nameFocusNode,
      textInputAction: TextInputAction.next,
      onFieldSubmitted: (String term) {
        FormHelper.changeFieldFocus(context, _nameFocusNode, _addressFocusNode);
      },
      textCapitalization: TextCapitalization.sentences,
      decoration: InputDecoration(
          prefixIcon: const Padding(
            padding: EdgeInsets.only(left: 5.0),
            child: Icon(
              Icons.title,
            ),
          ),
          suffixIcon: !_isNameClearVisible
              ? const SizedBox()
              : IconButton(
                  onPressed: () {
                    _nameTextController.clear();
                  },
                  icon: const Icon(
                    Icons.clear,
                  )),
          labelText: 'Customer Name *',
          counterStyle: const TextStyle(
            height: double.minPositive,
          ),
          contentPadding: const EdgeInsets.fromLTRB(10.0, 10.0, 10.0, 10.0),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(20.0)),
          filled: true,
          fillColor: Colors.white),
      validator: (String? value) {
        return Validator.validateCustomerName(value);
      },
      onSaved: (String? value) {
        _formData.name = value;
      },
    );
  }

  Widget _buildAddressTextField(CustomerModel? customer) {
    return TextFormField(
      maxLength: Constants.maxCustomerAddressLength,
      maxLines: 5,
      controller: _addressTextController,
      focusNode: _addressFocusNode,
      textInputAction: TextInputAction.newline,
      textCapitalization: TextCapitalization.sentences,
      decoration: InputDecoration(
          prefixIcon: const Padding(
            padding: EdgeInsets.only(left: 5.0),
            child: Icon(
              Icons.mail_sharp,
            ),
          ),
          suffixIcon: !_isAddressClearVisible
              ? const SizedBox()
              : IconButton(
                  onPressed: () {
                    _addressTextController.clear();
                  },
                  icon: const Icon(
                    Icons.clear,
                  )),
//          hintText: 'Customer Address',
          labelText: 'Customer Address',
          counterStyle: const TextStyle(
            height: double.minPositive,
          ),
          contentPadding: const EdgeInsets.fromLTRB(10.0, 10.0, 10.0, 10.0),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(20.0)),
          filled: true,
          fillColor: Colors.white),
      validator: (String? value) {
        return Validator.validateCustomerAddress(value);
      },
      onSaved: (String? value) {
        _formData.address = value;
      },
    );
  }

  Widget _buildPhoneNumberField() {
    return Theme(
      data: Theme.of(context).copyWith(
        canvasColor: Theme.of(context).secondaryHeaderColor,
      ),
      child: InternationalPhoneNumberInput(
        inputDecoration: InputDecoration(
          prefixIcon: const Padding(
            padding: EdgeInsets.only(left: 5.0),
            child: Icon(
              Icons.phone,
            ),
          ),
          suffixIcon: !_isPhoneNumberClearVisible
              ? const SizedBox()
              : Padding(
                  padding: const EdgeInsets.only(left: 5.0),
                  child: IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () => _phoneNumberTextController.clear(),
                  ),
                ),
          labelText: 'Phone number',
          counterStyle: const TextStyle(
            height: double.minPositive,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 10.0),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(20.0)),
          filled: true,
          // fillColor: Colors.white,
        ),
        spaceBetweenSelectorAndTextField: 0,
        selectorConfig: const SelectorConfig(
          selectorType: PhoneInputSelectorType.BOTTOM_SHEET,
          setSelectorButtonAsPrefixIcon: true,
          leadingPadding: 20,
        ),
        ignoreBlank: false,
        autoValidateMode: AutovalidateMode.onUserInteraction,
        selectorTextStyle: const TextStyle(color: Colors.black),
        initialValue: _initialPhoneNumber,
        textFieldController: _phoneNumberTextController,
        formatInput: false,
        keyboardType: const TextInputType.numberWithOptions(
            signed: false, decimal: false),
        inputBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20.0),
        ),
        onInputChanged: (PhoneNumber number) {
          // print('number: ${number.phoneNumber}');
        },
        onSaved: (PhoneNumber number) {
          final String parsedNumber = number.parseNumber();
          if (parsedNumber.isNotEmpty) {
            _formData.phoneNumber = number;
          }
        },
        onInputValidated: (bool isValid) {
          _isPhoneNumberValid = isValid;
        },
        validator: (String? value) {
          return Validator.validateCustomerPhoneNumber(
              value, _isPhoneNumberValid);
        },
        errorMessage: 'Invalid phone number',
      ),
    );
  }

  Widget _buildActiveField() {
    if (widget._currentCustomer == null) {
      return const SizedBox();
    }

    final bool isActive = widget._currentCustomer!.active;
    const String message =
        'Inactive customers won\'t appear in the selection list during the order creation.';

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: isActive ? Colors.green : Colors.red,
      ),
      child: Row(
        children: <Widget>[
          IconButton(
            icon: const Icon(Icons.info_outline_rounded),
            color: Colors.white,
            tooltip: message,
            onPressed: () {
              UiHelper.showAlertDialogNoTitle(context, AlertType.info, message);
            },
          ),
          Text(
            isActive ? 'This customer is active' : 'This customer is inactive',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return TextButton.icon(
      onPressed: _isLoading ? null : () => _submitForm(),
      icon: Icon(
        Icons.save,
        color: Theme.of(context).primaryColor,
        size: 30,
      ),
      label: Text(
        'SAVE',
        style: TextStyle(
          color: Theme.of(context).primaryColor,
          fontSize: 20,
        ),
      ),
    );
  }

  Widget _buildPageContent(BuildContext context, CustomerModel? customer) {
    final double deviceWidth = MediaQuery.of(context).size.width;
    final double targetWidth = deviceWidth > 550.0 ? 500.0 : deviceWidth * 0.95;
    final double targetPadding = deviceWidth - targetWidth;
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).requestFocus(FocusNode());
      },
      child: Container(
        margin: const EdgeInsets.all(10.0),
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: targetPadding / 2),
          child: Form(
            key: _formKey,
            child: Column(
              children: <Widget>[
                const SizedBox(
                  height: 5.0,
                ),
                _buildNameTextField(customer),
                const SizedBox(
                  height: 5.0,
                ),
                _buildAddressTextField(customer),
                const SizedBox(
                  height: 5.0,
                ),
                _buildPhoneNumberField(),
                const SizedBox(
                  height: 5.0,
                ),
                _buildActiveField(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _submitForm() {
    if (_formKey.currentState == null) {
      logger.e('Cannot submit form : formKey currentState is null');
      return;
    }

    if (!_formKey.currentState!.validate()) {
      logger.d('Form is invalid');
      return;
    }
    _formKey.currentState!.save();
    _formData.active = widget._currentCustomer?.active ?? true;

    if (widget._currentCustomer == null) {
      _createCustomer();
    } else {
      _updateCustomer();
    }
  }

  void _createCustomer() {
    setState(() => _isLoading = true);

    final CustomerModel customerToCreate = _formData.toCustomer();

    _customerListStateNotifier
        .add(
      customer: customerToCreate,
    )
        .then((CustomerModel? customerCreated) {
      setState(() => _isLoading = false);
      if (mounted && customerCreated != null) {
        Navigator.pop(context, customerCreated);
      } else {
        _showErrorDialog();
      }
    }).catchError(
      (Object err, StackTrace trace) {
        logger.e('Error: $err');
        setState(() => _isLoading = false);

        String title = genericErrorTitle;
        String content = genericErrorMessage;

        final bool isNameNotUnique = err is NotUniqueException;
        if (isNameNotUnique) {
          title = 'Cannot create this customer.';
          content = err.message;
        }

        if (mounted) {
          UiHelper.showAlertDialog(context, AlertType.error, title, content);
        }
      },
    );
  }

  void _updateCustomer() {
    if (widget._currentCustomer == null ||
        widget._currentCustomer?.id == null) {
      logger.e('Cannot update customer : current customer cannot be null');
      return;
    }

    setState(() => _isLoading = true);

    final CustomerModel customerToUpdate =
        CustomerModel.clone(widget._currentCustomer!);
    final CustomerModel customerFromFormData = _formData.toCustomer();
    customerToUpdate.name = customerFromFormData.name;
    customerToUpdate.address = customerFromFormData.address;
    customerToUpdate.phoneNumber = customerFromFormData.phoneNumber;
    customerToUpdate.active = customerFromFormData.active;

    _customerListStateNotifier
        .edit(
      customerId: widget._currentCustomer!.id!,
      customer: customerToUpdate,
    )
        .then((CustomerModel? customerUpdated) {
      setState(() => _isLoading = false);
      if (mounted && customerUpdated != null) {
        Navigator.pop(context, customerUpdated);
      } else {
        _showErrorDialog();
      }
    }).catchError(
      (Object err, StackTrace trace) {
        logger.e('Error: $err');
        setState(() => _isLoading = false);

        String title = genericErrorTitle;
        String content = genericErrorMessage;

        final bool isAlreadyInUse = err is AlreadyInUseException;
        final bool isNameNotUnique = err is NotUniqueException;
        if (isAlreadyInUse) {
          title = 'Cannot update this customer.';
          content = err.message;
        } else if (isNameNotUnique) {
          title = 'Cannot update this customer.';
          content = err.message;
        }

        if (mounted) {
          UiHelper.showAlertDialog(context, AlertType.error, title, content);
        }
      },
    );
  }

  // void _showConfirmationDialog() {
  //   if (widget._currentCustomer == null) {
  //     return;
  //   }
  //
  //   AwesomeDialog(
  //     context: context,
  //     dialogType: DialogType.warning,
  //     animType: AnimType.bottomSlide,
  //     body: const Column(
  //       mainAxisAlignment: MainAxisAlignment.center,
  //       crossAxisAlignment: CrossAxisAlignment.center,
  //       children: <Widget>[
  //         Padding(
  //           padding: EdgeInsets.symmetric(horizontal: 50),
  //           child: Text(
  //             'Warning',
  //             style: TextStyle(
  //               fontWeight: FontWeight.bold,
  //               fontSize: 20,
  //             ),
  //           ),
  //         ),
  //         SizedBox(
  //           height: 10,
  //         ),
  //         Text('Do you want to delete this customer ?'),
  //       ],
  //     ),
  //     btnCancelColor: Colors.red,
  //     btnOkColor: Colors.green,
  //     btnCancelOnPress: () {
  //       logger.d('Cancel delete customer ${widget._currentCustomer!.name}');
  //     },
  //     btnOkOnPress: () {
  //       logger.d('Confirm delete customer ${widget._currentCustomer!.name}');
  //       _deleteCustomer();
  //     },
  //   ).show();
  // }

  // void _deleteCustomer() {
  //   if (widget._currentCustomer == null) {
  //     logger.e('Current customer is null');
  //     return;
  //   }
  //
  //   setState(() => _isLoading = true);
  //
  //   _customerListStateNotifier
  //       .remove(customerToRemove: widget._currentCustomer!)
  //       .then(
  //     (bool success) {
  //       setState(() => _isLoading = false);
  //       if (mounted && success) {
  //         Navigator.pop(context);
  //       } else {
  //         _showErrorDialog();
  //       }
  //     },
  //   ).catchError(
  //     (Object err, StackTrace trace) {
  //       logger.e('Error: $err');
  //       setState(() => _isLoading = false);
  //
  //       String title = genericErrorTitle;
  //       String content = genericErrorMessage;
  //
  //       final bool isAlreadyInUse = err is AlreadyInUseException;
  //       if (isAlreadyInUse) {
  //         title = 'Cannot delete this customer.';
  //         content = err.message;
  //       }
  //
  //       if (mounted) {
  //         UiHelper.showAlertDialog(context, AlertType.error, title, content);
  //       }
  //     },
  //   );
  // }

  // void _toggleActive(bool active) {
  //   if (widget._currentCustomer == null ||
  //       widget._currentCustomer!.id == null) {
  //     logger.e('Current customer is null');
  //     return;
  //   }
  //
  //   setState(() => _isLoading = true);
  //
  //   _customerListStateNotifier
  //       .toggleActive(customerId: widget._currentCustomer!.id!, active: active)
  //       .then(
  //     (CustomerModel? customerUpdated) {
  //       setState(() => _isLoading = false);
  //       if (mounted && customerUpdated != null) {
  //         Navigator.pop(context, customerUpdated);
  //       } else {
  //         _showErrorDialog();
  //       }
  //     },
  //   ).catchError((Object err, StackTrace trace) {
  //     logger.e('Error: $err');
  //     setState(() => _isLoading = false);
  //     _showErrorDialog();
  //   });
  // }

  void _showErrorDialog() {
    UiHelper.showAlertDialog(
        context, AlertType.error, genericErrorTitle, genericErrorMessage);
  }

  void _toggleNameClearVisible() {
    setState(() {
      _isNameClearVisible = _nameTextController.text.isNotEmpty;
    });
  }

  void _toggleAddressClearVisible() {
    setState(() {
      _isAddressClearVisible = _addressTextController.text.isNotEmpty;
    });
  }

  void _togglePhoneNumberClearVisible() {
    setState(() {
      _isPhoneNumberClearVisible = _phoneNumberTextController.text.isNotEmpty;
    });
  }
}

class _FormData {
  String? name;
  String? address;
  PhoneNumber? phoneNumber;
  bool? active;

  CustomerModel toCustomer() {
    return CustomerModel(
      name: name == null ? '' : name!,
      address: address == null || address!.isEmpty ? null : address,
      phoneNumber: phoneNumber == null || phoneNumber!.phoneNumber == null
          ? null
          : phoneNumber!.phoneNumber,
      active: active ?? true,
    );
  }
}
