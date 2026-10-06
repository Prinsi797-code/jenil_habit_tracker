require 'xcodeproj'

project_path = 'DailyPlanner.xcodeproj'
project = Xcodeproj::Project.open(project_path)
target = project.targets.first

group = project.main_group.find_subpath(File.join('DailyPlanner', 'Models'), true)

# Remove HabitTask.swift
file_refs_to_remove = group.files.select { |f| f.path == 'HabitTask.swift' }
file_refs_to_remove.each do |ref|
    target.source_build_phase.remove_file_reference(ref)
    ref.remove_from_project
    puts "Removed HabitTask.swift"
end

# Add AppHabitTask.swift
unless group.files.any? { |f| f.path == 'AppHabitTask.swift' }
    file_ref = group.new_reference('AppHabitTask.swift')
    target.source_build_phase.add_file_reference(file_ref, true)
    puts "Added AppHabitTask.swift"
end

project.save
puts "Project saved!"
