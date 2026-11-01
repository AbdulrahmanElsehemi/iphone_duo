#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint iphone_duo.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'iphone_duo'
  s.version          = '0.6.0'
  s.summary          = 'The iPhone Duo hinge, fold and status bar column, for iphone_duo.'
  s.description      = <<-DESC
The iPhone Duo hinge, fold and status bar column, for iphone_duo.
                       DESC
  s.homepage         = 'https://github.com/AbdulrahmanElsehemi/iphone_duo'
  s.license          = { :file => '../LICENSE' }
  s.author           = 'Abdulrahman Elsehemy'
  s.source           = { :path => '.' }
  s.source_files = 'iphone_duo/Sources/iphone_duo/**/*.swift'
  s.dependency 'Flutter'
  s.platform = :ios, '15.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'

  # It declares nothing: the plugin tracks nothing, collects nothing, and
  # calls none of the APIs Apple asks reasons for.
  s.resource_bundles = {'iphone_duo_privacy' => ['iphone_duo/Sources/iphone_duo/PrivacyInfo.xcprivacy']}
end
