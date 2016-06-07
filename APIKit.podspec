Pod::Spec.new do |s|
s.name             = "APIKit"
s.version          = "0.7.9"
s.summary          = "Promise-based tools for working with an abstract API"

s.description      = <<-DESC
This is a promise-based library abstracts the interface to a model data source, which may be remote.
DESC

s.homepage         = "https://github.com/sadawi/APIKit"
s.license          = 'MIT'
s.author           = { "Sam Williams" => "samuel.williams@gmail.com" }
s.source           = { :git => "https://github.com/sadawi/APIKit.git", :tag => s.version.to_s }

s.platforms       = { :ios => '8.0', :watchos => '2.0' }
s.requires_arc = true

s.source_files = 'APIKit/*.swift'
s.resource_bundles = {
    'APIKit' => ['Pod/Assets/*.png']
}

s.dependency 'Alamofire', '~> 3.0'
s.dependency 'PromiseKit/CorePromise', '~> 3.0'
s.dependency 'SwiftyJSON', '~> 2.3.0'
s.dependency 'MagneticFields', '~> 0.6.3'

end
