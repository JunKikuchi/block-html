module Innate
  module View
    register 'Innate::View::BlockHTML', :bhtml

    module BlockHTML
      def self.call(action, string)
        string = transform_string(action, string) if action.view
        return string, 'text/html'
      end

      def self.transform_string(action, string)
        action.instance.instance_eval do
          args = action.params
          instance_eval(string)
        end
      end
    end
  end
end
