Gem::Specification.new do |s|
  s.name = %q{sandra}
  s.version = "0.1.8"
  s.date = Time.now.strftime("%Y-%m-%d")
  s.authors = ["Charles Max Wood"]
  s.email = %q{chuck@teachmetocode.com}
  s.summary = %q{ORM for Cassandra in Ruby}
  s.homepage = %q{http://teachmetocode.com/}
  s.description = %q{Provides an Object Relational interface to Cassandra}
  s.add_dependency('cassandra')
  s.add_dependency('activemodel')
  s.add_development_dependency('rspec')
  s.files = [ "README", 
              "MIT-LICENSE", 
              "lib/sandra.rb",
              "lib/sandra/list.rb",
              "lib/sandra/key_validator.rb",
              "lib/sandra/uniqueness_validator.rb"]
end

