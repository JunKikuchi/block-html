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

      def edit(name, attrs={})
        self << Element::Input.new(
          @model,
          attrs.merge(:name => name, :type => :text)
        )
      end

      def password(name, attrs={})
        self << Element::Password.new(
          @model,
          attrs.merge(:name => name, :type => :password)
        )
      end

      %w(file hidden).each do |type|
        class_eval %Q{
          def #{type}(name, attrs={})
            self << Element::Input.new(
              @model,
              attrs.merge(:name => name, :type => :#{type})
            )
          end
        }
      end

      %w(submit reset button radio).each do |type|
        class_eval %Q{
          def #{type}(name, attrs={})
            self << Element::Button.new(
              @model,
              attrs.merge(:name => name, :type => :#{type})
            )
          end
        }
      end

      def checkbox(name, attrs={})
        self << Element::Checkbox.new(
          @model,
          attrs.merge(:name => name, :type => :checkbox)
        )
      end
    end

    class Element < BlockHTML
      def initialize(model, attrs)
        super()
        @model = model
        @attrs = attrs
        @name  = @attrs[:name]
        @id    = @attrs[:id] || @name
        @value = @model ? @model.__send__(@name) : @attrs[:value]
      end

      class Input < Element
        def initialize(model, attrs)
          super(model, attrs)
          tag(:input, @attrs.merge(:id => @id, :value => @value))
        end
      end

      class Password < Element
        def initialize(model, attrs)
          super(model, attrs)
          tag(:input, @attrs.merge(:id => @id, :value => ''))
        end
      end

      class Button < Element
        def initialize(model, attrs)
          super(model, attrs)
          tag(:input, @attrs.merge(:id => @id, :value => @value || @name))
        end
      end

      class Checkbox < Element
        def initialize(model, attrs)
          super(model, attrs)
          tag(:input, @value ? @attrs.merge(:checked => '') : @attrs)
        end
      end
    end
  end
end
