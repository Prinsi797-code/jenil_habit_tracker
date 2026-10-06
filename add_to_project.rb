require 'xcodeproj'

project_path = 'DailyPlanner.xcodeproj'
project = Xcodeproj::Project.open(project_path)
target = project.targets.first

group = project.main_group.find_subpath(File.join('DailyPlanner', 'Manager'), true)
file_ref = group.new_reference('RemoteConfigManager.swift')
target.source_build_phase.add_file_reference(file_ref, true)

project.save
puts "Added RemoteConfigManager.swift to project!"
