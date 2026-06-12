import 'abstract_html_ripper.dart';

abstract class AbstractSingleFileRipper extends AbstractHTMLRipper {
  AbstractSingleFileRipper(super.url);

  @override
  bool get usesByteProgress => true;
}
