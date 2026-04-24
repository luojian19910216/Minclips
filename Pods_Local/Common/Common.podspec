#
# Be sure to run `pod lib lint Common.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  #
  s.name = 'Common'
  #
  s.version = '1.0.0'
  #
  s.summary = '通用'
  #
  s.description = <<-DESC
  TODO: Add long description of the pod here.
  DESC
  #
  s.authors = { 'XXX' => '' }
  #
  s.license = { :type => 'MIT', :file => 'LICENSE' }
  #
  s.homepage = 'XXX'
  #
  s.source = { :git => 'XXX', :tag => s.version.to_s }
  #
  s.ios.deployment_target = '15.0'
  #
  s.source_files = 'Common/Classes/**/*'
  #
  s.dependency 'Data'
  s.dependency 'SnapKit'
end
