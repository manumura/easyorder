import 'package:easyorder/bloc/auth_bloc.dart';
import 'package:easyorder/bloc/user_bloc.dart';
import 'package:easyorder/exceptions/authentication_exception.dart';
import 'package:easyorder/models/alert_type.dart';
import 'package:easyorder/models/authentication_provider.dart';
import 'package:easyorder/models/authentication_type.dart';
import 'package:easyorder/models/user_model.dart';
import 'package:easyorder/shared/about_utils.dart';
import 'package:easyorder/shared/constants.dart';
import 'package:easyorder/state/providers.dart';
import 'package:easyorder/widgets/helpers/form_helper.dart';
import 'package:easyorder/widgets/helpers/logger.dart';
import 'package:easyorder/widgets/helpers/ui_helper.dart';
import 'package:easyorder/widgets/helpers/validator.dart';
import 'package:easyorder/widgets/ui_elements/adapative_progress_indicator.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:package_info/package_info.dart';
import 'package:sign_button/constants.dart';
import 'package:sign_button/create_button.dart';

class LoginScreen extends ConsumerStatefulWidget {
  static const String routeName = '/login';

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with TickerProviderStateMixin {
  late AuthBloc authBloc;
  late UserBloc userBloc;

  final Logger logger = getLogger();
  final double maxHeightThreshold = 550.0;

  // final GlobalKey _fbKey = GlobalKey();
  // final GlobalKey _googleKey = GlobalKey();

  final _FormData _formData = _FormData();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  AuthenticationType _authMode = AuthenticationType.login;
  bool _isLoading = false;

  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();
  final FocusNode _passwordConfirmFocusNode = FocusNode();

  bool _isEmailClearVisible = false;
  bool _isPasswordClearVisible = false;
  bool _isPasswordConfirmClearVisible = false;

  final TextEditingController _emailTextController = TextEditingController();
  final TextEditingController _passwordTextController = TextEditingController();
  final TextEditingController _passwordConfirmTextController =
      TextEditingController();

  // final TextEditingController _emailTextController = useTextEditingController();
  // final TextEditingController _passwordTextController =
  //     useTextEditingController();
  // final TextEditingController _passwordConfirmTextController =
  //     useTextEditingController();
  // _emailTextController;
  // _passwordTextController.addListener(_togglePasswordClearVisible);
  // _passwordConfirmTextController.addListener(_togglePasswordConfirmClearVisible);

  late AnimationController _passwordOpacityAnimationController;
  late AnimationController _passwordAnimationController;

  // final AnimationController _passwordOpacityAnimationController =
  //     useAnimationController(
  //   duration: const Duration(milliseconds: 300),
  // );
  // final AnimationController _passwordAnimationController =
  //     useAnimationController(
  //   duration: const Duration(milliseconds: 300),
  // );

  late Animation<double> _passwordOpacityAnimation; // = useAnimation();
  late Animation<double> _passwordAnimation; // = useAnimation();

  late AnimationController _passwordConfirmOpacityAnimationController;
  late AnimationController _passwordConfirmAnimationController;

  // final AnimationController _passwordConfirmOpacityAnimationController =
  //     useAnimationController(
  //   duration: const Duration(milliseconds: 300),
  // );
  // final AnimationController _passwordConfirmAnimationController =
  //     useAnimationController(
  //   duration: const Duration(milliseconds: 300),
  // );

  late Animation<double> _passwordConfirmOpacityAnimation; // = useAnimation();
  late Animation<double> _passwordConfirmAnimation; // = useAnimation();

  PackageInfo _packageInfo = PackageInfo(
    appName: 'Unknown',
    packageName: 'Unknown',
    version: 'Unknown',
    buildNumber: 'Unknown',
  );

  @override
  void initState() {
    super.initState();

    authBloc = ref.read(authBlocProvider);
    userBloc = ref.read(userBlocProvider);

    _initPackageInfo();

    _emailTextController.addListener(_toggleEmailClearVisible);
    _passwordTextController.addListener(_togglePasswordClearVisible);
    _passwordConfirmTextController
        .addListener(_togglePasswordConfirmClearVisible);

    _passwordConfirmAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _passwordConfirmOpacityAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _passwordAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _passwordOpacityAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _passwordConfirmAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _passwordConfirmAnimationController, curve: Curves.easeIn),
    );

