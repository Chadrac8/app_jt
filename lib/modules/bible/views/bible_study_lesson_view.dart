import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/bible_study.dart';
import '../services/bible_study_service.dart';
import '../../../../theme.dart';
import '../../../theme.dart';

class BibleStudyLessonView extends StatefulWidget {
  final BibleStudy study;
  final BibleStudyLesson lesson;
  final int lessonIndex;

  const BibleStudyLessonView({
    Key? key,
    required this.study,
    required this.lesson,
    required this.lessonIndex,
  }) : super(key: key);

  @override
  State<BibleStudyLessonView> createState() => _BibleStudyLessonViewState();
}

class _BibleStudyLessonViewState extends State<BibleStudyLessonView> {
  bool _isLoading = false;
  List<bool> _answeredQuestions = [];
  Map<String, String> _questionAnswers = {};
  bool _isLessonCompleted = false;

  @override
  void initState() {
    super.initState();
    _loadProgress();
    _initializeQuestions();
  }

  void _initializeQuestions() {
    _answeredQuestions = List.filled(widget.lesson.questions.length, false);
  }

  Future<void> _loadProgress() async {
    setState(() => _isLoading = true);
    try {
      final progress = await BibleStudyService.getStudyProgress(widget.study.id);
      setState(() {
        _isLessonCompleted = progress?.completedLessons.contains(widget.lesson.id) ?? false;
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _markLessonComplete() async {
    setState(() => _isLoading = true);
    try {
      await BibleStudyService.markLessonComplete(
        widget.study.id,
        widget.lesson.id,
      );
      setState(() => _isLessonCompleted = true);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Leçon terminée avec succès !'),
          backgroundColor: AppTheme.greenStandard,
        ),
      );

      // Naviguer vers la prochaine leçon si elle existe
      if (widget.lessonIndex < widget.study.lessons.length - 1) {
        _showNextLessonDialog();
      } else {
        _showStudyCompletedDialog();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: AppTheme.redStandard,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showNextLessonDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Félicitations !'),
        content: const Text('Vous avez terminé cette leçon. Voulez-vous passer à la suivante ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Plus tard'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _navigateToNextLesson();
            },
            child: const Text('Continuer'),
          ),
        ],
      ),
    );
  }

