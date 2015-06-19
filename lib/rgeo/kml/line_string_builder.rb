module RGeo
  module Kml
    
    class LineStringBuilder
      attr_reader :parent, :geo_factory, :line_string 
      attr_accessor :points, :text
      
      def initialize(geo_factory, parent)
        @geo_factory = geo_factory
        @parent = parent
      end

      def build
        return nil unless points.kind_of?(::Array)
        @line_string = @geo_factory.line_string(points)
      end
    end

  end
end
