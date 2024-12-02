import 'dart:io';

import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:easyorder/bloc/category_bloc.dart';
import 'package:easyorder/exceptions/already_in_use_exception.dart';
import 'package:easyorder/exceptions/not_unique_exception.dart';
import 'package:easyorder/models/alert_type.dart';
import 'package:easyorder/models/category_model.dart';
import 'package:easyorder/models/product_model.dart';
import 'package:easyorder/pages/category_edit_screen.dart';
import 'package:easyorder/shared/constants.dart';
import 'package:easyorder/state/product_list_state_notifier.dart';
import 'package:easyorder/state/providers.dart';
import 'package:easyorder/widgets/form_inputs/drop_down_form_field.dart';
import 'package:easyorder/widgets/form_inputs/image_form_field.dart';
import 'package:easyorder/widgets/form_inputs/image_input_adapter.dart';
import 'package:easyorder/widgets/helpers/form_helper.dart';
import 'package:easyorder/widgets/helpers/logger.dart';
import 'package:easyorder/widgets/helpers/ui_helper.dart';
import 'package:easyorder/widgets/helpers/validator.dart';
import 'package:easyorder/widgets/ui_elements/adapative_progress_indicator.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:loading_overlay/loading_overlay.dart';
import 'package:logger/logger.dart';

class ProductEditScreen extends ConsumerStatefulWidget {
  const ProductEditScreen({super.key, ProductModel? currentProduct})
      : _currentProduct = currentProduct;

  static const String routeName = '/product-edit';

  final ProductModel? _currentProduct;

  @override
  ConsumerState<ProductEditScreen> createState() => _ProductEditScreenState();
}

class _ProductEditScreenState extends ConsumerState<ProductEditScreen> {
  final Logger logger = getLogger();

  late ProductListStateNotifier _productListStateNotifier;

  bool _isLoading = false;
  final _FormData _formData = _FormData();

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final FocusNode _nameFocusNode = FocusNode();
  final FocusNode _categoryFocusNode = FocusNode();
  final FocusNode _descriptionFocusNode = FocusNode();
  final FocusNode _priceFocusNode = FocusNode();

  final TextEditingController _nameTextController = TextEditingController();
  final TextEditingController _categoryTextController = TextEditingController();
  final TextEditingController _descriptionTextController =
      TextEditingController();
  final TextEditingController _priceTextController = TextEditingController();
  bool _isNameClearVisible = false;
  bool _isDescriptionClearVisible = false;
  bool _isPriceClearVisible = false;

  @override
  void initState() {
    super.initState();

    _productListStateNotifier =
        ref.read(productListStateNotifierProvider.notifier);

    _nameTextController.addListener(_toggleNameClearVisible);
    _nameTextController.text =
        (widget._currentProduct == null) ? '' : widget._currentProduct!.name;

    _descriptionTextController.addListener(_toggleDescriptionClearVisible);
    _descriptionTextController.text = (widget._currentProduct == null)
        ? ''
        : widget._currentProduct!.description!;

    _priceTextController.addListener(_togglePriceClearVisible);
    _priceTextController.text = (widget._currentProduct == null)
        ? ''
        : widget._currentProduct!.price.toString();
  }

  @override
  void dispose() {
    _nameTextController.dispose();
    _categoryTextController.dispose();
    _descriptionTextController.dispose();
    _priceTextController.dispose();

    _nameFocusNode.dispose();
    _categoryFocusNode.dispose();
    _descriptionFocusNode.dispose();
    _priceFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final String pageTitle =
        widget._currentProduct == null ? 'Create Product' : 'Edit Product';
    final AsyncValue<CategoryBloc?> categoryBlocProvider$ =
        ref.watch(categoryBlocProvider);
    return categoryBlocProvider$.when(
      data: (CategoryBloc? categoryBloc) {
        if (categoryBloc == null) {
          return _buildErrorScreen(pageTitle, 'No active category found');
        }

        return _buildScreen(context, pageTitle, categoryBloc.activeCategories$);
      },
      loading: () {
        return _buildLoadingScreen(pageTitle);
      },
      error: (Object err, StackTrace? stack) =>
          _buildErrorScreen(pageTitle, err),
    );
  }

  Widget _buildErrorScreen(String pageTitle, Object? err) {
    return Scaffold(
      appBar: AppBar(
        title: Text(pageTitle),
      ),
      body: Center(
        child: Text('Error: $err'),
      ),
    );
  }

  Widget _buildLoadingScreen(String pageTitle) {
    return Scaffold(
      appBar: AppBar(
        title: Text(pageTitle),
      ),
      body: Center(child: AdaptiveProgressIndicator()),
    );
  }

