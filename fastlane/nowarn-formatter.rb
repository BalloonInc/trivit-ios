class NoWarnFormatter < XCPretty::Simple
  def format_compile_warning(file, file_path, reason, line, cursor) EMPTY; end    
  def format_ld_warning(message);                                   EMPTY; end
  def format_compile(file_name, file_path);                         EMPTY; end
  def format_copy_header_file(source, target);                      EMPTY; end
  def format_copy_plist_file(source, target);                       EMPTY; end
  def format_copy_strings_file(file_name);                          EMPTY; end
end
NoWarnFormatter