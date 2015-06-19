module RGeo
  module Kml
    
    class PolygonBuilder
      attr_reader :parent, :geo_factory, :polygon
      attr_accessor :linear_rings, :text
      
      def initialize(geo_factory, parent)
        @geo_factory = geo_factory
        @parent = parent
        @linear_rings = []
      end
      
      def add_linear_ring(linear_ring)
        linear_rings << linear_ring
      end

      def build
        return nil unless ( linear_rings.kind_of?(::Array) || linear_rings.size != 0 )
        @polygon = @geo_factory.polygon(linear_rings[0], linear_rings[1..-1])
      end
      
    end

  end
end
