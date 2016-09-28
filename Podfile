# Uncomment this line to define a global platform for your project
source 'https://github.com/CocoaPods/Specs.git'
#platform :ios, '8.0'
# Uncomment this line if you're using Swift
use_frameworks!

post_install do |installer|
    installer.pods_project.targets.each do |target|
        target.build_configurations.each do |config|
            config.build_settings['ENABLE_BITCODE'] = 'NO'
        end
    end
end

target 'GPS Tracker' do
    pod 'Alamofire'
    pod 'SwiftyJSON'
    pod 'Bugsnag', :git => "https://github.com/bugsnag/bugsnag-cocoa.git"
    pod 'Google/Analytics'
    pod 'TTTAttributedLabel'

end

target 'GPS TrackerTests' do

end

