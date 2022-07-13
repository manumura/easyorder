import 'dart:io';

import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/material.dart';
import 'package:easyorder/exceptions/already_in_use_exception.dart';
import 'package:easyorder/exceptions/not_unique_exception.dart';
import 'package:easyorder/models/alert_type.dart';
import 'package:easyorder/models/category_model.dart';
import 'package:easyorder/shared/constants.dart';
import 'package:easyorder/state/category_list_state_notifier.dart';
import 'package:easyorder/state/providers.dart';
import 'package:easyorder/widgets/helpers/form_helper.dart';
import 'package:easyorder/widgets/helpers/logger.dart';
import 'package:easyorder/widgets/helpers/ui_helper.dart';
import 'package:easyorder/widgets/helpers/validator.dart';
import 'package:easyorder/widgets/ui_elements/adapative_progress_indicator.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:loading_overlay/loading_overlay.dart';
import 'package:logger/logger.dart';

class CategoryEditScreen extends ConsumerStatefulWidget {
  const CategoryEditScreen([this._currentCategory]);

  static const String routeName = '/category-edit';

  final CategoryModel? _currentCategory;

  @override
  ConsumerState<CategoryEditScreen> createState() => _CategoryEditScreenState();
}

class _CategoryEditScreenState extends ConsumerState<CategoryEditScreen> {
  final Logger logger = getLogger();

  late CategoryListStateNotifier _categoryListStateNotifier;

  bool _isLoading = false;
  final _FormData _formData = _FormData();

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final FocusNode _nameFocusNode = FocusNode();
  final FocusNode _descriptionFocusNode = FocusNode();

  final TextEditingController _nameTextController = TextEditingController();
  final TextEditingController _descriptionTextController =
      TextEditingController();
  bool _isNameClearVisible = false;
  bool _isDescriptionClearVisible = false;

  @override
  void initState() {
    super.initState();

    _categoryListStateNotifier =
        ref.read(categoryListStateNotifierProvider.notifier);

    _nameTextController.addListener(_toggleNameClearVisible);
    _nameTextController.text =
        (widget._currentCategory == null) ? '' : widget._currentCategory!.name;

    _descriptionTextController.addListener(_toggleDescriptionClearVisible);
    _descriptionTextController.text = (widget._currentCategory == null)
        ? ''
        : widget._currentCategory!.description!;
  }

  @override
  void dispose() {
    _nameTextController.dispose();
    _descriptionTextController.dispose();

    _nameFocusNode.dispose();
    _descriptionFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final String pageTitle =
        widget._currentCategory == null ? 'Create Category' : 'Edit Category';
    return _buildScreen(pageTitle);
  }

  Widget _buildScreen(String pageTitle) {
    final Widget pageContent =
        _buildPageContent(context, widget._currentCategory);

    return LoadingOverlay(
      isLoading: _isLoading,
      progressIndicator: AdaptiveProgressIndicator(),
      child: Scaffold(
        appBar: AppBar(
          title: Text(pageTitle),
          elevation:
              Theme.of(context).platform == TargetPlatform.iOS ? 0.0 : 4.0,
          actions: <Widget>[
            if (widget._currentCategory != null)
              _buildToggleActiveButton(widget._currentCategory!),
            if (widget._currentCategory != null) _buildDeleteButton(),
            _buildSubmitButton(),
          ],
        ),
        body: pageContent,
      ),
    );
  }

