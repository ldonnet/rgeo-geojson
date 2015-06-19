module RGeo
  module Kml
    
    class MultiGeometryBuilder
      attr_reader :geo_factory, :parent
      attr_accessor :text, :points, :line_strings, :linear_rings, :polygons
      
      def initialize(geo_factory, parent)
        @geo_factory = geo_factory
        @parent = parent
        @points = []
        @linear_rings = []
        @line_strings = []
        @polygons = []
      end
      
      def add_point(point)
        @points << point
      end

      def add_line_string(line_string)
        @line_strings << line_string
      end
      
      def add_linear_ring(linear_ring)
        @linear_rings << linear_ring
      end
      
      def add_polygon(polygon)
        @polygons << polygon
      end

      def multi_geometries
        puts [points, line_strings, linear_rings, polygons].reduce(:+).inspect
        @multi_geometries ||= [points, line_strings, linear_rings, polygons].reduce(:+)
      end

      def multi_geometries?
        geometries_counter = 0
        
        geometries_counter += 1 if !points.empty?
        geometries_counter += 1 if !line_strings.empty?
        geometries_counter += 1 if !linear_rings.empty?
        geometries_counter += 1 if !polygons.empty?

        geometries_counter >=2 ? true : false 
      end

      def build
        if multi_geometries?
          @geo_factory.collection(multi_geometries)
        elsif !points.empty?
          return nil unless points.kind_of?(::Array)
          @geo_factory.multi_point(points)
        elsif !line_strings.empty?
          return nil unless line_strings.kind_of?(::Array)
          @geo_factory.multi_line_string(line_strings)
        elsif !linear_rings.empty?
          return nil unless linear_rings.kind_of?(::Array)
          @geo_factory.multi_linear_ring(linear_rings)
        elsif !polygons.empty?
          return nil unless polygons.kind_of?(::Array)
          @geo_factory.multi_polygon(polygons)
        else
          nil
        end
      end
      
    end

  end
end
    
