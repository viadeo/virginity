Gem::Specification.new do |s|
  s.name = %q{virginity}
  s.version = "0.3.31"
  s.date = %q{2012-09-19}
  s.authors = ["Tijn Schuurmans"]
  s.email = %q{tijn@soocial.com}
  s.summary = %q{Virginity vCard writer/parser.}
  s.description = %q{Virginity reads and writes vcards and provides a nice api to modify them.}
  s.add_dependency('reactive_array', ">= 1.0")
  s.add_dependency('fast_xs')
  s.files = Dir['lib/**/*']
end

