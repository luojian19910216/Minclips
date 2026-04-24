#
install! 'cocoapods', :warn_for_unused_master_specs_repo => false
#
source 'https://cdn.cocoapods.org/'
#
platform :ios, '15.0'
#
use_frameworks!
#
inhibit_all_warnings!
#
def commonPods
  #
  pod 'Data', :path => './Pods_Local/Data'
  #
  pod 'Common', :path => './Pods_Local/Common'
  #
  pod 'FDFullscreenPopGesture'
  #
  pod 'PanModal'
  #
  pod 'CTMediator'
  #
  pod 'CombineExt'
  pod 'CombineCocoa'
  #
  pod 'SnapKit'
  #
  pod 'SDWebImage'
  pod 'SDWebImageWebPCoder'
  #
  pod 'IQKeyboardManager'
  #
  pod 'SkeletonView'
  #
  pod 'MBProgressHUD'
  #
  pod 'FSPagerView'
  #
  pod 'JXPagingView/Paging'
  #
  pod 'MJRefresh'
  #
  pod 'KTVHTTPCache'
  #
  pod 'AliyunOSSiOS'
end
#
def toolPods
  #
  pod 'FLEX'
end
# 
targets = ['Minclips_D', 'Minclips_T', 'Minclips_P', 'Minclips_R']
targets.each do |t|
  target t do
    commonPods
    unless t.end_with?('_R')
      toolPods
    end
  end
end
#
post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      
      xcconfig_path = config.base_configuration_reference.real_path
      xcconfig = File.read(xcconfig_path)
      xcconfig_mod = xcconfig.gsub(/DT_TOOLCHAIN_DIR/, "TOOLCHAIN_DIR")
      File.open(xcconfig_path, "w") { |file| file << xcconfig_mod }
      
      if config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'].to_f < 15.0
        config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '15.0'
      end
      
      if target.respond_to?(:product_type) and target.product_type == "com.apple.product-type.bundle"
        target.build_configurations.each do |config|
          config.build_settings['CODE_SIGNING_ALLOWED'] = 'NO'
        end
      end
      
    end
  end
end
