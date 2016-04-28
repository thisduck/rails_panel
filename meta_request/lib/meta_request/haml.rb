module Haml
  class Compiler

    alias_method :orig_compile, :compile

    def compile(node)
      if node.type == :tag
        file = @options[:filename]
        if defined?(::Rails)
          file.gsub!(::Rails.root, "")
          file.gsub!(/^\//, "")
        end

        node.value.attributes.merge!(:data => { :source_line => "#{file}:#{node.line}" })
      end

      orig_compile(node)
    end

  end
end
