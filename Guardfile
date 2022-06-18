# -*- ruby -*-
# frozen_string_literal: true

gem 'guard-rspec'

guard :rspec, cmd: "rspec" do
  watch(%r{^spec/.+_spec\.rb$}) { |m| m[0] }
  watch(%r{^lib/cx/(.+)\.rb$})  { |m| "spec/#{m[1]}_spec.rb" }
  watch('spec/spec_helper.rb')  { "rspec" }
end

