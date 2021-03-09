module GraphQL
  module Language
    abstract class ASTNode
      macro inherited
        VALUES = [] of Tuple(Symbol, Object.class)
      end

      macro values(args)
        {%
          args.each do |k, v|
            VALUES << {k, v}
          end
        %}

        property {{args.map { |k, v| "#{k} : #{v}" }.join(",").id}}

        def_equals_and_hash {{VALUES.map(&.[0])}}

        {%
          signatures = VALUES.map { |v| "#{v[0].id} " }
          signature = (signatures + ["**rest"]).join(", ").id
          assignments = VALUES.map do |v|
            if v[1].id =~ /^Array/
              type = v[1].id.gsub(/Array\(/, "").gsub(/\)/, "")
              "@#{v[0].id} = #{v[0].id}.as(Array).map(&.as(#{type})).as(#{v[1].id})"
            else
              "@#{v[0].id} = #{v[0].id}.as(#{v[1].id})"
            end
          end
        %}

        def initialize({{signature}})
          {{assignments.size > 0 ? assignments.join("\n").id : "".id}}
          super(**rest)
        end
      end

      macro traverse(name, *values)
        def visit(visited_ids = [] of UInt64, block = Proc(ASTNode, ASTNode?).new {})
          {% for key in values %}
            %val = {{key.id}}
            if %val.is_a?(Array)
              %result = %val.map! do |v|
                next v if visited_ids.includes? v.object_id
                visited_ids << v.object_id
                res = v.visit(visited_ids, block)
                res.is_a?(ASTNode) ? res : v
              end
            else
              unless %val == nil || visited_ids.includes? %val.object_id
                visited_ids << %val.object_id
                %result = %val.not_nil!.visit(visited_ids, block)
                self.{{key.id}}=(%result)
              end
            end
          {% end %}

          res = block.call(self)
          res.is_a?(self) ? res : self
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
