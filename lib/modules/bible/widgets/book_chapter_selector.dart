import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../theme.dart';
import '../models/bible_book.dart';

class BookChapterSelector extends StatefulWidget {
  final List<BibleBook> books;
  final String? selectedBook;
  final int? selectedChapter;
  final Function(String book, int chapter) onBookChapterSelected;

  const BookChapterSelector({
    Key? key,
    required this.books,
    this.selectedBook,
    this.selectedChapter,
    required this.onBookChapterSelected,
  }) : super(key: key);

  @override
  State<BookChapterSelector> createState() => _BookChapterSelectorState();
}

class _BookChapterSelectorState extends State<BookChapterSelector>
    with TickerProviderStateMixin {
  late TabController _testamentTabController;
  String? _selectedBook;
  int? _selectedChapter;
  
  @override
  void initState() {
    super.initState();
    _testamentTabController = TabController(length: 2, vsync: this);
    _selectedBook = widget.selectedBook;
    _selectedChapter = widget.selectedChapter;
  }

  @override
  void dispose() {
    _testamentTabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: AppTheme.white100,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Poignée de glissement
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            height: 4,
            width: 40,
            decoration: BoxDecoration(
              color: AppTheme.grey300,
              borderRadius: BorderRadius.circular(AppTheme.radius2),
            ),
          ),
          
          // En-tête
          Padding(
            padding: const EdgeInsets.all(AppTheme.spaceMedium),
            child: Row(
              children: [
                Text(
                  'Sélectionner un passage',
                  style: GoogleFonts.inter(
                    fontSize: AppTheme.fontSize20,
                    fontWeight: AppTheme.fontBold,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          
          // Sélection actuelle
          if (_selectedBook != null)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(AppTheme.space12),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                border: Border.all(
                  color: AppTheme.primaryColor.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.bookmark,
                    color: AppTheme.primaryColor,
                    size: 20,
                  ),
                  const SizedBox(width: AppTheme.spaceSmall),
                  Text(
                    '$_selectedBook${_selectedChapter != null ? ' $_selectedChapter' : ''}',
                    style: GoogleFonts.inter(
                      fontWeight: AppTheme.fontSemiBold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const Spacer(),
                  if (_selectedBook != null && _selectedChapter != null)
                    ElevatedButton(
                      onPressed: () {
                        widget.onBookChapterSelected(_selectedBook!, _selectedChapter!);
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: AppTheme.white100,
                        minimumSize: const Size(80, 32),
                      ),
                      child: const Text('Aller'),
                    ),
                ],
              ),
            ),
          
          const SizedBox(height: AppTheme.spaceMedium),
          
          // Onglets Testament
          Container(
            color: AppTheme.primaryColor, // Couleur primaire cohérente
            child: TabBar(
              controller: _testamentTabController,
              labelColor: AppTheme.onPrimaryColor, // Texte blanc
              unselectedLabelColor: AppTheme.onPrimaryColor.withOpacity(0.7), // Texte blanc semi-transparent
              indicatorColor: AppTheme.onPrimaryColor, // Indicateur blanc
            tabs: const [
              Tab(text: 'Ancien Testament'),
              Tab(text: 'Nouveau Testament'),
            ],
          ),
          ),
          
          // Contenu des onglets
          Expanded(
            child: TabBarView(
              controller: _testamentTabController,
              children: [
                _buildTestamentBooks('old'),
                _buildTestamentBooks('new'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTestamentBooks(String testament) {
    final books = widget.books.where((book) => book.testament == testament).toList();
    
    return ListView.builder(
      padding: const EdgeInsets.all(AppTheme.spaceMedium),
      itemCount: books.length,
      itemBuilder: (context, index) {
        final book = books[index];
        final isSelected = _selectedBook == book.name;
        
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          elevation: isSelected ? 4 : 1,
          color: isSelected ? AppTheme.primaryColor.withOpacity(0.1) : null,
          child: ExpansionTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isSelected 
                    ? AppTheme.primaryColor 
                    : AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
              ),
              child: Center(
                child: Text(
                  book.abbreviation,
                  style: GoogleFonts.inter(
                    fontSize: AppTheme.fontSize12,
                    fontWeight: AppTheme.fontBold,
                    color: isSelected ? AppTheme.white100 : AppTheme.primaryColor,
                  ),
                ),
              ),
            ),
            title: Text(
              book.name,
              style: GoogleFonts.inter(
                fontWeight: AppTheme.fontSemiBold,
                color: isSelected ? AppTheme.primaryColor : AppTheme.black100.withOpacity(0.87),
              ),
            ),
            subtitle: Text(
              '${book.totalChapters} chapitres',
              style: GoogleFonts.inter(
                fontSize: AppTheme.fontSize12,
                color: AppTheme.grey600,
              ),
            ),
            onExpansionChanged: (expanded) {
              if (expanded) {
                setState(() {
                  _selectedBook = book.name;
                  _selectedChapter = null;
                });
              }
            },
            children: [
              Container(
                padding: const EdgeInsets.all(AppTheme.spaceMedium),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sélectionner un chapitre:',
                      style: GoogleFonts.inter(
                        fontWeight: AppTheme.fontMedium,
                        color: AppTheme.grey700,
                      ),
                    ),
                    const SizedBox(height: AppTheme.space12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: List.generate(book.totalChapters, (chapterIndex) {
                        final chapterNumber = chapterIndex + 1;
                        final isChapterSelected = _selectedChapter == chapterNumber && 
                                                _selectedBook == book.name;
                        
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedBook = book.name;
                              _selectedChapter = chapterNumber;
                            });
                          },
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: isChapterSelected 
                                  ? AppTheme.primaryColor 
                                  : AppTheme.grey100,
                              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                              border: Border.all(
                                color: isChapterSelected 
                                    ? AppTheme.primaryColor 
                                    : AppTheme.grey300,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                '$chapterNumber',
                                style: GoogleFonts.inter(
                                  fontWeight: AppTheme.fontSemiBold,
                                  color: isChapterSelected 
                                      ? AppTheme.white100 
                                      : AppTheme.black100.withOpacity(0.87),
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
