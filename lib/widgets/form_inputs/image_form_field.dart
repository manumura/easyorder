import 'dart:io';

import 'package:another_flushbar/flushbar.dart';
import 'package:flutter/material.dart';
import 'package:easyorder/shared/constants.dart';
import 'package:easyorder/widgets/helpers/logger.dart';
import 'package:easyorder/widgets/helpers/ui_helper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:logger/logger.dart';

import './image_input_adapter.dart';

class ImageFormField extends FormField<ImageInputAdapter> {
  /// ImageFormField
  ImageFormField({
    super.onSaved,
    super.validator,
    super.initialValue,
    AutovalidateMode autovalidate = AutovalidateMode.disabled,
    double fileMaxWidth = 300.0,
    double previewImageHeight = 300.0,
    int imageQuality = 100,
  }) : super(
          autovalidateMode: autovalidate,
          builder: (FormFieldState<ImageInputAdapter> state) {
            final Color buttonColor = Theme.of(state.context).primaryColor;
            // Widget previewImage = Text('Please select an image.');
            Widget deleteButton = _buildDeleteButton(state);
            Widget previewImage = _buildPreviewImage(state, previewImageHeight);

            return Column(
              children: <Widget>[
                OutlinedButton(
                  style: ButtonStyle(
                    side: WidgetStateProperty.resolveWith(
                      (Set<WidgetState> states) => BorderSide(
                        color: buttonColor,
                        width: 2.0,
                      ),
                    ),
                    padding: WidgetStateProperty.resolveWith(
                      (Set<WidgetState> states) => const EdgeInsets.all(12),
                    ),
                    shape: WidgetStateProperty.resolveWith(
                      (Set<WidgetState> states) => RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20.0),
                      ),
                    ),
                  ),
                  onPressed: () {
                    _openImagePicker(state, fileMaxWidth, imageQuality);
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Icon(
                        Icons.camera_alt,
                        color: buttonColor,
                      ),
                      const SizedBox(
                        width: 5.0,
                      ),
                      Text(
                        'CHOOSE IMAGE',
                        style: TextStyle(color: buttonColor),
                      )
                    ],
                  ),
                ),
                const SizedBox(height: 10.0),
                previewImage,
                if (state.hasError) const SizedBox(height: 10.0),
                if (state.hasError)
                  Text(
                    state.errorText!,
                    style:
                        Theme.of(state.context).inputDecorationTheme.errorStyle,
                  ),
                deleteButton,
                // else
                //   Container()
                // _imageFile == null
                //     ? Text('Please pick an image.')
                //     :
              ],
            );
          },
        );

  static Widget _buildPreviewImage(
      FormFieldState<ImageInputAdapter> state, double previewImageHeight) {
    Widget previewImage = const SizedBox();
    if (state.value != null) {
      if (state.value!.isFile) {
        previewImage = Image.file(
          state.value!.file!,
          fit: BoxFit.scaleDown,
          height: previewImageHeight,
          width: MediaQuery.of(state.context).size.width,
          alignment: Alignment.topCenter,
        );
      } else if (state.value!.isUrl) {
        previewImage = Image.network(
          state.value!.url!,
          fit: BoxFit.scaleDown,
          height: previewImageHeight,
          width: MediaQuery.of(state.context).size.width,
          alignment: Alignment.topCenter,
        );
      }
    }
    return previewImage;
  }

  static Widget _buildDeleteButton(FormFieldState<ImageInputAdapter> state) {
    Widget deleteButton = const SizedBox();
    if (state.value != null && (state.value!.isFile || state.value!.isUrl)) {
      deleteButton = ElevatedButton.icon(
        style: ButtonStyle(
          shape: WidgetStateProperty.resolveWith(
            (Set<WidgetState> states) => ContinuousRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
          ),
          foregroundColor: WidgetStateProperty.resolveWith(
              (Set<WidgetState> states) => Colors.white),
          backgroundColor: WidgetStateProperty.resolveWith(
              (Set<WidgetState> states) => Colors.red),
          elevation:
              WidgetStateProperty.resolveWith((Set<WidgetState> states) => 4.0),
        ),
        label: const Text('DELETE IMAGE'),
        icon: const Icon(Icons.delete_forever),
        onPressed: () => _deleteImage(state),
      );
    }
    return deleteButton;
  }

  static void _openImagePicker(FormFieldState<ImageInputAdapter> state,
      double fileMaxWidth, int imageQuality) {
    showModalBottomSheet<BuildContext>(
      shape: const RoundedRectangleBorder(
        side: BorderSide(
          color: Colors.white,
          width: 2.0,
        ),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(10.0),
          topRight: Radius.circular(10.0),
        ),
      ),
      context: state.context,
      builder: (BuildContext context) {
        return Container(
          width: MediaQuery.of(context).size.width,
          height: 160.0,
//            decoration: BoxDecoration(
//              color: Colors.white,
//              borderRadius: BorderRadius.only(
//                topLeft: Radius.circular(20.0),
//                topRight: Radius.circular(20.0),
//              )
//            ),
          padding: const EdgeInsets.all(10.0),
          child: Column(
            children: <Widget>[
              const Text(
                'Pick an Image',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18.0,
                ),
              ),
              const SizedBox(
                height: 10.0,
              ),
              TextButton(
                style: ButtonStyle(
                  foregroundColor: WidgetStateProperty.resolveWith(
                      (Set<WidgetState> states) =>
                          Theme.of(context).primaryColor),
                ),
                onPressed: () {
                  _getImage(
                      state, ImageSource.camera, fileMaxWidth, imageQuality);
                },
                child: const Text(
                  'Use Camera',
                  style: TextStyle(
                    fontSize: 16.0,
                  ),
                ),
              ),
              TextButton(
                style: ButtonStyle(
                  foregroundColor: WidgetStateProperty.resolveWith(
                      (Set<WidgetState> states) =>
                          Theme.of(context).primaryColor),
                ),
                onPressed: () {
                  _getImage(
                      state, ImageSource.gallery, fileMaxWidth, imageQuality);
                },
                child: const Text(
                  'Use Gallery',
                  style: TextStyle(
                    fontSize: 16.0,
                  ),
                ),
              )
            ],
          ),
        );
      },
    );
  }

  static void _getImage(FormFieldState<ImageInputAdapter> state,
      ImageSource source, double fileMaxWidth, int imageQuality) {
    final Logger logger = getLogger();
    ImagePicker()
        .pickImage(
      source: source,
      maxWidth: fileMaxWidth,
      imageQuality: imageQuality,
    )
        .then(
      (XFile? image) {
        if (image != null) {
          final ImageInputAdapter imageInputAdapter =
              ImageInputAdapter(file: File(image.path));
          state.didChange(imageInputAdapter);
        }

        if (state.mounted) {
          Navigator.pop(state.context);
        }
      },
    ).onError((Object? error, StackTrace stackTrace) {
      logger.e('Error while picking image: $error');
      final Flushbar<void> flushbar = UiHelper.createErrorFlushbar(
          message: 'Unexpected error while picking image', title: 'Error !');
      flushbar.show(navigatorKey.currentContext ?? state.context);

      if (state.mounted) {
        Navigator.pop(state.context);
      }
    });
  }

  static void _deleteImage(FormFieldState<ImageInputAdapter> state) {
    state.didChange(null);
  }
}
