# -*- encoding: utf-8 -*-
# stub: rss 0.2.8 ruby lib

Gem::Specification.new do |s|
  s.name = "rss".freeze
  s.version = "0.2.8"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Kouhei Sutou".freeze]
  s.bindir = "exe".freeze
  s.date = "2019-01-25"
  s.description = "Family of libraries that support various formats of XML \"feeds\".".freeze
  s.email = ["kou@cozmixng.org".freeze]
  s.homepage = "https://github.com/ruby/rss".freeze
  s.licenses = ["BSD-2-Clause".freeze]
  s.rubygems_version = "2.7.6".freeze
  s.summary = "Family of libraries that support various formats of XML \"feeds\".".freeze

  s.installed_by_version = "2.7.6" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<bundler>.freeze, [">= 0"])
      s.add_development_dependency(%q<rake>.freeze, [">= 0"])
      s.add_development_dependency(%q<test-unit>.freeze, [">= 0"])
    else
      s.add_dependency(%q<bundler>.freeze, [">= 0"])
      s.add_dependency(%q<rake>.freeze, [">= 0"])
      s.add_dependency(%q<test-unit>.freeze, [">= 0"])
    end
  else
    s.add_dependency(%q<bundler>.freeze, [">= 0"])
    s.add_dependency(%q<rake>.freeze, [">= 0"])
    s.add_dependency(%q<test-unit>.freeze, [">= 0"])
  end
end
