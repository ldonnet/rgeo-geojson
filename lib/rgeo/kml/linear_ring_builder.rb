module RGeo
  module Kml
    
    class LinearRingBuilder
      attr_reader :parent, :geo_factory, :linear_ring
      attr_accessor :points, :text
      
      def initialize(geo_factory, parent)
        @geo_factory = geo_factory
        @parent = parent
      end

      def build
        return nil unless points.kind_of?(::Array)
        @linear_ring = @geo_factory.linear_ring(points)
      end
    end

  end
end
