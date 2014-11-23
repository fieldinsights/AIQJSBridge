Pod::Spec.new do |s|
  s.name             = "AIQCoreLib-RACExtensions"
  s.version          = "0.0.1"
  s.summary          = "A short description of AIQCoreLib-RACExtensions."
  s.homepage         = "https://github.com/appear/AIQCoreLib-RACExtensions"
  s.license          = 'MIT'
  s.author           = { "Appear Networks AB" => "ios@appearnetworks.com" }
  s.source           = { :git => "https://github.com/appear/AIQCoreLib-RACExtensions.git", :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/appear'

  s.platform     = :ios, '7.0'
  s.requires_arc = true

  s.source_files = 'Pod/Classes'

  s.public_header_files = 'Pod/Classes/AIQ*.h'
  s.dependency 'AIQCoreLib'
  s.dependency 'ReactiveCocoa'
end
