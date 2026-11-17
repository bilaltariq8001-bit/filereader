import 'constant.dart';

String getIconForFile(String filePath) {
  if (filePath.toLowerCase().endsWith(Constants.pdf)) {
    return "assets/image/pdf.png";
  } else if (filePath.toLowerCase().endsWith(Constants.doc) || filePath.toLowerCase().endsWith(Constants.docx)) {
    return 'assets/image/words.png';
  } else if (filePath.toLowerCase().endsWith(Constants.xlsx) || filePath.toLowerCase().endsWith(Constants.xls)) {
    return 'assets/image/excel.png';
  } else if (filePath.toLowerCase().endsWith(Constants.ppt) || filePath.toLowerCase().endsWith(Constants.pptx)) {
    return 'assets/image/ppt.png';
  } else {
    return 'assets/default.svg'; // Default icon if the file type isn't recognized
  }
}