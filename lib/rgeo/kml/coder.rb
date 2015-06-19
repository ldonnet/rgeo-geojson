# -----------------------------------------------------------------------------
#
# Kml encoder object
#
# -----------------------------------------------------------------------------

require "rexml/document"
require 'rexml/parsers/pullparser'

module RGeo

  module Kml


    # This object encapsulates encoding and decoding settings (principally
    # the RGeo::Feature::Factory and the RGeo::Kml::EntityFactory to
    # be used) so that you can encode and decode without specifying those
    # settings every time.

    class Coder

      ELEMENT_MAP = {
      'Point' => "point",
      'LineString' => "line_string",
      'LinearRing' => "linear_ring",
      'Polygon' => "polygon",
      'MultiGeometry' => "geometry_collection"
      }

      @@kml_available = nil
      @@activesupport_available = nil


      # Create a new coder settings object. The geo factory is passed as
      # a required argument.
      #
      # Options include:
      #
      # [<tt>:geo_factory</tt>]
      #   Specifies the geo factory to use to create geometry objects.
      #   Defaults to the preferred cartesian factory.
      # [<tt>:entity_factory</tt>]
      #   Specifies an entity factory, which lets you override the types
      #   of Kml entities that are created. It defaults to the default
      #   RGeo::Kml::EntityFactory, which generates objects of type
      #   RGeo::Kml::Feature or RGeo::Kml::FeatureCollection.
      #   See RGeo::Kml::EntityFactory for more information.

      def initialize(opts_={})
        @geo_factory = opts_[:geo_factory] || ::RGeo::Cartesian.preferred_factory
        @entity_factory = opts_[:entity_factory] || EntityFactory.instance
        @buffer = ''
        
        @num_coordinates = 2
        @num_coordinates += 1 if @geo_factory.property(:has_z_coordinate)
        @num_coordinates += 1 if @geo_factory.property(:has_m_coordinate)
      end


      # Encode the given object as Kml. The object may be one of the
      # geometry objects specified in RGeo::Feature, or an appropriate
      # Kml wrapper entity supported by this coder's entity factory.
      #
      # This method returns a KML object (xml with Placemark).
      #
      # Returns nil if nil is passed in as the object.

      def encode(object_)
        if @entity_factory.is_feature_collection?(object_)
          {
            'type' => 'FeatureCollection',
            'features' => @entity_factory.map_feature_collection(object_){ |f_| _encode_feature(f_) },
          }
        elsif @entity_factory.is_feature?(object_)
          _encode_feature(object_)
        elsif object_.nil?
          nil
        else
          _encode_geometry(object_)
        end
      end

      
      # Returns the RGeo::Feature::Factory used to generate geometry objects.

      def geo_factory
        @geo_factory
      end


      # Returns the RGeo::Kml::EntityFactory used to generate Kml
      # wrapper entities.

      def entity_factory
        @entity_factory
      end


      def _encode_feature(object_)  # :nodoc:
        id_ = @entity_factory.get_feature_id(object_)
        kml_ = '<?xml version="1.0" encoding="UTF-8"?>\n'
        kml_ += '<kml xmlns="http://www.opengis.net/kml/2.2">\n'
        kml_ += "<Document>"
        kml_ += "<name>Kml File</name>"
        kml_ += "<Placemark id="#{id_}">\n"
        kml_ += _encode_geometry(@entity_factory.get_feature_geometry(object_))
        kml_ += "</Placemark>\n"
        kml_ += "</Document>"
        kml_ += "</kml>"
        
        # 'properties' => @entity_factory.get_feature_properties(object_).dup,        
        # id_ = @entity_factory.get_feature_id(object_)
        # json_['id'] = id_ if id_
        kml_
      end


      def _encode_geometry(object_, point_encoder_=nil)  # :nodoc:
        unless point_encoder_
          if object_.factory.property(:has_z_coordinate)
            if object_.factory.property(:has_m_coordinate)
              point_encoder_ = ::Proc.new{ |p_| [p_.x, p_.y, p_.z, p_.m].join(",") }
            else
              point_encoder_ = ::Proc.new{ |p_| [p_.x, p_.y, p_.z].join(",") }
            end
          else
            if object_.factory.property(:has_m_coordinate)
              point_encoder_ = ::Proc.new{ |p_| [p_.x, p_.y, p_.m].join(",") }
            else
              point_encoder_ = ::Proc.new{ |p_| [p_.x, p_.y].join(",") }
            end
          end
        end
        case object_
        when ::RGeo::Feature::Point
          result = "<Point>\n"
          #result += options[:geom_data] if options[:geom_data]
          result += "<coordinates>" + point_encoder_.call(object_)
          result += "</coordinates>\n"
          result += "</Point>\n"
        when ::RGeo::Feature::LineString
          result = "<LineString>\n"
          #result += options[:geom_data] if options[:geom_data]
          result += "<coordinates>\n"
          result += object_.points.map(&point_encoder_).join("\n")
          result += "\n</coordinates>\n"
          result += "</LineString>\n"
        when ::RGeo::Feature::Polygon
          result = "<Polygon>\n"
          #result += options[:geom_data] if options[:geom_data]
          result += "<outerBoundaryIs><LinearRing><coordinates>\n"
          result += object_.exterior_ring.points.map(&point_encoder_).join("\n")
          result += "\n</coordinates></LinearRing></outerBoundaryIs>\n"
          object_.interior_rings.each do |interior_ring|
            result += "<innerBoundaryIs><LinearRing><coordinates>\n"
            result += interior_ring.points.map(&point_encoder_).join("\n")
            result += "\n</coordinates></LinearRing></innerBoundaryIs>\n"
          end
          result += "</Polygon>\n"
        when ::RGeo::Feature::MultiPoint
          result = "<MultiGeometry>\n"
          object_.each do |geometry|
            result += "<Point>\n<coordinates>"
            #options[:id_attr] = "" #the subgeometries do not have an ID
            result += point_encoder_.call(geometry)
            result += "</coordinates>\n</Point>\n"
          end
          result += "</MultiGeometry>\n"
        when ::RGeo::Feature::MultiLineString
          result = "<MultiGeometry>\n"
          object_.each do |geometry|
            #options[:id_attr] = "" #the subgeometries do not have an ID
            result += "<LineString>\n"
            #result += options[:geom_data] if options[:geom_data]
            result += "<coordinates>\n"
            result += geometry.points.map(&point_encoder_).join("\n")
            result += "\n</coordinates>\n"
            result += "</LineString>\n"            
          end
          result += "</MultiGeometry>\n"
        when ::RGeo::Feature::MultiPolygon
          result = "<MultiGeometry>\n"
          object_.each do |geometry|
            #options[:id_attr] = "" #the subgeometries do not have an ID
            result += "<Polygon>\n"
            #result += options[:geom_data] if options[:geom_data]
           result += "<outerBoundaryIs><LinearRing><coordinates>\n"
            result += geometry.exterior_ring.points.map(&point_encoder_).join("\n")
            result += "\n</coordinates></LinearRing></outerBoundaryIs>\n"
            geometry.interior_rings.each do |interior_ring|
              result += "<innerBoundaryIs><LinearRing><coordinates>\n"
              result += interior_ring.points.map(&point_encoder_).join("\n")
              result += "\n</coordinates></LinearRing></innerBoundaryIs>\n"
            end
            result += "</Polygon>\n"
          end
          result += "</MultiGeometry>\n"
        when ::RGeo::Feature::GeometryCollection
          result = "<MultiGeometry>\n"          
          #options[:id_attr] = "" #the subgeometries do not have an ID
          result += object_.map{ |geom_| _encode_geometry(geom_, point_encoder_) }.join("")
          result += "</MultiGeometry>\n"
        else
          nil
        end
      end


      # Decode an object from Kml. The input may a
      # String, or an IO object from which to read the KML string.
      # If an error occurs, nil is returned.
      def decode(input_) 
        @kml_stream_listener = KmlStreamListener.new(geo_factory)
        @kml_stream_listener.parse(input_)
        @kml_stream_listener.result
      end

    end     

  end

end
