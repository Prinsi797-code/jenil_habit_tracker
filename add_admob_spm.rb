require 'xcodeproj'

project_path = 'DailyPlanner.xcodeproj'
project = Xcodeproj::Project.open(project_path)
target = project.targets.first

# Add XCRemoteSwiftPackageReference
package_ref = project.new(Xcodeproj::Project::Object::XCRemoteSwiftPackageReference)
package_ref.repositoryURL = "https://github.com/googleads/swift-package-manager-google-mobile-ads.git"
package_ref.requirement = {
  "kind" => "upToNextMajorVersion",
  "minimumVersion" => "11.8.0"
}
project.root_object.package_references << package_ref

# Add XCSwiftPackageProductDependency
package_dep = project.new(Xcodeproj::Project::Object::XCSwiftPackageProductDependency)
package_dep.package = package_ref
package_dep.product_name = "GoogleMobileAds"

target.package_product_dependencies << package_dep

# Add PBXBuildFile to target's frameworks build phase
build_file = project.new(Xcodeproj::Project::Object::PBXBuildFile)
build_file.product_ref = package_dep
target.frameworks_build_phase.files << build_file

project.save
puts "Successfully added GoogleMobileAds via SPM!"
