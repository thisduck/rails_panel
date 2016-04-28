module Haml
  class Compiler

    alias_method :orig_compile, :compile

    def compile(node)
      if node.type == :tag
        file, line = @options[:filename], node.line
        node.value.attributes.merge!(:data => { :source_line => "#{file}:#{line}" })
      end
      orig_compile(node)
    end

  end
end
