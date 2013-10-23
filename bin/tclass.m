classdef tclass < handle
  properties
      tmr
  end
  methods
      function this = tclass(key)
          warning('OFF','MATLAB:TIMER:RATEPRECISION');
          this.tmr = timer('TimerFcn', @tclass.timer_callback, 'Period', 1/30, 'ExecutionMode', 'fixedSpacing');
          ud.key = key;
          ud.keyIsDown = 0;
          set(this.tmr,'UserData',ud); % Default
      end
      function delete(this)
          stop(this.tmr);
          delete(this.tmr);
          warning('ON','MATLAB:TIMER:RATEPRECISION');
      end
  end
  methods (Static)
      function timer_callback(h,e)
          ud = get(h,'UserData');
          [ud.keyIsDown,~,keyCode]=KbCheck; % Re-occuring check
          if ud.keyIsDown
              if find(keyCode)==ud.key
                  disp(['tclass.m (timer_callback): Key pressed -- ' KbName(ud.key)]);
                  set(h,'UserData',ud);
              end
          end
      end
  end
end