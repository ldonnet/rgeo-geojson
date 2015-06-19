# -----------------------------------------------------------------------------
#
# RGeo::GeoJSON Gemspec
#
# -----------------------------------------------------------------------------

::Gem::Specification.new do |s_|
  s_.name = 'rgeo-kml'
  s_.summary = 'An RGeo module providing KML encoding and decoding.'
  s_.description = "RGeo is a geospatial data library for Ruby. RGeo::Kml is an optional RGeo module providing KML encoding and decoding services. This module can be used to communicate with location-based web services that understand the KML format."
  s_.version = "#{::File.read('Version').strip}.nonrelease"
  s_.author = 'Luc Donnet'
  s_.email = 'luc.donnet@free.fr'
  s_.homepage = "http://ldonnet.github.com/rgeo-kml"
  s_.licenses = ['MIT']
  s_.required_ruby_version = '>= 1.9.3'
  s_.files = ::Dir.glob("lib/**/*.rb") +
    ::Dir.glob("test/**/*.rb") +
    ::Dir.glob("*.rdoc") +
    ['Version']
  s_.extra_rdoc_files = ::Dir.glob("*.rdoc")
  s_.test_files = ::Dir.glob("test/**/tc_*.rb")
  s_.platform = ::Gem::Platform::RUBY
  s_.add_dependency('rgeo', '>= 0.3.13')
end
