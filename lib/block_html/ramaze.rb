module Ramaze
  module Template
    class BlockHTML < Template
      ENGINES[self] = %w[blockhtml, bhtml]

      class << self
        def transform(action)
          template = wrap_compile(action)
          action.instance.instance_eval(template, action.template || __FILE__)
        end

        def compile(action, template)
          template
        end
      end
    end
  end
end
