module Pod
  module Generator

    # Generates a header which allows to inspect at compile time the installed
    # pods and the installed specifications of a pod.
    #
    # Example output:
    #
    #     #define COCOAPODS_POD_AVAILABLE_ObjectiveSugar 1
    #     #define COCOAPODS_VERSION_MAJOR_ObjectiveSugar 0
    #     #define COCOAPODS_VERSION_MINOR_ObjectiveSugar 6
    #     #define COCOAPODS_VERSION_PATCH_ObjectiveSugar 2
    #
    # Example usage:
    #
    #     #ifdef COCOAPODS
    #       #ifdef COCOAPODS_POD_AVAILABLE_ObjectiveSugar
    #         #import "ObjectiveSugar.h"
    #       #endif
    #     #else
    #       // Non CocoaPods code
    #     #endif
    #
    class TargetEnvironmentHeader

      # @return [Array<TargetDefinition>] the target definitions installed for the target.
      #
      attr_reader :target_definitions

      # @param  [Array<Library>] target_definitions @see target_definitions
      # @param  [Array<String>]  build_configs Names of the configurations in the aggregate target
      #
      def initialize(target_definitions, build_configs)
        @target_definitions = target_definitions
        @build_configs = build_configs
      end

      # Generates and saves the file.
      #
      # @param  [Pathname] pathname
      #         The path where to save the generated file.
      #
      # @return [void]
      #
      def save_as(pathname)
        pathname.open('w') do |source|
          source.puts
          source.puts "// To check if a library is compiled with CocoaPods you"
          source.puts "// can use the `COCOAPODS` macro definition which is"
          source.puts "// defined in the xcconfigs so it is available in"
          source.puts "// headers also when they are imported in the client"
          source.puts "// project."
          source.puts
          source.puts
          puts "HELLO DEFS #{target_definitions}"
          target_definitions.each do |targdef|
            puts "target #{targdef}"
            spec = pod_target.specs[0]
            spec_name = safe_spec_name(spec.name)
            source.puts "// #{spec.name}"
            source.puts "#define COCOAPODS_POD_HEADERS_AVAILABLE_#{spec_name}"

            pod_whitelisted_in_configs = @build_configs.filter do |config_name|
              pod_target.is_pod_whitelisted_for_configuration?(spec.name, config_name)
            end
            if pod_whitelisted_in_configs != @build_configs
              condition = pod_whitelisted_in_configs.map { |config_name| "COCOAPODS_BUILD_CONFIGURATION_#{config_name}"}.join(" || ")
              source.puts "#if #{condition}"
              source.puts "    #define COCOAPODS_POD_AVAILABLE_#{spec_name}"
              source.puts "#endif"
            else
              source.puts "#define COCOAPODS_POD_AVAILABLE_#{spec_name}"
            end

            if spec.version.semantic?
              source.puts "#define COCOAPODS_VERSION_MAJOR_#{spec_name} #{spec.version.major}"
              source.puts "#define COCOAPODS_VERSION_MINOR_#{spec_name} #{spec.version.minor}"
              source.puts "#define COCOAPODS_VERSION_PATCH_#{spec_name} #{spec.version.patch}"
            else
              source.puts "// This library does not follow semantic-versioning,"
              source.puts "// so we were not able to define version macros."
              source.puts "// Please contact the author."
              source.puts "// Version: #{spec.version}."
            end
            source.puts
          end
        end
      end

      #-----------------------------------------------------------------------#

      private

      # !@group Private Helpers

      def safe_spec_name(spec_name)
        spec_name.gsub(/[^\w]/,'_')
      end

      #-----------------------------------------------------------------------#

    end
  end
end
