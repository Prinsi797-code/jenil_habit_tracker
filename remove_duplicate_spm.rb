require 'xcodeproj'

project_path = 'DailyPlanner.xcodeproj'
project = Xcodeproj::Project.open(project_path)
target = project.targets.first

# Remove the package reference we added
project.root_object.package_references.delete_if do |ref|
  ref.requirement && ref.requirement['minimumVersion'] == '11.8.0'
end

# Remove the product dependency
target.package_product_dependencies.delete_if do |dep|
  dep.product_name == 'GoogleMobileAds' && dep.package.nil?
end

# Remove the framework build phase entry
target.frameworks_build_phase.files.delete_if do |file|
  file.product_ref.is_a?(Xcodeproj::Project::Object::XCSwiftPackageProductDependency) &&
  file.product_ref.product_name == 'GoogleMobileAds' && 
  file.product_ref.package.nil?
end

project.save
puts "Successfully removed duplicate SPM package"
