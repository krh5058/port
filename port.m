function port(varargin)
% port
% As requested by Kathleen Keller, Wendy Stein
%
% Author: Ken Hwang
% SLEIC, PSU
%
% See ReadMe.txt

s = false;

if nargin > 0
    switch varargin{1}
        case 'scramble'
            s = true; % Scramble
    end
end

if ~ispc
    error('port.m: PC support only.')
end

% Directory initialization
try
    fprintf('port.m: Directory initialization...\n')
    
    mainpath = which('main.m');
    if ~isempty(mainpath)
        [mainext,~,~] = fileparts(mainpath);
        rmpath(mainext);
    end
    
    javauipath = which('javaui.m');
    if ~isempty(javauipath)
        [javauiext,~,~] = fileparts(javauipath);
        rmpath(javauiext);
    end
    
    p = mfilename('fullpath');
    [ext,~,~] = fileparts(p);
    [~,d] = system(['dir /ad-h/b ' ext]);
    d = regexp(strtrim(d),'\n','split');
    cellfun(@(y)(addpath([ext filesep y])),d);
    fprintf('port.m: Directory initialization success!.\n')
catch ME
    throw(ME)
end

try
    fprintf('port.m: Object Handling...\n')
    % Object construction and initial key restriction
    obj = main(ext,d,s);
    fprintf('port.m: Object Handling success!.\n')
catch ME
    throw(ME)
end

if s
    result = obj.scrambleCall;
    disp(result);
