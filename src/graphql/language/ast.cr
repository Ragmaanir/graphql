module GraphQL
  module Language
    abstract class ASTNode
      macro values(args)
        property {{args.map { |k, v| "#{k} : #{v}" }.join(",").id}}

        def_equals_and_hash {{args.keys}}

        def initialize({{args.keys.join(",").id}}, **rest)
          {%
            assignments = args.map do |k, v|
              if v.is_a?(Generic) && v.name.id == "Array"
                type = v.type_vars.first.id
                "@#{k.id} = #{k.id}.map(&.as(#{type}))"
              else
                "@#{k.id} = #{k.id}"
              end
            end
          %}

          {{assignments.join("\n").id}}

          super(**rest)
        end
      end

      macro traverse(*values)
        def visit(visited_ids : Array(UInt64), block = Proc(ASTNode, ASTNode?).new {})
          {% for key in values %}
            case val = {{key.id}}
            when Array
              val.each do |v|
                visited_ids << v.object_id
                v.visit(visited_ids, block)
              end
            when nil
            else
              visited_ids << val.object_id
              val.visit(visited_ids, block)
            end
          {% end %}

          block.call(self)
        end
      end

      def visit(visited_ids = [] of UInt64, block = Proc(ASTNode, ASTNode?).new { })
        res = block.call(self)
        res.is_a?(self) ? res : self
      end

      def ==(other)
        self.class == other.class
      end
    end # ASTNode
  end
end
