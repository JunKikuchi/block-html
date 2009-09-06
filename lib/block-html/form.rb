class BlockHTML
  class Form < BlockHTML
    def tag(tag, attrs={}, &block)
      self << Tag.new(nil, tag, attrs, @env_instance, &block)
    end

    def form(attrs={}, &block)
      tag(:form, attrs, &block)
    end

    class Tag < BlockHTML::Tag
      def initialize(model, name, attrs={}, env_instance=nil, &block)
        @model = model
        super(name, attrs, env_instance, &block)
      end

      def tag(tag, attrs={}, &block)
        self << Tag.new(@model, tag, attrs, @env_instance, &block)
      end

      def model(model, &block)
        @model = model
        block.call(self)
        @model = nil
      end

      def errors(name, params={})
        return if @model.nil? || @model.errors[name].empty?

        tag(:div, params) {
          @model.errors.on(name).each do |val|
            tag(:p).text(val)
          end
        }
      end

      def edit(name, params={})
        self << Element::Input.new(@model, name, params, :text)
      end

      def password(name, params={})
        self << Element::Input.new(@model, name, params, :password)
      end

      def submit(name, params={})
        self << Element::Input.new(@model, name, params, :submit)
      end

      def checkbox(name, params={})
        self << Element::Checkbox.new(@model, name, params)
      end
    end

    class Element < BlockHTML
      def initialize(model, name, params)
        super()
        @model, @name, @params = model, name, params
        @id = @params[:id] || @name,
        @value = @model ? @model.__send__(@name) : @params[:value]
      end

      class Input < Element
        def initialize(model, name, params, type)
          super(model, name, params)
          tag :input,
            :type  => type,
            :id    => @id,
            :name  => name,
            :value => @value
        end
      end

      class Checkbox < Element
        def initialize(model, name, params)
          super(model, name, params)
          attrs = {
            :type  => 'checkbox',
            :id    => @id,
            :name  => name
          }
          attrs[:checked] = '' if @value
          tag :input, attrs
        end
      end
    end
  end
end
