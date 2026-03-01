Pod::Spec.new do |s|
  s.name             = 'flutter_live_location'
  s.version          = '0.0.1'
  s.summary          = 'A Flutter plugin for real-time location tracking.'
  s.description      = <<-DESC
A Flutter plugin for real-time location tracking with configurable distance filters
and time intervals, supporting both foreground and background tracking on Android and iOS.
                       DESC
  s.homepage         = 'https://github.com/VigneshJagannadhan/flutter_live_location'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Vignesh Jagannadhan' => 'vignesh@stunntech.com' }
  s.source           = { :path => '.' }
  s.public_header_files = 'Classes/**/*.h'
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '11.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'
end
