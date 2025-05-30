class Book {
  final String title;
  final String author;
  final String chapter;
  final String date;
  final int views;
  final int favorites;
  final String content; // 新增：章節內容

  Book(this.title, this.author, this.chapter, this.date, this.views, this.favorites, this.content);
}
