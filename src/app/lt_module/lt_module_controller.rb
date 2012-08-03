class LtModuleController < ApplicationController
  set_model 'LtModuleModel'
  set_view  'LtModuleView'

  attr_accessor :timers, :timer_mutex

  def load(*args)
    @timer_mutex = Mutex.new if @timer_mutex.nil?
    unless args.compact.empty?
      options = Hash[*args.flatten]
      if options.has_key?(:model)
        model = options[:model]
        update_model(model, *model.attributes)
      end
    end
  end

  def activate_module(model)
    @timer_mutex.synchronize do
      @timers.each(&:cancel) unless @timers.nil?
      @timers       = []
      unless model.scroll_text.nil?
        timer = EM::PeriodicTimer.new(0.150) do
          unless model.scroll_text.nil?
            model.text = model.scroll_text.slice(model.scroll_index, 12)
            model.text += model.scroll_text.slice(0, 12 - model.text.size) if model.text.size < 12
            model.scroll_index += 1
            model.scroll_index = model.scroll_index % model.scroll_text.size
            update_model(model, *model.attributes)
            update_view
          end
        end
        @timers << timer
      end
    end
    update_model(model, *model.attributes)
    update_view
  end
end