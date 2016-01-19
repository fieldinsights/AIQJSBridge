Pod::Spec.new do |s|
  s.name             = "AIQJSBridge"
  s.version          = "1.0.1"
  s.summary          = "Provides JavaScript access to AppearIQ cloud services."
  s.homepage         = "https://github.com/appear/AIQJSBridge"
  s.license          = 'MIT'
  s.author           = { "Appear Networks AB" => "ios@appearnetworks.com" }
  s.source           = { :git => "https://github.com/appear/AIQJSBridge.git", :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/appear'

  s.platform     = :ios, '8.0'
  s.requires_arc = true

  s.source_files = 'Pod/Classes/**/*'
  s.resource_bundles = {
    'AIQJSBridge' => ['Pod/Assets/*']
  }

  s.public_header_files = 'Pod/Classes/**/AIQ*.h'
  s.dependency 'AIQCoreLib', '1.5.0'
  s.dependency 'Google/Analytics', '1.1.0'

  s.subspec 'Cordova' do |ss|
    ss.source_files = 'Cordova/Classes/**/*'
    ss.public_header_files = 'Cordova/Classes/**/CDV*.h', 'Cordova/Classes/**/NS*.h', 'Cordova/Classes/**/UI*.h'
    ss.header_dir = 'Cordova'
    ss.header_mappings_dir = 'Cordova/Classes'
  end
end