else
    
    try
        fprintf('port.m: Window initialization...\n')
        % Open and format window
        obj.monitor.w = Screen('OpenWindow',obj.monitor.whichScreen,obj.monitor.white);
        Screen('BlendFunction',obj.monitor.w, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
        Screen('TextSize',obj.monitor.w,30);
        fprintf('port.m: Window initialization success!.\n')
    catch ME
        throw(ME)
    end
    
    if ~obj.debug
        ListenChar(2);
        HideCursor;
        ShowHideFullWinTaskbarMex(0);
    end
    
    % Prepare experimental conditions
    obj.loadImages;
    imgHeight = cellfun(@(y)(y(1)),cellfun(@size,obj.img,'UniformOutput',false));
    imgHeightMax = max(imgHeight(:));
    
    % Calibration routine
    fprintf('port.m: Beginning calibration sequence...\n')
    RestrictKeysForKbCheck([obj.exp.keys.esckey obj.exp.keys.upkey obj.exp.keys.downkey]);
    abortCal = 0;
    while ~abortCal

        obj.misc.tick1(obj.monitor,imgHeightMax);
        obj.misc.tick2(obj.monitor,imgHeightMax);
        obj.drwfix;
        obj.dispimg();
        
        [~,calKeyCode] = KbStrokeWait;
        
        % Adjust obj.monitor.u_center_H or escape
        if find(calKeyCode)==obj.exp.keys.upkey
            if obj.monitor.u_center_H-imgHeightMax/2 <= 0
            else
                obj.monitor.u_center_H = obj.monitor.u_center_H - 5;
            end
        elseif find(calKeyCode)==obj.exp.keys.downkey
            if obj.monitor.u_center_H+imgHeightMax/2 >= obj.monitor.rect(4)
            else
                obj.monitor.u_center_H = obj.monitor.u_center_H + 5;
            end
        elseif find(calKeyCode)==obj.exp.keys.esckey
            abortCal = 1;
        end
        
    end
    
    fprintf('port.m: Calibration sequence finished...\n')
    
    [obj.exp.presmat,obj.exp.presmatend] = obj.presCalc;
    tobj = tclass(obj.exp.keys.esckey);
    
    fprintf('port.m: Beginning presentation sequence...\n')
    
    for i = 1:obj.exp.order_n
        
        data.run = i;
        
        % Prepare intra-order parameters
        ii = 1;
        iii = 1;
        picflag = 1;
        prepflag = 1;
        dispflag = 1;
        data.order = obj.exp.order{i};
        %         order_i = data.order;
        %         data.order = order(i);
        %         pres_order = obj.shuffleSection;
    
        obj.dispimg(); % Clear screen
        
        % Wait for instructions
        RestrictKeysForKbCheck([obj.exp.keys.spacekey obj.exp.keys.esckey]);
        obj.disptxt(obj.exp.intro);
        [~,keyCode] = KbStrokeWait;
        
        % Abort if escape pressed during instructions screen
        if find(keyCode)==obj.exp.keys.esckey
           break; 
        end
        
        % Triggering
        obj.disptxt(obj.exp.intro1);
        if obj.exp.trig % Auto-trigger
            RestrictKeysForKbCheck(obj.exp.keys.tkey);
            KbStrokeWait; % Waiting for first trigger pulse, return timestamp
        else % Manual trigger
            RestrictKeysForKbCheck(obj.exp.keys.spacekey);
            KbStrokeWait; % Waiting for scanner operator
            obj.disptxt(obj.exp.intro2);
            pause(obj.exp.DisDaq); % Simulating DisDaq
        end
        
        RestrictKeysForKbCheck(obj.exp.keys.esckey);
        
        start(tobj.tmr);
        t0 = GetSecs;
        
        while (GetSecs - t0) < obj.exp.presmatend(i) % Continue until last time point
            
            % Draw & prepare
            if prepflag
                prepflag = 0;
                %         for ii = 1:length(pres_order)
                data.section = data.order(ii);
                pres_i = strcmp(data.section,obj.exp.section);
                %             for iii = 1:obj.exp.pres_n*2
                data.schedt = obj.getT(iii,ii,i);
                if picflag % Picture or fixation
                    if obj.debug
                        disp(['port.m (Debug): Expected image: ' data.section int2str(i) '_' int2str(ceil(iii/2))]);
                    end
                    
                    data.pres = [data.section int2str(i) '_' int2str(ceil(iii/2))];
                    
                    img = obj.img{i,pres_i,ceil(iii/2)};
                    tex = obj.drwimg(img);
                    picflag = 0;
                else
                    if obj.debug
                        disp('port.m (Debug): Expecting Fixation.');
                    end
                    
                    data.pres = 'Fixation';
                    
                    obj.drwfix;
                    picflag = 1;
                end
            end
            
            % Display & record
            if dispflag
                if (GetSecs - t0) > data.schedt % If time surpasses current onset
                    prepflag = 1; % Prep next
                    try
                        obj.dispimg();
                        
                        data.actt = GetSecs-t0;
                        
                        if obj.debug
                            disp(['port.m (Debug): Scheduled time: ' num2str(data.schedt)]);
                            disp(['port.m (Debug): VBL timestamp: ' num2str(data.actt)]);
                            
%                             disp(['port.m (Debug): Order value: ' int2str(data.order)]);
                            disp(['port.m (Debug): Image ID: ' data.pres]);
                            disp(['port.m (Debug): Presentation order value: ' int2str(ceil(iii/2))]);
                        end
                        
                        notify(obj,'record',evt(data));
                        
                    catch ME
                        disp(ME)
                    end
                    
                    if picflag
                        obj.closetex(tex);
                    end
                    
                    % Increase indices
                    if iii == obj.exp.pres_n*2 % Increase if not final presentation index
                        iii = 1; % Reset to 1 if final index
                        if ii == length(data.order) % Increase if not final section index
                            prepflag = 0; % Cancel last prep
                            dispflag = 0; % Stop displays
                        else
                            ii = ii + 1;
                        end
                    else
                        iii = iii + 1;
                    end
                    
                end
            end
            
            ud = get(tobj.tmr,'UserData');
            if ud.keyIsDown
                break;
            end
            
        end
        
        % End record
        data.section = [];
        data.schedt = [];
        data.actt = (GetSecs - t0);
        data.pres = 'End';
        notify(obj,'record',evt(data));
        
        stop(tobj.tmr);
        
        if ud.keyIsDown
            break;
        end
        
    end
    
%     obj.outWrite;
    
    % Clean up
    obj.outClose;
    RestrictKeysForKbCheck([]);
    tobj.delete;
    
    if ~obj.debug
        ListenChar(0);
        ShowCursor;
        ShowHideFullWinTaskbarMex(1);
    end
    
%     Screen('Preference','Verbosity',obj.monitor.oldVerbosityDebugLevel);
%     Screen('Preference','VisualDebugLevel',obj.monitor.oldVisualDebugLevel);
    fclose('all');
    Screen('CloseAll');
end
end