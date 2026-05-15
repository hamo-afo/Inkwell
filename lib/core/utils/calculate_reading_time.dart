int calculateReadingTime(String content) {
  final wordCount = content.split(RegExp(r'\s+')).length;
  final readingTime =  wordCount / 225; // Assuming an average reading speed of 200 words per minute
  return readingTime.ceil();
}
