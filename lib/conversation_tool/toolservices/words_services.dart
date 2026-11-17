import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:xml/xml.dart';

class WordService {
  /// Extract text from DOCX
  static Future<String> extractTextFromDocx(Uint8List bytes) async {
    try {
      final archive = ZipDecoder().decodeBytes(bytes);

      final documentFile = archive.files.firstWhere(
            (file) => file.name == 'word/document.xml',
        orElse: () => throw Exception('document.xml not found'),
      );

      final xmlContent = String.fromCharCodes(documentFile.content as List<int>);
      final document = XmlDocument.parse(xmlContent);
      final paragraphs = <String>[];

      for (final paragraph in document.findAllElements('w:p')) {
        final text = paragraph
            .findAllElements('w:t')
            .map((node) => node.innerText)
            .join()
            .trim();

        if (text.isEmpty) {
          paragraphs.add('');
          continue;
        }

        String? paragraphStyle;
        for (final styleNode in paragraph.findAllElements('w:pStyle')) {
          paragraphStyle = styleNode.getAttribute('w:val') ??
              styleNode.getAttribute('val');
          break;
        }

        if (paragraphStyle == null) {
          paragraphs.add(text);
          continue;
        }

        if (paragraphStyle.startsWith('Heading1') ||
            paragraphStyle.startsWith('Title')) {
          paragraphs.add('# $text');
        } else if (paragraphStyle.startsWith('Heading2')) {
          paragraphs.add('## $text');
        } else if (paragraphStyle.startsWith('Heading3')) {
          paragraphs.add('### $text');
        } else {
          paragraphs.add(text);
        }
      }

      final extractedText = paragraphs.join('\n').trim();

      return extractedText.isNotEmpty
          ? extractedText
          : 'No text found in document';
    } catch (e) {
      throw Exception('Failed to extract text: $e');
    }
  }

  /// Create VALID DOCX from text
  static Future<Uint8List> createDocxFromText(String text) async {
    try {
      final archive = Archive();

      void add(String path, String content) {
        archive.addFile(ArchiveFile(path, content.length, content.codeUnits));
      }

      add('[Content_Types].xml', _contentTypes());
      add('_rels/.rels', _rels());
      add('docProps/core.xml', _coreXml());
      add('docProps/app.xml', _appXml());
      add('word/document.xml', _documentXml(text));
      add('word/styles.xml', _stylesXml());
      add('word/_rels/document.xml.rels', _documentRels());

      final zipData = ZipEncoder().encode(archive);
      return Uint8List.fromList(zipData!);
    } catch (e) {
      throw Exception('Failed to create DOCX: $e');
    }
  }

  static String _contentTypes() => '''<?xml version="1.0" encoding="UTF-8"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
  <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
  <Default Extension="xml" ContentType="application/xml"/>
  <Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/>
  <Override PartName="/word/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.styles+xml"/>
  <Override PartName="/docProps/core.xml" ContentType="application/vnd.openxmlformats-package.core-properties+xml"/>
  <Override PartName="/docProps/app.xml" ContentType="application/vnd.openxmlformats-officedocument.extended-properties+xml"/>
</Types>''';

  static String _rels() => '''<?xml version="1.0" encoding="UTF-8"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/>
  <Relationship Id="rId2" Type="http://schemas.openxmlformats.org/package/2006/relationships/metadata/core-properties" Target="docProps/core.xml"/>
  <Relationship Id="rId3" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/extended-properties" Target="docProps/app.xml"/>
</Relationships>''';

  static String _documentRels() => '''<?xml version="1.0" encoding="UTF-8"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"/>''';

  static String _stylesXml() => '''<?xml version="1.0" encoding="UTF-8"?>
<w:styles xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
  <w:style w:type="paragraph" w:default="1" w:styleId="Normal">
    <w:name w:val="Normal"/>
    <w:qFormat/>
  </w:style>
</w:styles>''';

  static String _coreXml() => '''<?xml version="1.0" encoding="UTF-8"?>
<cp:coreProperties xmlns:cp="http://schemas.openxmlformats.org/package/2006/metadata/core-properties"
 xmlns:dc="http://purl.org/dc/elements/1.1/">
  <dc:title>Generated Document</dc:title>
  <dc:creator>Flutter App</dc:creator>
</cp:coreProperties>''';

  static String _appXml() => '''<?xml version="1.0" encoding="UTF-8"?>
<Properties xmlns="http://schemas.openxmlformats.org/officeDocument/2006/extended-properties">
  <Application>Flutter</Application>
</Properties>''';

  static String _documentXml(String text) {
    final escaped = _escapeXml(text);

    final paragraphs = escaped.split('\n').map((line) {
      return '''
<w:p>
  <w:r>
    <w:t xml:space="preserve">${line.isEmpty ? ' ' : line}</w:t>
  </w:r>
</w:p>''';
    }).join();

    return '''<?xml version="1.0" encoding="UTF-8"?>
<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
  <w:body>
    $paragraphs
    <w:sectPr/>
  </w:body>
</w:document>''';
  }

  static String _escapeXml(String text) {
    return text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');
  }
}
