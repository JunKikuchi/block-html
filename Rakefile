require 'rubygems'
require 'rake/gempackagetask'

NAME = 'block-html'
VERS = '0.0.1'

desc 'Packages block-html'
spec = Gem::Specification.new do |s|
  s.name = NAME
  s.version = VERS
  s.platform = Gem::Platform::RUBY
  s.has_rdoc = false
  s.summary = "BlockHTML"
  s.description = s.summary
  s.author = "Jun Kikuchi"
  s.email = "kikuchi@bonnou.com"
  s.homepage = "http://bonnou.com/"
  s.files = %w(COPYING CHANGELOG README Rakefile) + Dir.glob("{bin,doc,spec,lib}/**/*")
  s.require_path = "lib"
end

Rake::GemPackageTask.new(spec) do |pkg|
end
