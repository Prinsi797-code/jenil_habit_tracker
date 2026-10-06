require 'xcodeproj'

project_path = 'DailyPlanner.xcodeproj'
project = Xcodeproj::Project.open(project_path)
target = project.targets.first

# Helper to add a file to a specific group path
def add_file(project, target, group_path, filename)
    group = project.main_group.find_subpath(group_path, true)
    
    # Check if file is already added
    if group.files.any? { |f| f.path == filename }
        puts "#{filename} already in project!"
        return
    end

    file_ref = group.new_reference(filename)
    target.source_build_phase.add_file_reference(file_ref, true)
    puts "Added #{filename} to project!"
end

add_file(project, target, File.join('DailyPlanner', 'Models'), 'HabitTask.swift')
add_file(project, target, File.join('DailyPlanner', 'Manager'), 'Array+Extensions.swift')
add_file(project, target, File.join('DailyPlanner', 'Manager'), 'Haptics.swift')
add_file(project, target, 'DailyPlanner', 'HabitChartView.swift')

project.save
puts "Project saved!"