    _passwordConfirmOpacityAnimation =
        Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: CurvedAnimation(
            parent: _passwordConfirmOpacityAnimationController,
            curve: Curves.fastOutSlowIn),
        curve: Curves.easeIn,
      ),
    );

    _passwordAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
          parent: _passwordAnimationController, curve: Curves.easeIn),
    );

    _passwordOpacityAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
          parent: _passwordOpacityAnimationController,
          curve: Curves.fastOutSlowIn),
    );

    // WidgetsBinding.instance.addPostFrameCallback((Duration duration) {
    //   _getSizeAndPosition();
    // });
  }

  // void _getSizeAndPosition() {
  //   final RenderBox fbBox =
  //       _fbKey.currentContext.findRenderObject() as RenderBox;
  //   final fbSize = fbBox.size;
  //   final RenderBox googleBox =
  //       _googleKey.currentContext.findRenderObject() as RenderBox;
  //   final googleSize = googleBox.size;
  // }

  @override
  void dispose() {
    // Clean up the controller when the Widget is removed from the Widget tree
    _emailTextController.dispose();
    _passwordTextController.dispose();
    _passwordConfirmTextController.dispose();
    _passwordAnimationController.dispose();
    _passwordConfirmAnimationController.dispose();
    _passwordOpacityAnimationController.dispose();
    _passwordConfirmOpacityAnimationController.dispose();
    super.dispose();
  }

  void _toggleEmailClearVisible() {
    setState(() {
      _isEmailClearVisible = _emailTextController.text.isNotEmpty;
    });
  }

  void _togglePasswordClearVisible() {
    setState(() {
      _isPasswordClearVisible = _passwordTextController.text.isNotEmpty;
    });
  }

  void _togglePasswordConfirmClearVisible() {
    setState(() {
      _isPasswordConfirmClearVisible =
          _passwordConfirmTextController.text.isNotEmpty;
    });
  }

  Future<void> _initPackageInfo() async {
    final PackageInfo info = await PackageInfo.fromPlatform();
    setState(() {
      _packageInfo = info;
    });
  }

  Widget _buildEmailTextField() {
    return TextFormField(
      keyboardType: TextInputType.emailAddress,
      controller: _emailTextController,
      focusNode: _emailFocusNode,
      textInputAction: _authMode != AuthenticationType.forgotPassword
          ? TextInputAction.next
          : TextInputAction.done,
      onFieldSubmitted: (String value) {
        if (_authMode != AuthenticationType.forgotPassword) {
          FormHelper.changeFieldFocus(
              context, _emailFocusNode, _passwordFocusNode);
        } else {
          _submitForm();
        }
      },
      decoration: InputDecoration(
        prefixIcon: const Padding(
          padding: EdgeInsets.only(left: 5.0),
          child: Icon(
            Icons.email,
          ),
        ),
        suffixIcon: !_isEmailClearVisible
            ? const SizedBox()
            : IconButton(
                onPressed: () {
                  _emailTextController.clear();
                },
                icon: const Icon(
                  Icons.clear,
                )),
        hintText: 'Email',
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 10.0, vertical: 10.0),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(20.0)),
        filled: true,
        fillColor: Colors.white,
      ),
      validator: (String? value) {
        return Validator.validateEmail(value);
      },
      onSaved: (String? value) {
        _formData.email = value;
      },
    );
  }

  Widget _buildPasswordTextField() {
    return FadeTransition(
      opacity: _passwordOpacityAnimation,
      child: SizeTransition(
        sizeFactor: _passwordAnimation,
        child: TextFormField(
          obscureText: true,
          controller: _passwordTextController,
          focusNode: _passwordFocusNode,
          textInputAction: _authMode != AuthenticationType.login
              ? TextInputAction.next
              : TextInputAction.done,
          onFieldSubmitted: (String term) {
            if (_authMode != AuthenticationType.login) {
              FormHelper.changeFieldFocus(
                  context, _passwordFocusNode, _passwordConfirmFocusNode);
            } else {
              _submitForm();
            }
          },
          decoration: InputDecoration(
              prefixIcon: const Padding(
                padding: EdgeInsets.only(left: 5.0),
                child: Icon(
                  Icons.lock,
                ),
              ),
              suffixIcon: !_isPasswordClearVisible
                  ? const SizedBox()
                  : IconButton(
                      onPressed: () {
                        _passwordTextController.clear();
                      },
                      icon: const Icon(
                        Icons.clear,
                      )),
              hintText: 'Password',
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 10.0, vertical: 10.0),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(20.0)),
              filled: true,
              fillColor: Colors.white),
          validator: (String? value) {
            if (_authMode != AuthenticationType.forgotPassword) {
              return Validator.validatePassword(value);
            }
            return null;
          },
          onSaved: (String? value) {
            _formData.password = value;
          },
        ),
      ),
    );
  }

  Widget _buildPasswordConfirmTextField() {
    return FadeTransition(
      opacity: _passwordConfirmOpacityAnimation,
      child: SizeTransition(
        sizeFactor: _passwordConfirmAnimation,
        child: TextFormField(
          obscureText: true,
          focusNode: _passwordConfirmFocusNode,
          textInputAction: TextInputAction.done,
          onFieldSubmitted: (String term) => _submitForm(),
          controller: _passwordConfirmTextController,
          style: const TextStyle(fontSize: 16.0),
          decoration: InputDecoration(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 10.0, vertical: 10.0),
              prefixIcon: const Padding(
                padding: EdgeInsets.only(left: 5.0),
                child: Icon(
                  Icons.lock,
                ),
              ),
              suffixIcon: !_isPasswordConfirmClearVisible
                  ? const SizedBox()
                  : IconButton(
                      onPressed: () {
                        _passwordConfirmTextController.clear();
                      },
                      icon: const Icon(
                        Icons.clear,
                      )),
              hintText: 'Confirm password',
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(20.0)),
              filled: true,
              fillColor: Colors.white),
          validator: (String? value) {
            // TODO export to class
            if (_passwordTextController.text != value &&
                _authMode == AuthenticationType.signUp) {
              return 'Passwords do not match';
            }
            return null;
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            image: _buildBackgroundImage(),
            color: backgroundColor,
            border: Border.all(color: backgroundColor), // Colors.red
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10.0),
          child: _buildPageContent(context),
        ),
      ),
      bottomNavigationBar: _buildFooter(context),
    );
  }

  Widget _buildSwitchButton() {
    final double bottomButtonFontSize =
        MediaQuery.of(context).size.height > maxHeightThreshold ? 16 : 12;
    return _authMode == AuthenticationType.forgotPassword
        ? Container()
        : Material(
            color: Colors.transparent,
            child: InkWell(
              splashColor: Theme.of(context).colorScheme.secondary,
              onTap: () {
                if (_authMode == AuthenticationType.login) {
                  setState(() {
                    _authMode = AuthenticationType.signUp;
                  });
                  _passwordConfirmOpacityAnimationController.forward();
                  _passwordConfirmAnimationController.forward();
                } else {
                  setState(() {
                    _authMode = AuthenticationType.login;
                  });
                  _passwordConfirmOpacityAnimationController.reverse();
                  _passwordConfirmAnimationController.reverse();
                }
              },
              child: Container(
                padding: const EdgeInsets.all(8.0),
//                decoration: BoxDecoration(color: Colors.red),
                child: Text(
                  _authMode == AuthenticationType.login
                      ? 'Don' 't have an account ? Create one !'
                      : 'Already have an account ? Sign in !',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.secondary,
                    fontWeight: FontWeight.bold,
                    fontSize: bottomButtonFontSize,
                  ),
                ),
              ),
            ),
          );
  }

  Widget _buildForgotPasswordButton() {
    final double bottomButtonFontSize =
        MediaQuery.of(context).size.height > maxHeightThreshold ? 16 : 12;
    return _authMode == AuthenticationType.signUp
        ? Container()
        : Material(
            color: Colors.transparent,
            child: InkWell(
              splashColor: Theme.of(context).colorScheme.secondary,
              onTap: () {
                if (_authMode == AuthenticationType.login) {
                  setState(() => _authMode = AuthenticationType.forgotPassword);
                  _passwordAnimationController.forward();
                  _passwordOpacityAnimationController.forward();
                } else {
                  setState(() => _authMode = AuthenticationType.login);
                  _passwordAnimationController.reverse();
                  _passwordOpacityAnimationController.reverse();
                }
              },
              child: Container(
                padding: const EdgeInsets.all(8.0),
//                decoration: BoxDecoration(color: Colors.red),
                child: Text(
                  _authMode == AuthenticationType.login
                      ? 'Forgot password ?'
                      : 'Sign in !',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.secondary,
                    fontWeight: FontWeight.bold,
                    fontSize: bottomButtonFontSize,
                  ),
                ),
              ),
            ),
          );
  }

  Widget _buildAboutButton(BuildContext context) {
    return Material(
      color: Colors.transparent,
      textStyle: TextStyle(
        color: Theme.of(context).colorScheme.secondary,
        fontWeight: FontWeight.bold,
        fontSize: 10,
      ),
      child: TextButton.icon(
        icon: const Icon(
          Icons.info,
          color: Colors.indigo,
        ),
        onPressed: () =>
            openAboutDialog(context, _packageInfo, applicationLegalese),
        label: const Text(
          'About',
          style: TextStyle(
            color: Colors.indigo,
          ),
        ),
      ),
    );
  }

  Widget _buildPageContent(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).requestFocus(FocusNode());
      },
      child: Align(
        // align vertically
        alignment: Alignment.center,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    final List<Widget> children = <Widget>[
      _buildSwitchButton(),
      _buildForgotPasswordButton(),
      _buildAboutButton(context),
    ];

    return Container(
      // color: backgroundColor,
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border.all(color: backgroundColor), // Colors.red
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          return Column(
            children: <Widget>[
              _buildTitle(),
              _buildForm(authBloc),
            ],
          );
        },
      ),
    );
  }

  Widget _buildForm(AuthBloc? authBloc) {
    return Form(
      key: _formKey,
      child: Column(
        children: <Widget>[
          _buildEmailTextField(),
          const SizedBox(
            height: 10.0,
          ),
          _buildPasswordTextField(),
          if (_authMode == AuthenticationType.login ||
              _authMode == AuthenticationType.signUp)
            const SizedBox(
              height: 10.0,
            ),
          _buildPasswordConfirmTextField(),
          if (_authMode == AuthenticationType.signUp)
            const SizedBox(
              height: 10.0,
            ),
          _buildSubmitButtons(),
        ],
      ),
    );
  }

  Widget _buildTitle() {
    final double deviceHeight = MediaQuery.of(context).size.height;
    final double titleFontSize = deviceHeight > maxHeightThreshold ? 45 : 35;
    final double titlePadding = deviceHeight > maxHeightThreshold ? 30 : 10;

    return Container(
      margin: EdgeInsets.only(top: titlePadding, bottom: titlePadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text(
            'SIMPLE',
            style: TextStyle(
              fontSize: titleFontSize,
              fontFamily: 'LuckiestGuy',
              color: Theme.of(context).colorScheme.secondary,
            ),
          ),
          Text(
            'ORDER',
            style: TextStyle(
              fontSize: titleFontSize,
              fontFamily: 'LuckiestGuy',
              color: Theme.of(context).colorScheme.secondary,
            ),
          ),
          Text(
            'MANAGER',
            style: TextStyle(
              fontSize: titleFontSize,
              fontFamily: 'LuckiestGuy',
              color: Theme.of(context).colorScheme.secondary,
            ),
          ),
        ],
      ),
    );
  }

  DecorationImage _buildBackgroundImage() {
    final Color color = backgroundColor;
    return DecorationImage(
      fit: BoxFit.scaleDown,
      colorFilter: ColorFilter.mode(color.withOpacity(0.1), BlendMode.dstATop),
      image: const AssetImage('assets/background.png'),
    );
  }

  Widget _buildSubmitButtons() {
    // const double submitButtonPadding = 0;
    final Widget loginButton = SizedBox(
      width: 200,
      child: ElevatedButton(
        style: ButtonStyle(
          shape: MaterialStateProperty.resolveWith(
            (Set<MaterialState> states) => RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
          ),
          foregroundColor: MaterialStateProperty.resolveWith(
              (Set<MaterialState> states) => Colors.white),
          backgroundColor: MaterialStateProperty.resolveWith(
              (Set<MaterialState> states) =>
                  Theme.of(context).colorScheme.secondary),
        ),
        onPressed: () => _submitForm(),
        child: Text(_authMode == AuthenticationType.login
            ? 'LOGIN'
            : (_authMode == AuthenticationType.signUp
                ? 'REGISTER'
                : 'RESET PASSWORD')),
      ),
    );
    final Widget googleSignInButton = _authMode == AuthenticationType.login
        ? SignInButton(
            buttonType: ButtonType.google,
            buttonSize: ButtonSize.medium, // small(default), medium, large
            onPressed: () => _signInWithProvider(AuthenticationProvider.google),
          )
        : const SizedBox();
    final Widget facebookSignInButton = _authMode == AuthenticationType.login
        ? SignInButton(
            buttonType: ButtonType.facebook,
            buttonSize: ButtonSize.medium,
            // btnText: 'Facebook Signin',
            width: 250,
            onPressed: () =>
                _signInWithProvider(AuthenticationProvider.facebook),
          )
        : const SizedBox();

    return Container(
      // padding: const EdgeInsets.only(),
      child: _isLoading
          ? Column(children: <Widget>[
              AdaptiveProgressIndicator(),
              const SizedBox(
                height: 108, // (48 + 6) x 2
              )
            ])
          : Column(
              children: <Widget>[
                loginButton,
                const SizedBox(
                  height: 5,
                ),
                googleSignInButton,
                const SizedBox(
                  height: 10,
                ),
                facebookSignInButton,
              ],
            ),
    );
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState == null) {
      logger.e('Cannot submit form : formKey currentState is null');
      return;
    }

    if (!_formKey.currentState!.validate()) {
      setState(() => _isLoading = false);
      return;
    }

    _formKey.currentState!.save();

    if (_authMode == AuthenticationType.forgotPassword) {
      if (_formData.email == null) {
        UiHelper.showAlertDialog(context, AlertType.error,
            'Missing mandatory data !', 'Email should be filled');
        return;
      }
    } else {
      if (_formData.email == null || _formData.password == null) {
        UiHelper.showAlertDialog(context, AlertType.error,
            'Missing mandatory data !', 'Email and password should be filled');
        return;
      }
    }

    switch (_authMode) {
      case AuthenticationType.login:
        final UserModel? user = await _signInWithEmailAndPassword(
          email: _formData.email!,
          password: _formData.password!,
        );
        logger.d('Logged in user: $user');
        break;

      case AuthenticationType.signUp:
        await _register(
          email: _formData.email!,
          password: _formData.password!,
        );
        break;

      case AuthenticationType.forgotPassword:
        await _forgotPassword(
          email: _formData.email!,
        );
        break;

      default:
        logger.e('Unsupported Auth Mode');
        break;
    }
  }

  Future<UserModel?> _signInWithEmailAndPassword(
      {required String email, required String password}) async {
    try {
      setState(() => _isLoading = true);

      final UserModel? user = await authBloc.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (user == null || !user.isEmailVerified) {
        setState(() => _isLoading = false);
        if (!mounted) return null;
        UiHelper.showAlertDialog(
            context,
            AlertType.error,
            'Authentication failed !',
            'Please check that your email address is verified');
      } else {
        await _setCrashlyticsUserIdentifier(user);
        setState(() => _isLoading = false);
        authBloc.login(user);
      }
      return user;
    } on AuthenticationException catch (e) {
      setState(() => _isLoading = false);
      UiHelper.showAlertDialog(
          context, AlertType.error, 'Authentication failed !', e.message);
      return null;
    } catch (e) {
      setState(() => _isLoading = false);
      UiHelper.showAlertDialog(context, AlertType.error,
          'Authentication failed !', 'Please check your username and password');
      return null;
    }
  }

  Future<UserModel?> _signInWithProvider(
      AuthenticationProvider provider) async {
    try {
      setState(() => _isLoading = true);

      UserModel? user;
      switch (provider) {
        case AuthenticationProvider.google:
          user = await authBloc.signInWithGoogle();
          logger.d('Google user: $user');
          break;
        case AuthenticationProvider.facebook:
          user = await authBloc.signInWithFacebook();
          logger.d('Facebook user: $user');
          break;
        default:
          logger.e('Authentication provider not implemented');
          user = null;
          break;
      }

      if (user == null) {
        setState(() => _isLoading = false);
        if (!mounted) return null;
        UiHelper.showAlertDialog(context, AlertType.error,
            'Authentication failed !', 'Please try again later');
      } else {
        await userBloc.createCounters(userId: user.id);
        await _setCrashlyticsUserIdentifier(user);
        setState(() => _isLoading = false);
        authBloc.login(user);
      }
      return user;
    } on AuthenticationException catch (e) {
      setState(() => _isLoading = false);
      UiHelper.showAlertDialog(
          context, AlertType.error, 'Authentication failed !', e.message);
      return null;
    } catch (e) {
      setState(() => _isLoading = false);
      UiHelper.showAlertDialog(context, AlertType.error,
          'Authentication failed !', 'Please try again later');
      return null;
    }
  }

  Future<void> _register(
      {required String email, required String password}) async {
    try {
      setState(() => _isLoading = true);

      final UserModel? user = await authBloc.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (user == null) {
        setState(() => _isLoading = false);
        if (!mounted) return;
        UiHelper.showAlertDialog(
            context,
            AlertType.error,
            'Registration failed !',
            'Please try again and verify that your email is not already used');
        return;
      }

      await userBloc.createCounters(userId: user.id);

      setState(() {
        _isLoading = false;
        _authMode = AuthenticationType.login;
      });

      _passwordConfirmOpacityAnimationController.reverse();
      _passwordConfirmAnimationController.reverse();

      if (!mounted) return;
      UiHelper.showAlertDialog(
          context,
          AlertType.info,
          'Registration successful !',
          'A verification email has been sent to your email address');
    } on AuthenticationException catch (e) {
      setState(() => _isLoading = false);
      UiHelper.showAlertDialog(
          context, AlertType.error, 'Registration failed !', e.message);
    } catch (e) {
      setState(() => _isLoading = false);
      UiHelper.showAlertDialog(
          context,
          AlertType.error,
          'Registration failed !',
          'Please try again and verify that your email is not already used');
    }
  }

  Future<void> _forgotPassword({required String email}) async {
    try {
      setState(() => _isLoading = true);

      await authBloc.sendPasswordResetEmail(
        email: email,
      );

      setState(() {
        _isLoading = false;
        _authMode = AuthenticationType.login;
      });

      _passwordOpacityAnimationController.reverse();
      _passwordAnimationController.reverse();
      _passwordConfirmOpacityAnimationController.reverse();
      _passwordConfirmAnimationController.reverse();

      if (!mounted) return;
      UiHelper.showAlertDialog(
          context,
          AlertType.info,
          'Reset password successful !',
          'A reset password email has been sent to your email address');
    } on AuthenticationException catch (e) {
      setState(() => _isLoading = false);
      UiHelper.showAlertDialog(
          context, AlertType.error, 'Reset password failed !', e.message);
    } catch (e) {
      setState(() => _isLoading = false);
      UiHelper.showAlertDialog(context, AlertType.error,
          'Reset password failed !', 'Please try again later');
    }
  }

  Future<void> _setCrashlyticsUserIdentifier(UserModel user) async {
    // Set Crashlytics user info
    logger.d('Setting up FirebaseCrashlytics with user: $user');
    await FirebaseCrashlytics.instance.setUserIdentifier(user.id);
  }
}

class _FormData {
  String? email;
  String? password;
}
