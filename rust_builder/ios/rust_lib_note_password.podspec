Pod::Spec.new do |s|
  s.name             = 'rust_lib_note_password'
  s.version          = '0.0.1'
  s.summary          = 'Rust library for NotePassword'
  s.homepage         = 'https://github.com/hardydou/note-password'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'hardydou' => 'hardydou@example.com' }
  s.source           = { :path => '.' }
  s.source_files     = 'Classes/**/*'
  s.platform         = :ios, '11.0'
  s.library          = 'rust_lib_note_password'
  
  s.pod_target_xcconfig = {
    'DEFINES_MODULE' => 'YES',
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386'
  }
  
  s.script_phase = {
    :name => 'Build Rust library',
    :script => '
      echo "Using pre-built Rust library"
      RUST_DIR="${PODS_ROOT}/../../rust"
      BUILD_DIR="${BUILT_PRODUCTS_DIR}"
      PLATFORM_NAME="${EFFECTIVE_PLATFORM_NAME}"
      
      if [[ "$PLATFORM_NAME" == *"simulator"* ]]; then
        LIB_NAME="librust_lib_note_password-sim.a"
        SRC="${RUST_DIR}/target/x86_64-apple-ios/debug/librust_lib_note_password.a"
      else
        LIB_NAME="librust_lib_note_password.a"
        SRC="${RUST_DIR}/target/aarch64-apple-ios/debug/librust_lib_note_password.a"
      fi
      
      if [ -f "$SRC" ]; then
        mkdir -p "${BUILD_DIR}"
        cp "$SRC" "${BUILD_DIR}/${LIB_NAME}"
        echo "Copied Rust library to ${BUILD_DIR}/${LIB_NAME}"
      else
        echo "Warning: Rust library not found at ${SRC}"
      fi
    ',
    :execution_position => :before_compile,
    :input_files => [],
    :output_files => []
  }
end