  void _showStudyCompletedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Étude terminée !'),
        content: const Text('Félicitations ! Vous avez terminé toute l\'étude biblique.'),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Retour'),
          ),
        ],
      ),
    );
  }

  void _navigateToNextLesson() {
    final nextLesson = widget.study.lessons[widget.lessonIndex + 1];
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => BibleStudyLessonView(
          study: widget.study,
          lesson: nextLesson,
          lessonIndex: widget.lessonIndex + 1,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(theme),
          SliverToBoxAdapter(
            child: _buildContent(theme),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(theme),
    );
  }

  Widget _buildAppBar(ThemeData theme) {
    return SliverAppBar(
      expandedHeight: 200,
      floating: false,
      pinned: true,
      backgroundColor: theme.colorScheme.primary,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          widget.lesson.title,
          style: GoogleFonts.inter(
            fontSize: AppTheme.fontSize16,
            fontWeight: AppTheme.fontSemiBold,
            color: AppTheme.white100,
          ),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                theme.colorScheme.primary,
                theme.colorScheme.primary.withOpacity(0.8),
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.spaceMedium),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Spacer(),
                  Text(
                    'Leçon ${widget.lessonIndex + 1} sur ${widget.study.lessons.length}',
                    style: GoogleFonts.inter(
                      fontSize: AppTheme.fontSize14,
                      color: AppTheme.white100.withOpacity(0.9),
                    ),
                  ),
                  const SizedBox(height: AppTheme.spaceSmall),
                  LinearProgressIndicator(
                    value: (widget.lessonIndex + 1) / widget.study.lessons.length,
                    backgroundColor: AppTheme.white100.withOpacity(0.3),
                    valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.white100),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      actions: [
        if (_isLessonCompleted)
          const Padding(
            padding: EdgeInsets.all(AppTheme.spaceSmall),
            child: Icon(
              Icons.check_circle,
              color: AppTheme.greenStandard,
            ),
          ),
      ],
    );
  }

  Widget _buildContent(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(AppTheme.spaceMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Objectifs de la leçon
          if (widget.lesson.objectives.isNotEmpty) ...[
            Text(
              'Objectifs de la leçon',
              style: GoogleFonts.inter(
                fontSize: AppTheme.fontSize18,
                fontWeight: AppTheme.fontSemiBold,
                color: theme.colorScheme.onBackground,
              ),
            ),
            const SizedBox(height: AppTheme.space12),
            ...widget.lesson.objectives.map((objective) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 20,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: AppTheme.spaceSmall),
                  Expanded(
                    child: Text(
                      objective,
                      style: GoogleFonts.inter(
                        fontSize: AppTheme.fontSize14,
                        color: theme.colorScheme.onBackground.withOpacity(0.8),
                      ),
                    ),
                  ),
                ],
              ),
            )),
            const SizedBox(height: AppTheme.spaceLarge),
          ],

          // Contenu de la leçon
          Text(
            'Contenu',
            style: GoogleFonts.inter(
              fontSize: AppTheme.fontSize18,
              fontWeight: AppTheme.fontSemiBold,
              color: theme.colorScheme.onBackground,
            ),
          ),
          const SizedBox(height: AppTheme.space12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppTheme.spaceMedium),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              border: Border.all(
                color: theme.colorScheme.outline.withOpacity(0.2),
              ),
            ),
            child: Text(
              widget.lesson.content,
              style: GoogleFonts.inter(
                fontSize: AppTheme.fontSize15,
                height: 1.6,
                color: theme.colorScheme.onBackground,
              ),
            ),
          ),
          const SizedBox(height: AppTheme.spaceLarge),

          // Références bibliques
          if (widget.lesson.bibleReferences.isNotEmpty) ...[
            Text(
              'Références bibliques',
              style: GoogleFonts.inter(
                fontSize: AppTheme.fontSize18,
                fontWeight: AppTheme.fontSemiBold,
                color: theme.colorScheme.onBackground,
              ),
            ),
            const SizedBox(height: AppTheme.space12),
            ...widget.lesson.bibleReferences.map((ref) => Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(AppTheme.spaceMedium),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                border: Border.all(
                  color: theme.colorScheme.primary.withOpacity(0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ref.reference,
                    style: GoogleFonts.inter(
                      fontSize: AppTheme.fontSize16,
                      fontWeight: AppTheme.fontSemiBold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spaceSmall),
                  Text(
                    ref.text,
                    style: GoogleFonts.inter(
                      fontSize: AppTheme.fontSize14,
                      fontStyle: FontStyle.italic,
                      color: theme.colorScheme.onBackground.withOpacity(0.8),
                    ),
                  ),
                  if (ref.commentary.isNotEmpty) ...[
                    const SizedBox(height: AppTheme.spaceSmall),
                    Text(
                      ref.commentary,
                      style: GoogleFonts.inter(
                        fontSize: AppTheme.fontSize14,
                        color: theme.colorScheme.onBackground.withOpacity(0.7),
                      ),
                    ),
                  ],
                ],
              ),
            )),
            const SizedBox(height: AppTheme.spaceLarge),
          ],

          // Questions de réflexion
          if (widget.lesson.questions.isNotEmpty) ...[
            Text(
              'Questions de réflexion',
              style: GoogleFonts.inter(
                fontSize: AppTheme.fontSize18,
                fontWeight: AppTheme.fontSemiBold,
                color: theme.colorScheme.onBackground,
              ),
            ),
            const SizedBox(height: AppTheme.space12),
            ...widget.lesson.questions.asMap().entries.map((entry) {
              final index = entry.key;
              final question = entry.value;
              return Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(AppTheme.spaceMedium),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  border: Border.all(
                    color: theme.colorScheme.outline.withOpacity(0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                          ),
                          child: Center(
                            child: Text(
                              '${index + 1}',
                              style: GoogleFonts.inter(
                                fontSize: AppTheme.fontSize12,
                                fontWeight: AppTheme.fontSemiBold,
                                color: AppTheme.white100,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppTheme.space12),
                        Expanded(
                          child: Text(
                            question.question,
                            style: GoogleFonts.inter(
                              fontSize: AppTheme.fontSize15,
                              fontWeight: AppTheme.fontMedium,
                              color: theme.colorScheme.onBackground,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (question.type == 'reflection') ...[
                      const SizedBox(height: AppTheme.space12),
                      TextField(
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText: 'Votre réflexion...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                          ),
                          contentPadding: const EdgeInsets.all(AppTheme.space12),
                        ),
                        onChanged: (value) {
                          _questionAnswers[question.id] = value;
                          setState(() {
                            _answeredQuestions[index] = value.isNotEmpty;
                          });
                        },
                      ),
                    ],
                    if (question.hints.isNotEmpty) ...[
                      const SizedBox(height: AppTheme.space12),
                      ExpansionTile(
                        title: Text(
                          'Aide',
                          style: GoogleFonts.inter(
                            fontSize: AppTheme.fontSize14,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        children: question.hints.map((hint) => Padding(
                          padding: const EdgeInsets.all(AppTheme.spaceSmall),
                          child: Text(
                            '• $hint',
                            style: GoogleFonts.inter(
                              fontSize: AppTheme.fontSize13,
                              color: theme.colorScheme.onBackground.withOpacity(0.7),
                            ),
                          ),
                        )).toList(),
                      ),
                    ],
                  ],
                ),
              );
            }),
            const SizedBox(height: AppTheme.spaceLarge),
          ],

          // Section de prière/méditation
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppTheme.spaceMedium),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.05),
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              border: Border.all(
                color: theme.colorScheme.primary.withOpacity(0.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.self_improvement,
                      color: theme.colorScheme.primary,
                      size: 20,
                    ),
                    const SizedBox(width: AppTheme.spaceSmall),
                    Text(
                      'Moment de prière et méditation',
                      style: GoogleFonts.inter(
                        fontSize: AppTheme.fontSize16,
                        fontWeight: AppTheme.fontSemiBold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.space12),
                Text(
                  'Prenez quelques minutes pour prier et méditer sur ce que vous avez appris dans cette leçon. Demandez à Dieu de vous aider à appliquer ces vérités dans votre vie quotidienne.',
                  style: GoogleFonts.inter(
                    fontSize: AppTheme.fontSize14,
                    height: 1.5,
                    color: theme.colorScheme.onBackground.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 100), // Espace pour le bottom bar
        ],
      ),
    );
  }

  Widget _buildBottomBar(ThemeData theme) {
    final canComplete = widget.lesson.questions.isEmpty || 
        _answeredQuestions.every((answered) => answered);
    
    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceMedium),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: AppTheme.black100.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Bouton précédent
            if (widget.lessonIndex > 0)
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _navigateToPreviousLesson(),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: BorderSide(color: theme.colorScheme.primary),
                  ),
                  child: Text(
                    'Précédent',
                    style: GoogleFonts.inter(
                      fontWeight: AppTheme.fontSemiBold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
              ),
            if (widget.lessonIndex > 0) const SizedBox(width: AppTheme.space12),
            
            // Bouton principal
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: _isLessonCompleted || !canComplete || _isLoading 
                    ? null 
                    : _markLessonComplete,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isLessonCompleted 
                      ? AppTheme.greenStandard 
                      : theme.colorScheme.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading 
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.white100),
                        ),
                      )
                    : Text(
                        _isLessonCompleted 
                            ? 'Leçon terminée' 
                            : 'Terminer la leçon',
                        style: GoogleFonts.inter(
                          fontWeight: AppTheme.fontSemiBold,
                          color: AppTheme.white100,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToPreviousLesson() {
    final previousLesson = widget.study.lessons[widget.lessonIndex - 1];
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => BibleStudyLessonView(
          study: widget.study,
          lesson: previousLesson,
          lessonIndex: widget.lessonIndex - 1,
        ),
      ),
    );
  }
}
