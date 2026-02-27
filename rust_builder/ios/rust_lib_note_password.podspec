Pod::Spec.new do |s|
  s.name             = 'rust_lib_note_password'
  s.version          = '0.0.1'
  s.summary          = 'Rust library for NotePassword'
  s.homepage         = 'https://github.com/hardydou/note-password'
  s.license          = { :file => 'LICENSE' }
  s.author           = { 'hardydou' => 'hardydou@example.com' }
  s.source           = { :path => '.' }
  s.source_files     = 'Classes/**/*'
  s.platform         = :ios, '11.0'
end
