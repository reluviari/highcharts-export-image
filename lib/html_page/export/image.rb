require "html_page/export/image/version"
require "html_page/export/image/configuration"
require 'shellwords'
require 'json'

module HtmlPage
  module Export
    module Image
      attr_accessor :config

      # Handle basic errors
      #
      def self.handle_errors(result, output_path)
        if result["error: format and output does not match (should be .jpeg)"]
          throw ArgumentError.new(result)
        elsif result["error"]
          throw StandardError.new(result)
        elsif !result["success"] || File.size(output_path) == 0
          throw StandardError.new("failed to create img #{result}")
        end
      end

      def self.command?(command)
        system("which #{ command} > /dev/null 2>&1")
      end

      # Convert html_page into image
      #
      def self.html_to_img(html_page_content, output_path, options = {})
        config ||= HtmlPage::Export::Image.config
        options = config.default_options.merge(options)
        options_line = options.inject([]) { |options_array, (option, value)|
          if option == :paper_size
            options_array << "-paper_size=#{value.to_json}".shellescape
          else
            options_array << (value ? "-#{option}=#{value.to_s}".shellescape : "--#{option}".shellescape );
          end

          options_array
        }.join(' ')

        cmd = "#{config.phantomjs} #{config.html_page_convert} #{html_page_content.shellescape} #{output_path.shellescape} #{options_line}"
        cmd = "timeout 42 " + cmd if self.command?("timeout")
        result = `#{cmd}`

        self.handle_errors(result, output_path)

        return output_path
      end
    end
  end
end
