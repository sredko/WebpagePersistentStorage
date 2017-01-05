Pod::Spec.new do |s|
  s.name = 'WebpagePersistentStorage'
  s.version = '0.0.1'
  s.license = ''
  s.summary = 'Webpage persistent storage SDK for iOS'
  s.homepage = 'https://github.com/sredko/WebpagePersistentStorage'
  s.authors = { 'Serhiy Redko' => 'serhiy.redko@gmail.com' }
  s.source = { :git => 'https://github.com/sredko/WebpagePersistentStorage.git', :tag => s.version }
  s.ios.deployment_target = '9.0'
  s.requires_arc = true

  s.source_files = 'WebpagePersistentStorage/Source/**/*.{h,swift}'
  s.preserve_paths = 'Modules/libxml2/*', 'Modules/CommonCrypto/*'
  
  s.xcconfig = {
    'SWIFT_INCLUDE_PATHS[sdk=iphoneos*]' => '$(SRCROOT)/WebpagePersistentStorage/Modules/libxml2/iphoneos $(SRCROOT)/WebpagePersistentStorage/Modules/CommonCrypto/iphoneos',
    'SWIFT_INCLUDE_PATHS[sdk=iphonesimulator*]' => '$(SRCROOT)/WebpagePersistentStorage/Modules/libxml2/iphonesimulator $(SRCROOT)/WebpagePersistentStorage/Modules/CommonCrypto/iphonesimulator',
    'HEADER_SEARCH_PATHS' => '$(SDKROOT)/usr/include/libxml2',
	'OTHER_LDFLAGS' => '-lxml2'
   }
end