  Widget _buildScreen(
    BuildContext context,
    String pageTitle,
    Stream<List<CategoryModel>> categories$,
  ) {
    return StreamBuilder<List<CategoryModel>>(
      stream: categories$,
      builder:
          (BuildContext context, AsyncSnapshot<List<CategoryModel>> snapshot) {
        if (snapshot.hasError) {
          return _buildErrorScreen(pageTitle, snapshot.error);
        }

        if (!snapshot.hasData) {
          return _buildLoadingScreen(pageTitle);
        }

        final List<CategoryModel>? categories = snapshot.data;
        return _buildScaffold(context, pageTitle, categories);
      },
    );
  }

  Widget _buildScaffold(
    BuildContext context,
    String pageTitle,
    List<CategoryModel>? categories,
  ) {
    final bool categoriesExist = categories != null && categories.isNotEmpty;
    final bool canEdit = widget._currentProduct != null || categoriesExist;
    final Widget pageContent =
        _buildPageContent(context, widget._currentProduct, categories);

    return LoadingOverlay(
      isLoading: _isLoading,
      progressIndicator: AdaptiveProgressIndicator(),
      child: Scaffold(
        appBar: AppBar(
          title: Text(pageTitle),
          elevation:
              Theme.of(context).platform == TargetPlatform.iOS ? 0.0 : 4.0,
          actions: <Widget>[
            if (widget._currentProduct != null)
              _buildToggleActiveButton(widget._currentProduct!),
            if (widget._currentProduct != null) _buildDeleteButton(),
            if (categoriesExist) _buildSubmitButton() else const SizedBox(),
          ],
        ),
        body: canEdit
            ? pageContent
            : const Center(child: Text('No active category found !')),
        floatingActionButton:
            canEdit ? const SizedBox() : _buildAddCategoryButton(),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      ),
    );
  }

