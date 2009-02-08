class BlockHTML
  def self.normalize_model_name(model)
    model.class.name.gsub(/::/, '_').downcase
  end

  def normalize_params(_name, params)
    if @model.nil?
      id   = params[:id] || _name
      name = _name
    else
      model_name = self.class.normalize_model_name(@model)
      id   = params[:id] || "#{model_name}_#{_name}"
      name = "#{model_name}[#{_name}]"
    end

    value   = @model[_name.to_sym] unless @model.nil?
    value ||= params[:value] || params[:default] || nil

    label = params[:label] || _name

    errors   = @model.errors[_name.to_sym] unless @model.nil?
    errors ||= params[:error] || []

    [id, name, value, label, errors]
  end
  private :normalize_params

  def error_tag(bhtml, errors)
    bhtml.tag(:div, :class => :form_error_messages) do |div|
      errors.each do |error|
        div.tag(:p, :class => :form_error_message) do |_p|
            _p.text error
        end
      end
    end unless errors.empty?
  end
  private :error_tag

  def form(attrs={}, &block)
    tag :form, attrs do |form|
      form.tag :dl, &block
    end
  end

  def for(model, &block)
    @model = model
    block.call self
    @model = nil
  end

  #
  # params[:id]
  # params[:value]
  # params[:default]
  # params[:label]
  #
  def edit(_name, params={})
    id, name, value, label, errors = normalize_params(_name, params)

    tag(:dt).tag(:label, :for => id).text label
    tag(:dd) do |dd|
      dd.tag :input,
        :type  => :text,
        :id    => id,
        :name  => name,
        :value => value
      error_tag(dd, errors)
    end
  end

  def password(_name, params={})
    id, name, value, label, errors = normalize_params(_name, params)

    tag(:dt).tag(:label, :for => id).text label
    tag(:dd) do |dd|
      dd.tag :input,
        :type => :password,
        :id   => id,
        :name => name
      error_tag(dd, errors)
    end
  end

  def checkbox(_name, params={})
    id, name, value, label, errors = normalize_params(_name, params)

    attrs = {
      :type => 'submit',
      :id   => id,
      :name => name
    }
    attrs[:checked] = '' if value

    tag(:dt).tag(:label, :for => id).text label
    tag(:dd) do |dd|
      dd.tag :input, attrs
      error_tag(dd, errors)
    end
  end

  def submit(_name, params={})
    id, name, value, label, errors = normalize_params(_name, params)

    tag(:dt).text
    tag(:dd) do |dd|
      dd.tag :input,
        :type  => :submit,
        :id    => id,
        :name  => name,
        :value => label || name
      error_tag(dd, errors)
    end
  end
end
