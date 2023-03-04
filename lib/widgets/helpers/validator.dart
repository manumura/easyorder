import 'package:easyorder/models/category_model.dart';
import 'package:easyorder/shared/constants.dart';
import 'package:easyorder/widgets/form_inputs/image_input_adapter.dart';

class Validator {
  Validator._();

  static String? validateEmail(String? value) {
    return (value == null ||
            value.isEmpty ||
            !RegExp(r"[a-z0-9!#$%&'*+/=?^_`{|}~-]+(?:\.[a-z0-9!#$%&'*+/=?^_`{|}~-]+)*@(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?")
                .hasMatch(value))
        ? 'Please enter a valid email'
        : null;
  }

  static String? validatePassword(String? value) {
    return (value == null ||
            value.isEmpty ||
            value.length < Constants.minPasswordLength)
        ? 'Password is invalid'
        : null;
  }

  // static String? validateConfirmPassword(String? value) {
  //   return null;
  // }

  static String? validateName(String? value) {
    return (value == null ||
            value.isEmpty ||
            value.length < Constants.minNameLength ||
            value.length > Constants.maxNameLength)
        ? 'Name is required and should be ${Constants.minNameLength}+ characters long'
        : null;
  }

  static String? validateCategory(CategoryModel? value) {
    return (value == null) ? 'Category is required' : null;
  }

  static String? validateDescription(String? value) {
    return (value != null && value.length > Constants.maxDescriptionLength)
        ? 'Description should be max ${Constants.maxDescriptionLength} characters long'
        : null;
  }

  static String? validatePrice(String? value) {
    return (value == null ||
            value.isEmpty ||
            !RegExp(r'^(?:[1-9]\d*|0)?(?:[.,]\d+)?$').hasMatch(value))
        ? 'Price is required and should be a number'
        : null;
  }

  static String? validateImage(ImageInputAdapter? value) {
    if (value == null || value.file == null) {
//          return 'Please choose an image';
    }
    return null;
  }

  static String? validateCustomer(String? value) {
    return (value == null || value.isEmpty) ? 'Customer is required' : null;
  }

  static String? validateOrderCreationDate(DateTime? value) {
    return value == null
        // (value == null || value.compareTo(DateTime.now()) > 0)
        ? 'Date is empty or invalid' // (should be in the past)
        : null;
  }

  static String? validateOrderDescription(String? value) {
    return (value != null && value.length > Constants.maxOrderDescriptionLength)
        ? 'Description should be max ${Constants.maxOrderDescriptionLength} characters long'
        : null;
  }

  static String? validateOrderDueDate(DateTime? value) {
    return (value != null && value.compareTo(DateTime.now()) < 0)
        ? 'Due Date is empty or invalid' // (should be in the future)
        : null;
  }

  static String? validateCustomerName(String? value) {
    return (value == null ||
            value.isEmpty ||
            value.length < Constants.minCustomerNameLength ||
            value.length > Constants.maxCustomerNameLength)
        ? 'Name is required and should be ${Constants.minCustomerNameLength}+ characters long'
        : null;
  }

  static String? validateCustomerAddress(String? value) {
    return (value != null && value.length > Constants.maxCustomerAddressLength)
        ? 'Address should be max ${Constants.maxCustomerAddressLength} '
            'characters long'
        : null;
  }

  static String? validateCustomerPhoneNumber(String? value, bool isValid) {
    return value != null && !isValid ? 'Invalid phone number' : null;
  }
}
