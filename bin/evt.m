classdef evt < event.EventData
    properties
        run % Run value
        schedt % Scheduled (s)
        actt % Actual (s)
        order % Current order
        section % Current section
        pres % Current presentation
    end
    
  methods
    function this = evt(data)
      try
          f = fieldnames(data);
          for i = 1:length(f)
              this.(f{i}) = data.(f{i});
          end
      catch ME
          throw(ME);
      end
    end
  end
    
end

