import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import '../models/form_model.dart';
import '../services/forms_firebase_service.dart';
import '../auth/auth_service.dart';
import '../../theme.dart';

class FormPublicPage extends StatefulWidget {
  final String formId;

  const FormPublicPage({
    super.key,
    required this.formId,
  });

  @override
  State<FormPublicPage> createState() => _FormPublicPageState();
}

class _FormPublicPageState extends State<FormPublicPage>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();
  
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;
  
  FormModel? _form;
  bool _isLoading = true;
  bool _isSubmitting = false;
  bool _isSubmitted = false;
  String? _errorMessage;
  
  // Form responses
  final Map<String, dynamic> _responses = {};
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, FocusNode> _focusNodes = {};
  final Map<String, List<PlatformFile>> _selectedFiles = {};

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    
    _loadForm();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    for (final focusNode in _focusNodes.values) {
      focusNode.dispose();
    }
    super.dispose();
  }

  Future<void> _loadForm() async {
    setState(() => _isLoading = true);
    try {
      final form = await FormsFirebaseService.getPublicForm(widget.formId);
      if (form != null) {
        setState(() {
          _form = form;
          _isLoading = false;
        });
        _initializeForm();
        _animationController.forward();
      } else {
        setState(() {
          _errorMessage = 'Formulaire introuvable ou non disponible';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur lors du chargement: $e';
        _isLoading = false;
      });
    }
  }

  void _initializeForm() {
    if (_form == null) return;
    
    // Initialize controllers and focus nodes for input fields
    for (final field in _form!.fields) {
      if (field.isInputField) {
        _controllers[field.id] = TextEditingController();
        _focusNodes[field.id] = FocusNode();
        
        // Pre-fill person fields if user is authenticated
        if (field.type == 'person_field' && AuthService.isSignedIn) {
          _prefillPersonField(field);
        }
      }
    }
  }

  Future<void> _prefillPersonField(CustomFormField field) async {
    if (!field.personField.containsKey('field')) return;
    
    final personFieldType = field.personField['field'];
    final controller = _controllers[field.id];
    if (controller == null) return;
    
    try {
      // Get current user's person data
      final currentUser = AuthService.currentUser;
      if (currentUser == null) return;
      
      // Fetch person data from Firestore
      final personData = await FirebaseFirestore.instance
          .collection('personnes')
          .where('userId', isEqualTo: currentUser.uid)
          .get();
      
      if (personData.docs.isEmpty) {
        // If no person record exists, at least fill email from user
        if (personFieldType == 'email') {
          controller.text = currentUser.email ?? '';
        }
        return;
      }
      
      final person = personData.docs.first.data();
      
      // Fill field based on person field type
      switch (personFieldType) {
        case 'firstName':
          controller.text = person['prenom'] ?? '';
          break;
        case 'lastName':
          controller.text = person['nom'] ?? '';
          break;
        case 'email':
          controller.text = person['email'] ?? currentUser.email ?? '';
          break;
        case 'phone':
          controller.text = person['telephone'] ?? '';
          break;
        case 'address':
          controller.text = person['adresse'] ?? '';
          break;
        case 'city':
          controller.text = person['ville'] ?? '';
          break;
        case 'postalCode':
          controller.text = person['codePostal'] ?? '';
          break;
        case 'birthDate':
          if (person['dateNaissance'] != null) {
            final birthDate = (person['dateNaissance'] as Timestamp).toDate();
            controller.text = DateFormat('dd/MM/yyyy').format(birthDate);
          }
          break;
        case 'gender':
          controller.text = person['sexe'] ?? '';
          break;
        case 'maritalStatus':
          controller.text = person['situationMatrimoniale'] ?? '';
          break;
        case 'profession':
          controller.text = person['profession'] ?? '';
          break;
        case 'emergencyContact':
          controller.text = person['contactUrgence'] ?? '';
          break;
        case 'emergencyPhone':
          controller.text = person['telephoneUrgence'] ?? '';
          break;
        default:
          // For custom fields, check if they exist in person data
          if (person.containsKey(personFieldType)) {
            controller.text = person[personFieldType]?.toString() ?? '';
          }
      }
    } catch (e) {
      debugPrint('Error prefilling person field: $e');
      // Fallback to user email if available
      if (personFieldType == 'email' && AuthService.currentUser?.email != null) {
        controller.text = AuthService.currentUser!.email!;
      }
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      // Scroll to first error
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // Collect responses
      final responses = <String, dynamic>{};
      for (final field in _form!.fields) {
        if (field.isInputField) {
          final value = _getFieldValue(field);
          if (value != null) {
            responses[field.id] = value;
          }
        }
      }

      // Create submission
      final submission = FormSubmissionModel(
        id: '',
        formId: _form!.id,
        personId: AuthService.currentUser?.uid,
        firstName: _getResponseValue('firstName') ?? '',
        lastName: _getResponseValue('lastName') ?? '',
        email: _getResponseValue('email') ?? AuthService.currentUser?.email,
        responses: responses,
        submittedAt: DateTime.now(),
        isTestSubmission: _form!.settings.enableTestMode,
      );

      await FormsFirebaseService.submitForm(submission);
      
      setState(() {
        _isSubmitted = true;
        _isSubmitting = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isSubmitting = false;
      });
    }
  }

  dynamic _getFieldValue(CustomFormField field) {
    switch (field.type) {
      case 'checkbox':
        return _responses[field.id] ?? [];
      case 'radio':
      case 'select':
        return _responses[field.id];
      case 'date':
        final dateStr = _controllers[field.id]?.text;
        if (dateStr != null && dateStr.isNotEmpty) {
          try {
            return DateFormat('dd/MM/yyyy').parse(dateStr);
          } catch (e) {
            return null;
          }
        }
        return null;
      default:
        return _controllers[field.id]?.text;
    }
  }

  String? _getResponseValue(String key) {
    // Helper to get specific response values
    for (final field in _form!.fields) {
      if (field.type == 'person_field' && field.personField['field'] == key) {
        return _controllers[field.id]?.text;
      }
      if (field.type == key || (field.type == 'email' && key == 'email')) {
        return _controllers[field.id]?.text;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar.large(
              expandedHeight: 200,
              floating: false,
              pinned: true,
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
              flexibleSpace: FlexibleSpaceBar(
                title: Text(
                  _form?.title ?? 'Formulaire',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 20,
                  ),
                ),
                titlePadding: const EdgeInsets.only(left: 20, bottom: 16, right: 20),
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        colorScheme.primary,
                        colorScheme.primary.withOpacity(0.8),
                      ],
                    ),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        right: -30,
                        top: -30,
                        child: Container(
                          width: 150,
                          height: 150,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: colorScheme.onPrimary.withOpacity(0.1),
                          ),
                        ),
                      ),
                      Positioned(
                        right: 20,
                        bottom: 80,
                        child: Icon(
                          Icons.assignment_outlined,
                          size: 50,
                          color: colorScheme.onPrimary.withOpacity(0.3),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ];
        },
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 60,
              height: 60,
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
                strokeWidth: 3,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Chargement du formulaire...',
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Card(
            elevation: 2,
            color: colorScheme.errorContainer,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.error_outline_rounded,
                    size: 80,
                    color: colorScheme.onErrorContainer,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Oops ! Une erreur est survenue',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onErrorContainer,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _errorMessage!,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: colorScheme.onErrorContainer.withOpacity(0.8),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: _loadForm,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Réessayer'),
                    style: FilledButton.styleFrom(
                      backgroundColor: colorScheme.onErrorContainer,
                      foregroundColor: colorScheme.errorContainer,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    if (_isSubmitted) {
      return FadeTransition(
        opacity: _fadeAnimation,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Card(
              elevation: 4,
              color: colorScheme.surfaceContainerHighest,
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: AppTheme.successColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.check_circle_rounded,
                        size: 60,
                        color: AppTheme.successColor,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Merci !',
                      style: GoogleFonts.poppins(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Votre formulaire a été soumis avec succès',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Container(
                      constraints: const BoxConstraints(maxWidth: 350),
                      child: Text(
                        _form!.settings.confirmationMessage,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 32),
                    FilledButton.icon(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back_outlined),
                      label: Text(
                        'Retour',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0.0, 0.3),
          end: Offset.zero,
        ).animate(_slideAnimation),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              if (_form!.headerImageUrl != null)
                Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: NetworkImage(_form!.headerImageUrl!),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              
              Expanded(
                child: SingleChildScrollView(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(AppTheme.spaceLarge),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Form header
                      Text(
                        _form!.title,
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: AppTheme.fontBold,
                          color: AppTheme.textPrimaryColor,
                        ),
                      ),
                      if (_form!.description.isNotEmpty) ...[
                        const SizedBox(height: AppTheme.spaceMedium),
                        Text(
                          _form!.description,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: AppTheme.textSecondaryColor,
                          ),
                        ),
                      ],
                      
                      const SizedBox(height: AppTheme.spaceXLarge),
                      
                      // Form fields
                      ...List.generate(_form!.fields.length, (index) {
                        final field = _form!.fields[index];
                        return _buildField(field);
                      }),
                      
                      const SizedBox(height: AppTheme.spaceXLarge),
                      
                      // Submit button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isSubmitting ? null : _submitForm,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: AppTheme.white100,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                            ),
                          ),
                          child: _isSubmitting
                              ? const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(AppTheme.white100),
                                      ),
                                    ),
                                    SizedBox(width: AppTheme.space12),
                                    Text('Envoi en cours...'),
                                  ],
                                )
                              : const Text(
                                  'Soumettre le formulaire',
                                  style: TextStyle(
                                    fontSize: AppTheme.fontSize16,
                                    fontWeight: AppTheme.fontBold,
                                  ),
                                ),
                        ),
                      ),
                      
                      const SizedBox(height: AppTheme.spaceLarge),
                      
                      // Form info
                      if (_form!.hasSubmissionLimit)
                        Container(
                          padding: const EdgeInsets.all(AppTheme.space12),
                          decoration: BoxDecoration(
                            color: AppTheme.warningColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: AppTheme.warningColor,
                                size: 16,
                              ),
                              const SizedBox(width: AppTheme.spaceSmall),
                              Text(
                                'Limite de ${_form!.submissionLimit} soumissions',
                                style: TextStyle(
                                  color: AppTheme.warningColor,
                                  fontSize: AppTheme.fontSize12,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(CustomFormField field) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (field.isContentField) ...[
            _buildContentField(field),
          ] else ...[
            _buildInputField(field),
          ],
        ],
      ),
    );
  }

  Widget _buildContentField(CustomFormField field) {
    switch (field.type) {
      case 'section':
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 2,
                color: AppTheme.primaryColor,
              ),
              const SizedBox(height: AppTheme.spaceSmall),
              Text(
                field.label,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: AppTheme.fontBold,
                  color: AppTheme.primaryColor,
                ),
              ),
              if (field.helpText != null) ...[
                const SizedBox(height: AppTheme.spaceXSmall),
                Text(
                  field.helpText!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
              ],
            ],
          ),
        );
      case 'title':
        return Text(
          field.label,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: AppTheme.fontBold,
          ),
        );
      case 'instructions':
        return Container(
          padding: const EdgeInsets.all(AppTheme.spaceMedium),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
            border: Border.all(
              color: AppTheme.primaryColor.withOpacity(0.3),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.info_outline,
                color: AppTheme.primaryColor,
                size: 20,
              ),
              const SizedBox(width: AppTheme.space12),
              Expanded(
                child: Text(
                  field.label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
            ],
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildInputField(CustomFormField field) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        Row(
          children: [
            Expanded(
              child: Text(
                field.label,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: AppTheme.fontSemiBold,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
            ),
            if (field.isRequired)
              Text(
                '*',
                style: TextStyle(
                  color: AppTheme.errorColor,
                  fontSize: AppTheme.fontSize16,
                  fontWeight: AppTheme.fontBold,
                ),
              ),
          ],
        ),
        
        if (field.helpText != null) ...[
          const SizedBox(height: AppTheme.spaceXSmall),
          Text(
            field.helpText!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.textSecondaryColor,
            ),
          ),
        ],
        
        const SizedBox(height: AppTheme.spaceSmall),
        
        // Input widget
        _buildInputWidget(field),
      ],
    );
  }

  Widget _buildInputWidget(CustomFormField field) {
    switch (field.type) {
      case 'text':
      case 'email':
      case 'phone':
      case 'person_field':
        return _buildTextInput(field);
      case 'textarea':
        return _buildTextAreaInput(field);
      case 'select':
        return _buildSelectInput(field);
      case 'radio':
        return _buildRadioInput(field);
      case 'checkbox':
        return _buildCheckboxInput(field);
      case 'date':
        return _buildDateInput(field);
      case 'time':
        return _buildTimeInput(field);
      case 'file':
        return _buildFileInput(field);
      case 'signature':
        return _buildSignatureInput(field);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildTextInput(CustomFormField field) {
    return TextFormField(
      controller: _controllers[field.id],
      focusNode: _focusNodes[field.id],
      decoration: InputDecoration(
        hintText: field.placeholder,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        ),
        filled: true,
        fillColor: AppTheme.white100,
      ),
      keyboardType: _getKeyboardType(field.type),
      validator: (value) => _validateField(field, value),
      inputFormatters: _getInputFormatters(field.type),
    );
  }

  Widget _buildTextAreaInput(CustomFormField field) {
    return TextFormField(
      controller: _controllers[field.id],
      focusNode: _focusNodes[field.id],
      decoration: InputDecoration(
        hintText: field.placeholder,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        ),
        filled: true,
        fillColor: AppTheme.white100,
      ),
      maxLines: 4,
      validator: (value) => _validateField(field, value),
    );
  }

  Widget _buildSelectInput(CustomFormField field) {
    return DropdownButtonFormField<String>(
      initialValue: _responses[field.id],
      decoration: InputDecoration(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        ),
        filled: true,
        fillColor: AppTheme.white100,
      ),
      hint: Text(field.placeholder ?? 'Sélectionnez une option'),
      items: field.options.map((option) {
        return DropdownMenuItem<String>(
          value: option,
          child: Text(option),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _responses[field.id] = value;
        });
      },
      validator: (value) => _validateField(field, value),
    );
  }

  Widget _buildRadioInput(CustomFormField field) {
    return Column(
      children: field.options.map((option) {
        return RadioListTile<String>(
          title: Text(option),
          value: option,
          groupValue: _responses[field.id],
          onChanged: (value) {
            setState(() {
              _responses[field.id] = value;
            });
          },
          activeColor: AppTheme.primaryColor,
        );
      }).toList(),
    );
  }

  Widget _buildCheckboxInput(CustomFormField field) {
    final selectedOptions = _responses[field.id] as List<String>? ?? [];
    
    return Column(
      children: field.options.map((option) {
        return CheckboxListTile(
          title: Text(option),
          value: selectedOptions.contains(option),
          onChanged: (value) {
            setState(() {
              if (value == true) {
                selectedOptions.add(option);
              } else {
                selectedOptions.remove(option);
              }
              _responses[field.id] = selectedOptions;
            });
          },
          activeColor: AppTheme.primaryColor,
        );
      }).toList(),
    );
  }

  Widget _buildDateInput(CustomFormField field) {
    return TextFormField(
      controller: _controllers[field.id],
      decoration: InputDecoration(
        hintText: 'JJ/MM/AAAA',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        ),
        filled: true,
        fillColor: AppTheme.white100,
        suffixIcon: const Icon(Icons.calendar_today),
      ),
      readOnly: true,
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime(1900),
          lastDate: DateTime(2100),
        );
        if (date != null) {
          _controllers[field.id]?.text = DateFormat('dd/MM/yyyy').format(date);
        }
      },
      validator: (value) => _validateField(field, value),
    );
  }

  Widget _buildTimeInput(CustomFormField field) {
    return TextFormField(
      controller: _controllers[field.id],
      decoration: InputDecoration(
        hintText: 'HH:MM',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        ),
        filled: true,
        fillColor: AppTheme.white100,
        suffixIcon: const Icon(Icons.access_time),
      ),
      readOnly: true,
      onTap: () async {
        final time = await showTimePicker(
          context: context,
          initialTime: TimeOfDay.now(),
        );
        if (time != null) {
          _controllers[field.id]?.text = time.format(context);
        }
      },
      validator: (value) => _validateField(field, value),
    );
  }

  Widget _buildFileInput(CustomFormField field) {
    final selectedFiles = _selectedFiles[field.id] ?? [];
    final maxFiles = field.validation['maxFiles'] ?? 1;
    final allowedTypes = field.validation['allowedTypes'] as List<String>? ?? ['*'];
    final maxSizeMB = field.validation['maxSize'] ?? 10;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // File selection area
        Container(
          height: selectedFiles.isEmpty ? 120 : 80,
          decoration: BoxDecoration(
            border: Border.all(
              color: AppTheme.grey500,
              style: BorderStyle.solid,
            ),
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            color: AppTheme.white100,
          ),
          child: InkWell(
            onTap: selectedFiles.length < maxFiles ? () => _pickFiles(field) : null,
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  selectedFiles.length >= maxFiles ? Icons.check_circle : Icons.cloud_upload,
                  size: selectedFiles.isEmpty ? 48 : 32,
                  color: selectedFiles.length >= maxFiles 
                      ? AppTheme.successColor 
                      : AppTheme.textTertiaryColor,
                ),
                const SizedBox(height: AppTheme.spaceSmall),
                Text(
                  selectedFiles.length >= maxFiles
                      ? 'Nombre maximum de fichiers atteint'
                      : selectedFiles.isEmpty
                          ? 'Cliquez pour sélectionner ${maxFiles > 1 ? 'des fichiers' : 'un fichier'}'
                          : 'Ajouter ${maxFiles > 1 ? 'des fichiers' : 'un fichier'} supplémentaire${maxFiles > 1 ? 's' : ''}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: selectedFiles.length >= maxFiles 
                        ? AppTheme.textSecondaryColor 
                        : AppTheme.textPrimaryColor,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
        
        // Display selected files
        if (selectedFiles.isNotEmpty) ...[
          const SizedBox(height: AppTheme.spaceSmall),
          ...selectedFiles.asMap().entries.map((entry) {
            final index = entry.key;
            final file = entry.value;
            return Container(
              margin: const EdgeInsets.only(bottom: AppTheme.spaceXSmall),
              padding: const EdgeInsets.all(AppTheme.spaceSmall),
              decoration: BoxDecoration(
                color: AppTheme.grey200,
                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                border: Border.all(color: AppTheme.grey400),
              ),
              child: Row(
                children: [
                  Icon(
                    _getFileIcon(file.extension ?? ''),
                    size: 20,
                    color: AppTheme.primaryColor,
                  ),
                  const SizedBox(width: AppTheme.spaceSmall),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          file.name,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          _formatFileSize(file.size),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.textSecondaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => _removeFile(field, index),
                    icon: const Icon(Icons.close, size: 18),
                    color: AppTheme.errorColor,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
        
        // File constraints info
        Padding(
          padding: const EdgeInsets.only(top: AppTheme.spaceXSmall),
          child: Text(
            _buildFileConstraintsText(maxFiles, allowedTypes, maxSizeMB),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.textSecondaryColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSignatureInput(CustomFormField field) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        border: Border.all(
          color: AppTheme.grey500,
          style: BorderStyle.solid,
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        color: AppTheme.white100,
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.edit,
              size: 48,
              color: AppTheme.textTertiaryColor,
            ),
            const SizedBox(height: AppTheme.spaceSmall),
            Text(
              'Zone de signature',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondaryColor,
              ),
            ),
            const SizedBox(height: AppTheme.spaceXSmall),
            Text(
              'Fonctionnalité en développement',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.textTertiaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  TextInputType _getKeyboardType(String type) {
    switch (type) {
      case 'email':
        return TextInputType.emailAddress;
      case 'phone':
        return TextInputType.phone;
      case 'number':
        return TextInputType.number;
      default:
        return TextInputType.text;
    }
  }

  List<TextInputFormatter>? _getInputFormatters(String type) {
    switch (type) {
      case 'phone':
        return [FilteringTextInputFormatter.digitsOnly];
      default:
        return null;
    }
  }

  // File management methods
  Future<void> _pickFiles(CustomFormField field) async {
    try {
      final maxFiles = field.validation['maxFiles'] ?? 1;
      final allowedTypes = field.validation['allowedTypes'] as List<String>? ?? ['*'];
      final maxSizeMB = field.validation['maxSize'] ?? 10;
      final currentFiles = _selectedFiles[field.id] ?? [];
      
      if (currentFiles.length >= maxFiles) {
        _showSnackBar('Nombre maximum de fichiers atteint (${maxFiles})');
        return;
      }
      
      // Determine file type from allowed types
      FileType fileType = FileType.any;
      List<String>? allowedExtensions;
      
      if (allowedTypes.contains('image/*')) {
        fileType = FileType.image;
      } else if (allowedTypes.contains('application/pdf')) {
        fileType = FileType.custom;
        allowedExtensions = ['pdf'];
      } else if (!allowedTypes.contains('*')) {
        fileType = FileType.custom;
        allowedExtensions = allowedTypes
            .where((type) => !type.contains('/'))
            .map((type) => type.replaceAll('.', ''))
            .toList();
      }
      
      final result = await FilePicker.platform.pickFiles(
        type: fileType,
        allowedExtensions: allowedExtensions,
        allowMultiple: maxFiles > 1,
        withData: true,
      );
      
      if (result != null && result.files.isNotEmpty) {
        final newFiles = <PlatformFile>[];
        
        for (final file in result.files) {
          // Check file size
          if (file.size > maxSizeMB * 1024 * 1024) {
            _showSnackBar('Le fichier ${file.name} dépasse la taille maximum de ${maxSizeMB}MB');
            continue;
          }
          
          // Check if we still have space
          if (currentFiles.length + newFiles.length >= maxFiles) {
            _showSnackBar('Nombre maximum de fichiers atteint');
            break;
          }
          
          newFiles.add(file);
        }
        
        if (newFiles.isNotEmpty) {
          setState(() {
            _selectedFiles[field.id] = [...currentFiles, ...newFiles];
            _responses[field.id] = _selectedFiles[field.id];
          });
        }
      }
    } catch (e) {
      _showSnackBar('Erreur lors de la sélection du fichier: $e');
    }
  }
  
  void _removeFile(CustomFormField field, int index) {
    setState(() {
      final files = _selectedFiles[field.id] ?? [];
      if (index >= 0 && index < files.length) {
        files.removeAt(index);
        _selectedFiles[field.id] = files;
        _responses[field.id] = files.isEmpty ? null : files;
      }
    });
  }
  
  IconData _getFileIcon(String extension) {
    switch (extension.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'bmp':
        return Icons.image;
      case 'mp4':
      case 'avi':
      case 'mov':
        return Icons.video_file;
      case 'mp3':
      case 'wav':
      case 'aac':
        return Icons.audio_file;
      case 'zip':
      case 'rar':
      case '7z':
        return Icons.archive;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart;
      case 'ppt':
      case 'pptx':
        return Icons.slideshow;
      case 'txt':
        return Icons.text_snippet;
      default:
        return Icons.insert_drive_file;
    }
  }
  
  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '${bytes} B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
  
  String _buildFileConstraintsText(int maxFiles, List<String> allowedTypes, int maxSizeMB) {
    final constraints = <String>[];
    
    if (maxFiles > 1) {
      constraints.add('Maximum ${maxFiles} fichiers');
    }
    
    if (!allowedTypes.contains('*')) {
      if (allowedTypes.contains('image/*')) {
        constraints.add('Images uniquement');
      } else if (allowedTypes.contains('application/pdf')) {
        constraints.add('PDF uniquement');
      } else {
        final extensions = allowedTypes.where((type) => !type.contains('/')).join(', ');
        if (extensions.isNotEmpty) {
          constraints.add('Formats: $extensions');
        }
      }
    }
    
    constraints.add('Taille max: ${maxSizeMB}MB');
    
    return constraints.join(' • ');
  }
  
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.errorColor,
      ),
    );
  }

  String? _validateField(CustomFormField field, dynamic value) {
    if (field.isRequired && (value == null || value.toString().isEmpty)) {
      return 'Ce champ est obligatoire';
    }

    switch (field.type) {
      case 'email':
        if (value != null && value.toString().isNotEmpty) {
          final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
          if (!emailRegex.hasMatch(value.toString())) {
            return 'Email invalide';
          }
        }
        break;
      case 'phone':
        if (value != null && value.toString().isNotEmpty) {
          if (value.toString().length < 10) {
            return 'Numéro de téléphone invalide';
          }
        }
        break;
    }

    // Apply validation rules
    if (field.validation.isNotEmpty && value != null && value.toString().isNotEmpty) {
      final minLength = field.validation['minLength'];
      final maxLength = field.validation['maxLength'];
      
      if (minLength != null && value.toString().length < minLength) {
        return 'Minimum $minLength caractères requis';
      }
      
      if (maxLength != null && value.toString().length > maxLength) {
        return 'Maximum $maxLength caractères autorisés';
      }
    }

    return null;
  }
}