  Widget _buildNameTextField() {
    return TextFormField(
      maxLength: Constants.maxNameLength,
      controller: _nameTextController,
      focusNode: _nameFocusNode,
      textInputAction: TextInputAction.next,
      onFieldSubmitted: (String term) {
        FormHelper.changeFieldFocus(
            context, _nameFocusNode, _categoryFocusNode);
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
          labelText: 'Product Name *',
          counterStyle: const TextStyle(
            height: double.minPositive,
          ),
          contentPadding: const EdgeInsets.fromLTRB(10.0, 10.0, 10.0, 10.0),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(20.0)),
          filled: true,
          fillColor: Colors.white),
      validator: (String? value) {
        return Validator.validateName(value);
      },
      onSaved: (String? value) {
        _formData.name = value;
      },
    );
  }

  Widget _buildCategoriesDropDown(
      ProductModel? product, List<CategoryModel>? categories) {
    final Widget dropDown = (categories == null || categories.isEmpty)
        ? const Center(
            child: Text('* No active category found'),
          )
        : DropdownFormField<CategoryModel>(
            initialValue: product?.category,
            decoration: InputDecoration(
              prefixIcon: const Padding(
                padding: EdgeInsets.only(left: 5.0),
                child: Icon(
                  Icons.category,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 10.0),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(20.0)),
              filled: true,
              fillColor: Colors.white,
            ),
            labelText: 'Category *',
            items: categories.map((CategoryModel category) {
              return DropdownMenuItem<CategoryModel>(
                value: category,
                child: Text(category.name),
              );
            }).toList(),
            validator: (CategoryModel? value) {
              return Validator.validateCategory(value);
            },
            onSaved: (CategoryModel? value) {
              _formData.category = value;
            },
          );

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: <Widget>[
        Expanded(
          flex: 7,
          child: dropDown,
        ),
        Expanded(
          child: IconButton(
            iconSize: 36,
            icon: const Icon(Icons.add_circle),
            // color: Theme.of(context).colorScheme.secondary,
            onPressed: _openEditCategoryScreen,
          ),
        ),
      ],
    );
  }

  Widget _buildDescriptionTextField() {
    return TextFormField(
      maxLength: Constants.maxDescriptionLength,
      maxLines: 5,
      controller: _descriptionTextController,
      focusNode: _descriptionFocusNode,
      textInputAction: TextInputAction.newline,
      onFieldSubmitted: (String term) {
        FormHelper.changeFieldFocus(
            context, _descriptionFocusNode, _priceFocusNode);
      },
      textCapitalization: TextCapitalization.sentences,
      decoration: InputDecoration(
          prefixIcon: const Padding(
            padding: EdgeInsets.only(left: 5.0),
            child: Icon(
              Icons.description,
            ),
          ),
          suffixIcon: !_isDescriptionClearVisible
              ? const SizedBox()
              : IconButton(
                  onPressed: () {
                    _descriptionTextController.clear();
                  },
                  icon: const Icon(
                    Icons.clear,
                  )),
          labelText: 'Product Description',
          counterStyle: const TextStyle(
            height: double.minPositive,
          ),
          contentPadding: const EdgeInsets.fromLTRB(10.0, 10.0, 10.0, 10.0),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(20.0)),
          filled: true,
          fillColor: Colors.white),
      validator: (String? value) {
        return Validator.validateDescription(value);
      },
      onSaved: (String? value) {
        _formData.description = value;
      },
    );
  }

  Widget _buildPriceTextField() {
    return TextFormField(
      maxLength: 10,
      controller: _priceTextController,
      focusNode: _priceFocusNode,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
          prefixIcon: const Padding(
            padding: EdgeInsets.only(left: 5.0),
            child: Icon(
              Icons.attach_money,
            ),
          ),
          suffixIcon: !_isPriceClearVisible
              ? const SizedBox()
              : IconButton(
                  onPressed: () {
                    _priceTextController.clear();
                  },
                  icon: const Icon(
                    Icons.clear,
                  )),
          labelText: 'Product Price *',
          counterStyle: const TextStyle(
            height: double.minPositive,
          ),
          contentPadding: const EdgeInsets.fromLTRB(10.0, 10.0, 10.0, 10.0),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(20.0)),
          filled: true,
          fillColor: Colors.white),
      validator: (String? value) {
        return Validator.validatePrice(value);
      },
      onSaved: (String? value) {
        _formData.price = value == null
            ? 0
            : double.parse(value.replaceFirst(RegExp(r','), '.'));
      },
    );
  }

  Widget _buildImageField(ProductModel? product) {
    return Column(
      children: <Widget>[
        ImageFormField(
          initialValue: ImageInputAdapter(url: product?.imageUrl),
          validator: (ImageInputAdapter? value) {
            return Validator.validateImage(value);
          },
          onSaved: (ImageInputAdapter? value) {
            _formData.image = value?.file;
          },
        ),
      ],
    );
  }

  Widget _buildActiveField() {
    if (widget._currentProduct == null) {
      return const SizedBox();
    }

    final bool isActive = widget._currentProduct!.active;
    const String message =
        'Inactive products won\'t appear in the items list during the order creation.';

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
            isActive ? 'This product is active' : 'This product is inactive',
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
    return IconButton(
      onPressed: _isLoading ? null : () => _submitForm(),
      icon: const Icon(
        Icons.save,
        // color: Colors.white,
        size: 30,
      ),
    );
  }

  Widget _buildDeleteButton() {
    return IconButton(
      onPressed: _isLoading ? null : () => _showConfirmationDialog(),
      icon: const Icon(
        Icons.delete_forever,
        // color: Colors.white,
        size: 30,
      ),
    );
  }

  Widget _buildToggleActiveButton(ProductModel product) {
    return IconButton(
      icon: product.active
          ? const Icon(
              Icons.clear,
              size: 30,
              color: Colors.red,
              semanticLabel: 'Inactivate',
            )
          : const Icon(
              Icons.check,
              size: 30,
              color: Colors.green,
              semanticLabel: 'Activate',
            ),
      tooltip: 'Toggle customer active',
      onPressed: () => _toggleActive(!product.active),
    );
  }

  Widget _buildPageContent(BuildContext context, ProductModel? product,
      List<CategoryModel>? categories) {
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
                _buildNameTextField(),
                const SizedBox(
                  height: 5.0,
                ),
                _buildCategoriesDropDown(product, categories),
                const SizedBox(
                  height: 5.0,
                ),
                _buildDescriptionTextField(),
                const SizedBox(
                  height: 5.0,
                ),
                _buildPriceTextField(),
                const SizedBox(
                  height: 5.0,
                ),
                _buildActiveField(),
                const SizedBox(
                  height: 5.0,
                ),
                _buildImageField(product),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAddCategoryButton() {
    return FloatingActionButton.extended(
      elevation: 4.0,
      icon: const Icon(Icons.add),
      label: const Text('ADD CATEGORY'),
      onPressed: _openEditCategoryScreen,
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

    if (widget._currentProduct == null) {
      _createProduct();
    } else {
      _updateProduct();
    }
  }

  void _createProduct() {
    setState(() => _isLoading = true);

    final ProductModel productToCreate = ProductModel(
      name: _formData.name!,
      category: _formData.category,
      description: _formData.description,
      price: _formData.price!,
      active: true,
    );

    _productListStateNotifier
        .add(
      product: productToCreate,
      image: _formData.image,
    )
        .then((ProductModel? productCreated) {
      setState(() => _isLoading = false);
      if (mounted && productCreated != null) {
        Navigator.pop(context, productCreated);
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
          title = 'Cannot create this product.';
          content = err.message;
        }

        if (mounted) {
          UiHelper.showAlertDialog(context, AlertType.error, title, content);
        }
      },
    );
  }

  void _updateProduct() {
    if (widget._currentProduct == null || widget._currentProduct?.id == null) {
      logger.e('Cannot update product : current product cannot be null');
      return;
    }

    setState(() => _isLoading = true);

    final ProductModel productToUpdate =
        ProductModel.clone(widget._currentProduct!);
    productToUpdate.name = _formData.name!;
    productToUpdate.category = _formData.category;
    productToUpdate.description = _formData.description;
    productToUpdate.price = _formData.price!;

    _productListStateNotifier
        .edit(
      productId: widget._currentProduct!.id!,
      product: productToUpdate,
      image: _formData.image,
    )
        .then((ProductModel? productUpdated) {
      setState(() => _isLoading = false);
      if (mounted && productUpdated != null) {
        Navigator.pop(context, productUpdated);
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
          title = 'Cannot update this product.';
          content = err.message;
        } else if (isNameNotUnique) {
          title = 'Cannot update this product.';
          content = err.message;
        }

        if (mounted) {
          UiHelper.showAlertDialog(context, AlertType.error, title, content);
        }
      },
    );
  }

  void _showConfirmationDialog() {
    if (widget._currentProduct == null) {
      return;
    }

    AwesomeDialog(
      context: context,
      dialogType: DialogType.warning,
      animType: AnimType.bottomSlide,
      body: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 50),
            child: Text(
              'Warning',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ),
          SizedBox(
            height: 10,
          ),
          Text('Do you want to delete this product ?'),
          Text('It will be removed from current orders.'),
        ],
      ),
      btnCancelColor: Colors.red,
      btnOkColor: Colors.green,
      btnCancelOnPress: () {
        logger.d('Cancel delete product ${widget._currentProduct!.name}');
      },
      btnOkOnPress: () {
        logger.d('Confirm delete product ${widget._currentProduct!.name}');
        _deleteProduct();
      },
    ).show();
  }

  void _deleteProduct() {
    if (widget._currentProduct == null) {
      return;
    }

    setState(() => _isLoading = true);

    _productListStateNotifier
        .remove(productToRemove: widget._currentProduct!)
        .then(
      (bool success) {
        setState(() => _isLoading = false);
        if (mounted && success) {
          Navigator.pop(context);
        } else {
          _showErrorDialog();
        }
      },
    ).catchError(
      (Object err, StackTrace trace) {
        logger.e('Error: $err');
        setState(() => _isLoading = false);

        String title = genericErrorTitle;
        String content = genericErrorMessage;

        final bool isAlreadyInUse = err is AlreadyInUseException;
        if (isAlreadyInUse) {
          title = 'Cannot delete this product.';
          content = err.message;
        }

        if (mounted) {
          UiHelper.showAlertDialog(context, AlertType.error, title, content);
        }
      },
    );
  }

  void _toggleActive(bool active) {
    if (widget._currentProduct == null ||
        widget._currentProduct!.id == null ||
        widget._currentProduct!.uuid == null) {
      logger.e('Current product is null');
      return;
    }

    setState(() => _isLoading = true);

    _productListStateNotifier
        .toggleActive(
      productId: widget._currentProduct!.id!,
      productUuid: widget._currentProduct!.uuid!,
      active: active,
    )
        .then(
      (ProductModel? productUpdated) {
        setState(() => _isLoading = false);
        if (mounted && productUpdated != null) {
          Navigator.pop(context, productUpdated);
        } else {
          _showErrorDialog();
        }
      },
    ).catchError((Object err, StackTrace trace) {
      logger.e('Error: $err');
      setState(() => _isLoading = false);
      _showErrorDialog();
    });
  }

  void _openEditCategoryScreen() {
    Navigator.of(context).push(MaterialPageRoute<void>(
        settings: const RouteSettings(name: CategoryEditScreen.routeName),
        builder: (BuildContext context) => const CategoryEditScreen()));
  }

  void _showErrorDialog() {
    UiHelper.showAlertDialog(
        context, AlertType.error, genericErrorTitle, genericErrorMessage);
  }

  void _toggleNameClearVisible() {
    setState(() {
      _isNameClearVisible = _nameTextController.text.isNotEmpty;
    });
  }

  void _toggleDescriptionClearVisible() {
    setState(() {
      _isDescriptionClearVisible = _descriptionTextController.text.isNotEmpty;
    });
  }

  void _togglePriceClearVisible() {
    setState(() {
      _isPriceClearVisible = _priceTextController.text.isNotEmpty;
    });
  }
}

class _FormData {
  String? name;
  CategoryModel? category;
  String? description;
  double? price;
  File? image;
}