  Widget _buildNameTextField(CategoryModel? category) {
    return TextFormField(
      maxLength: Constants.maxNameLength,
      controller: _nameTextController,
      focusNode: _nameFocusNode,
      textInputAction: TextInputAction.next,
      onFieldSubmitted: (String term) {
        FormHelper.changeFieldFocus(
            context, _nameFocusNode, _descriptionFocusNode);
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
          labelText: 'Category Name *',
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

  Widget _buildDescriptionTextField(CategoryModel? category) {
    return TextFormField(
      maxLength: Constants.maxDescriptionLength,
      maxLines: 5,
      controller: _descriptionTextController,
      focusNode: _descriptionFocusNode,
      textInputAction: TextInputAction.newline,
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
//          hintText: 'Category Description',
          labelText: 'Category Description',
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

  Widget _buildActiveField() {
    if (widget._currentCategory == null) {
      return const SizedBox();
    }

    final bool isActive = widget._currentCategory!.active;
    const String message =
        'Inactive categories won\'t appear in the selection list during the product creation.';

    return Row(
      children: <Widget>[
        IconButton(
          icon: const Icon(Icons.info_outline_rounded),
          color: isActive ? Colors.green : Colors.red,
          tooltip: message,
          onPressed: () {
            UiHelper.showAlertDialogNoTitle(context, AlertType.info, message);
          },
        ),
        Text(
          isActive ? 'This category is active' : 'This category is inactive',
          style: TextStyle(
            color: isActive ? Colors.green : Colors.red,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return IconButton(
      onPressed: _isLoading ? null : () => _submitForm(),
      icon: const Icon(
        Icons.save,
        color: Colors.white,
        size: 30,
      ),
    );
  }

  Widget _buildDeleteButton() {
    return IconButton(
      onPressed: _isLoading ? null : () => _showConfirmationDialog(),
      icon: const Icon(
        Icons.delete_forever,
        color: Colors.white,
        size: 30,
      ),
    );
  }

  Widget _buildToggleActiveButton(CategoryModel category) {
    return IconButton(
      icon: category.active
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
      tooltip: 'Toggle category active',
      onPressed: () => _toggleActive(!category.active),
    );
  }

  Widget _buildPageContent(BuildContext context, CategoryModel? category) {
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
                _buildNameTextField(category),
                const SizedBox(
                  height: 5.0,
                ),
                _buildDescriptionTextField(category),
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

    if (widget._currentCategory == null) {
      _createCategory();
    } else {
      _updateCategory();
    }
  }

  void _createCategory() {
    setState(() => _isLoading = true);

    final CategoryModel categoryToCreate = CategoryModel(
      name: _formData.name!,
      description: _formData.description,
      active: true,
    );

    _categoryListStateNotifier
        .add(
      category: categoryToCreate,
      image: _formData.image,
    )
        .then((CategoryModel? categoryCreated) {
      setState(() => _isLoading = false);
      if (categoryCreated != null) {
        Navigator.pop(context, categoryCreated);
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
          title = 'Cannot create this category.';
          content = err.message;
        }

        UiHelper.showAlertDialog(context, AlertType.error, title, content);
      },
    );
  }

  void _updateCategory() {
    if (widget._currentCategory == null ||
        widget._currentCategory?.id == null) {
      logger.e('Cannot update category : current category cannot be null');
      return;
    }

    setState(() => _isLoading = true);

    final CategoryModel categoryToUpdate =
        CategoryModel.clone(widget._currentCategory!);
    categoryToUpdate.name = _formData.name!;
    categoryToUpdate.description = _formData.description;

    _categoryListStateNotifier
        .edit(
      categoryId: widget._currentCategory!.id!,
      category: categoryToUpdate,
      image: _formData.image,
    )
        .then((CategoryModel? categoryUpdated) {
      setState(() => _isLoading = false);
      if (categoryUpdated != null) {
        Navigator.pop(context, categoryUpdated);
      } else {
        _showErrorDialog();
      }
    }).catchError(
      (Object err, StackTrace trace) {
        setState(() => _isLoading = false);
        logger.e('Error: $err');

        String title = genericErrorTitle;
        String content = genericErrorMessage;

        final bool isNameNotUnique = err is NotUniqueException;
        if (isNameNotUnique) {
          title = 'Cannot update this category.';
          content = err.message;
        }

        UiHelper.showAlertDialog(context, AlertType.error, title, content);
      },
    );
  }

  void _showConfirmationDialog() {
    if (widget._currentCategory == null) {
      return;
    }

    AwesomeDialog(
      context: context,
      dialogType: DialogType.WARNING,
      animType: AnimType.BOTTOMSLIDE,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: const <Widget>[
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
          Text('Do you want to delete this category ?'),
        ],
      ),
      btnCancelColor: Colors.red,
      btnOkColor: Colors.green,
      btnCancelOnPress: () {
        logger.d('Cancel delete category ${widget._currentCategory!.name}');
      },
      btnOkOnPress: () {
        logger.d('Confirm delete category ${widget._currentCategory!.name}');
        _deleteCategory();
      },
    ).show();
  }

  void _deleteCategory() {
    if (widget._currentCategory == null) {
      return;
    }

    setState(() => _isLoading = true);

    _categoryListStateNotifier
        .remove(categoryToRemove: widget._currentCategory!)
        .then(
      (bool success) {
        setState(() => _isLoading = false);
        if (success) {
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
          title = 'Cannot delete this category.';
          content = err.message;
        }

        UiHelper.showAlertDialog(context, AlertType.error, title, content);
      },
    );
  }

  void _toggleActive(bool active) {
    if (widget._currentCategory == null ||
        widget._currentCategory!.id == null) {
      logger.e('Current category is null');
      return;
    }

    setState(() => _isLoading = true);

    _categoryListStateNotifier
        .toggleActive(categoryId: widget._currentCategory!.id!, active: active)
        .then(
      (CategoryModel? categoryUpdated) {
        setState(() => _isLoading = false);
        if (categoryUpdated != null) {
          Navigator.pop(context, categoryUpdated);
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
}

class _FormData {
  String? name;
  String? description;
  File? image;
}
