# frozen_string_literal: true

ENV["CONJUR_VERSION_DISPLAY"] = File.read(File.expand_path("../../VERSION", File.dirname(__FILE__)))

puts "Conjur Version: #{ENV["CONJUR_VERSION_DISPLAY"]}"
