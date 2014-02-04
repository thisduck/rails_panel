module MetaRequest
  module Middlewares
    class MetaRequestHandler
      def initialize(app)
        @app = app
      end

      def call(env)
        request_id = env["PATH_INFO"][%r{/__meta_request/(.+)\.json$}, 1]
        if request_id
          events_json(request_id)
        else
          @app.call(env)
        end
      end

      private

      def events_json(request_id)
        events_json = Storage.new(request_id).read
        events_json = add_template_source_map_event(events_json)
        [200, { "Content-Type" => "text/plain; charset=utf-8" }, [events_json]]
      end

      def add_template_source_map_event(events_json)
        events = JSON.parse(events_json)

        template_source_map = template_source_map(events)

        transaction_id = events.first.transaction_id
        event = Event.new("meta_request.source_of_templates",0,0,transaction_id,{template_source_map: template_source_map})
        events << event
        
        events_json = events.to_json
      end

      def template_source_map(events)
        files = get_all_rendered_templates(events)    

        template_source_map = {}

        files.each do |file|
          template_source_map[file] = File.read(file)
        end

        template_source_map
      end

      def get_all_rendered_templates(events)
        templates = events.select { |event| ["render_partial.action_view","render_template.action_view"].include?(event.name) }
                          .map    { |event| 
                            if layout = event.payload.layout 
                              [get_absolute_path_of_layout(layout),event.payload.identifier] 
                            else
                              [event.payload.identifier] 
                            end
                          }
                          .flatten
                          .uniq  
      end

      def get_absolute_path_of_layout(layout)
        Dir["#{Rails.root}/app/views/*/**"].select { |f| f.include?(layout) }.first
      end

    end
  end
end
