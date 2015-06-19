# RGeo::Kml

[![Build Status](https://travis-ci.org/ldonnet/rgeo-kml.png)](http://travis-ci.org/ldonnet/rgeo-kml?branch=master) [![Dependency Status](https://gemnasium.com/ldonnet/rgeo-kml.png)](https://gemnasium.com/ldonnet/rgeo-kml) [![Code Climate](https://codeclimate.com/github/ldonnet/rgeo-kml.png)](https://codeclimate.com/github/ldonnet/rgeo-kml)

RGeo::Kml is an optional module for [RGeo](https://github.com/rgeo/rgeo)
that provides Kml encoding and decoding services.

Summary
------------

RGeo is a key component for writing location-aware applications in the
Ruby programming language. At its core is an implementation of the
industry standard OGC Simple Features Specification, which provides data
representations of geometric objects such as points, lines, and polygons,
along with a set of geometric analysis operations. See the README for the
"rgeo" gem for more information.

RGeo::Kml is an optional RGeo add-on module that provides Kml
encoding and decoding services. Kml is a format
used by many web services that need to communicate geospatial data. See
https://developers.google.com/kml/documentation/ for more information.

Installation
-------------
RGeo::Kml has the following requirements:

* Ruby 1.9.2 or later.
* rgeo 0.3.13 or later.

Install RGeo::Kml as a gem:

```sh
 gem install rgeo
 gem install rgeo-kml
 ```
 
See the README for the "rgeo" gem, a required dependency, for further
installation information.

Development and support
-----------------------

More information can be found on the [project website on GitHub](http://github.com/ldonnet/rgeo-kml). 
There is extensive usage documentation available [on the wiki](https://github.com/ldonnet/rgeo-kml/wiki).

Example:
--------

### Decode KML

```ruby
require 'rgeo/kml'
str1 = '{"type":"Point","coordinates":[1,2]}'
geom = RGeo::Kml.decode(str1)
geom.as_text              # => "POINT(1.0 2.0)"
str2 = '{"type":"Feature","geometry":{"type":"Point","coordinates":[2.5,4.0]},"properties":{"color":"red"}}'
feature = RGeo::Kml.decode(str2)
feature['color']          # => 'red'
feature.geometry.as_text  # => "POINT(2.5 4.0)"
```

### Encode in KML

```ruby
hash = RGeo::Kml.encode(feature)
hash.to_json == str2      # => true
```

License
-------
 
This project is licensed under the MIT license, a copy of which can be found in the LICENSE file.

Support
-------
 
Users looking for support should file an issue on the GitHub issue tracking page (https://github.com/ldonnet/rgeo-kml/issues), or file a pull request (https://github.com/ldonnet/rgeo-kml/pulls) if you have a fix available.
