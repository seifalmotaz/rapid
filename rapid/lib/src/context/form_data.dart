library rapid.context.filepart;

/// presenting file data and bytes stream
class FilePart {
  /// name of the field
  final String name;

  /// name of the file
  final String filename;

  /// streamed bytes of the files
  final Stream<List<int>> bytes;

  /// presenting file data and bytes stream
  FilePart(this.name, this.filename, this.bytes);
}

class BodyForm {
  /// form fields as a list of string value for multiple value field
  final Map<String, List<String>> formFields;

  /// form fields as a list of [FilePart] value for multiple value field
  final Map<String, List<FilePart>> formFiles;

  /// get data from [formFields] or [formFiles] variables with the field name [i]
  List? operator [](String i) => formFields[i] ?? formFiles[i];

  /// get single value from [formFiles] with the field name [i]
  FilePart? file(String i) => formFiles[i]?.first;

  /// init new content
  BodyForm(this.formFields, this.formFiles);
}
