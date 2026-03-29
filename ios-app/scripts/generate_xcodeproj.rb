#!/usr/bin/env ruby
# frozen_string_literal: true

require 'pathname'

begin
  require 'xcodeproj'
rescue LoadError
  warn 'Missing gem: xcodeproj. Install with `gem install xcodeproj`.'
  exit 1
end

PROJECT_NAME = 'StoryComicAIApp'
APP_TARGET_NAME = 'StoryComicAIApp'
TEST_TARGET_NAME = 'StoryComicAIAppTests'
DEPLOYMENT_TARGET = '17.0'
SWIFT_VERSION = '5.10'
APP_BUNDLE_ID = 'com.storycomicai.app'
TEST_BUNDLE_ID = 'com.storycomicai.app.tests'

ROOT = Pathname.new(__dir__).join('..').expand_path
SOURCE_ROOT = ROOT.join(PROJECT_NAME)
PROJECT_PATH = ROOT.join("#{PROJECT_NAME}.xcodeproj")

unless SOURCE_ROOT.directory?
  warn "Source root not found: #{SOURCE_ROOT}"
  exit 1
end

PROJECT_PATH.rmtree if PROJECT_PATH.exist?
project = Xcodeproj::Project.new(PROJECT_PATH.to_s)

project.build_configurations.each do |config|
  config.build_settings['SWIFT_VERSION'] = SWIFT_VERSION
  config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = DEPLOYMENT_TARGET
end

app_target = project.new_target(:application, APP_TARGET_NAME, :ios, DEPLOYMENT_TARGET)
test_target = project.new_target(:unit_test_bundle, TEST_TARGET_NAME, :ios, DEPLOYMENT_TARGET)
test_target.add_dependency(app_target)

def configure_app_target(target)
  target.build_configurations.each do |config|
    config.build_settings['PRODUCT_BUNDLE_IDENTIFIER'] = APP_BUNDLE_ID
    config.build_settings['SWIFT_VERSION'] = SWIFT_VERSION
    config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = DEPLOYMENT_TARGET
    config.build_settings['GENERATE_INFOPLIST_FILE'] = 'YES'
    config.build_settings['CURRENT_PROJECT_VERSION'] = '1'
    config.build_settings['MARKETING_VERSION'] = '1.0'
    config.build_settings['TARGETED_DEVICE_FAMILY'] = '1,2'
    config.build_settings['ASSETCATALOG_COMPILER_APPICON_NAME'] = 'AppIcon'
    config.build_settings['CODE_SIGNING_ALLOWED'] = 'NO' if config.name == 'Debug'
  end
end

def configure_test_target(target)
  target.build_configurations.each do |config|
    config.build_settings['PRODUCT_BUNDLE_IDENTIFIER'] = TEST_BUNDLE_ID
    config.build_settings['SWIFT_VERSION'] = SWIFT_VERSION
    config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = DEPLOYMENT_TARGET
    config.build_settings['GENERATE_INFOPLIST_FILE'] = 'YES'
    config.build_settings['CODE_SIGNING_ALLOWED'] = 'NO'
    config.build_settings['TEST_HOST'] = '$(BUILT_PRODUCTS_DIR)/StoryComicAIApp.app/StoryComicAIApp'
    config.build_settings['BUNDLE_LOADER'] = '$(TEST_HOST)'
    config.build_settings['ENABLE_TESTING_SEARCH_PATHS'] = 'YES'
  end
end

configure_app_target(app_target)
configure_test_target(test_target)

def ensure_group(root_group, relative_dir)
  current = root_group
  return current if relative_dir.nil? || relative_dir == '.'

  relative_dir.split('/').each do |component|
    next if component.nil? || component.empty? || component == '.'

    next_group = current.groups.find { |group| group.display_name == component }
    current = next_group || current.new_group(component)
  end

  current
end

def add_file_to_target(project, target, absolute_path, source_root)
  relative_path = absolute_path.relative_path_from(source_root.parent).to_s
  directory = File.dirname(relative_path)
  group = ensure_group(project.main_group, directory)

  file_ref = group.files.find { |ref| ref.path == File.basename(relative_path) }
  file_ref ||= group.new_file(relative_path)
  target.source_build_phase.add_file_reference(file_ref, true)
end

all_swift_files = Dir.glob(SOURCE_ROOT.join('**/*.swift').to_s).map { |f| Pathname.new(f) }.sort
app_swift_files = all_swift_files.reject { |file| file.to_s.include?('/Tests/') }
test_swift_files = all_swift_files.select { |file| file.to_s.include?('/Tests/') }

app_swift_files.each { |file| add_file_to_target(project, app_target, file, SOURCE_ROOT) }
test_swift_files.each { |file| add_file_to_target(project, test_target, file, SOURCE_ROOT) }

scheme = Xcodeproj::XCScheme.new
scheme.add_build_target(app_target)
scheme.add_test_target(test_target)
scheme.set_launch_target(app_target)
scheme.save_as(PROJECT_PATH.to_s, PROJECT_NAME, true)

project.save
puts "Generated #{PROJECT_PATH} with shared scheme #{PROJECT_NAME}.xcscheme"
