% Class "Bitsi"
%
% %Constructor%
% 
% Bitsi(comport)
%
% When creating a new 'bitsi' object, you can specify to which comport it
% is connected. On windows computers, this is usually something like
% 'com1'.
% When using an empty string for 'comport', the object will run in testing
% mode. In this case it's not required to have the BITSI physically
% connected to the computer. Responses will be read from the keyboard.
%
% *Methods*
% - sendTrigger(code)
% - getResponse(timeout, return_after_response)
% - clearResponses()
% - numberOfResponses()
% - close()
%
%
%
% *sendTrigger(code)*
% code - trigger code, allowed codes 1 - 255. This code is sent to the
% BITSI which will output it on it's parallel output port. The code will be
% reset after 10 miliseconds.
%
% * [response time] = getResponse(timeout, return_after_response)*
%
% This function will take maximally 'timeout' seconds to execute
% return_after_response - allowed values: true or false
%
% False:
% If return_after_response equals false, getResponse will wait for a fixed
% duration (timeout) and record the first response during the wait. The
% first response and it's timeout will be returned after the specified
% timeout.
%
%   <     timeout     >
%   +-----------------+
%   |          A      |
% --+          |      +----------------
%
%
%
% True:
% This method will return as soon as there is a response. Both
% the response and the timestamp of the response will be returned.
% If 'timeout' seconds have been expired without a response, a response
% of 0 will be returned.
%
%   <    timeout     >
%   +-----------+
%   |          A|
% --+          |+----------------
%
%
%
% *Example*
%
%  b = Bitsi('com1');
%
%  b.sendTrigger(20);
%
%  ... do more stuff here
%
%  [r t] = b.getResponse(10, false);
%
%  b.close();
%
%
% If the constructor is called with an empty com port string, no serial connection will be
% established. The serial commands will be echo'd to stdout:
%
%  b = Bitsi('')
%  ...
%
%


classdef Bitsi
    
    properties (SetAccess = public)
        serobj;
        debugmode = false;
    end
    
    methods
        function B = Bitsi(comport)
            if (strcmp(comport, ''))
                fprintf('Bitsi: No Com port given, running in testing mode...\n')
                B.debugmode = true;
                
                KbName('UnifyKeyNames');
            end
            
            if (not(B.debugmode))
                delete(instrfind);
                B.serobj = serial(comport);
                
                % serial port configuration
                set(B.serobj, 'Baudrate',        115200);
                set(B.serobj, 'Parity',          'none');
                set(B.serobj, 'Databits',        8);       % number of data bits
                set(B.serobj, 'StopBits',        1);       % number of stop bits
                %set(B.serobj, 'Terminator',      'CR/LF'); % line ending character
                % see also:
                % http://www.mathworks.com/matlabcentral/newsreader/view_original/292759
                
                %set(B.serobj, 'InputBufferSize', 1);       % set read buffBuffer for read
                set(B.serobj, 'FlowControl',     'none');   %
                
                % open the serial port
                fopen(B.serobj);
                
                % since matlab pulls the DTR line, the arduino will reset
                % so we have to wait for the initialization of the controller
                oldState = pause('query');
                pause on;
                pause(2.5);
                pause(oldState);
                
                % read all bytes available at the serial port
                status = '[nothing]';
                
                if B.serobj.BytesAvailable > 0
                    status = fread(B.serobj, B.serobj.BytesAvailable);
                end
                
                fprintf('BITSI says: %s', char(status));
                fprintf('\n');
            end
        end
        
        
        function sendTrigger(B, code)
            % checking code range
            if code > 255
                fprintf('Bitsi: Error, code should not exeed 255\n');
                return;
            end
            
            if code < 1
                fprintf('Bitsi: Error, code should be bigger than 0\n');
            end
            
            fprintf('Bitsi: trigger code %i\n', code);
            
            if ~B.debugmode
                fwrite(B.serobj, code)
            end
        end
        
        
        function x = numberOfResponses(B)
            x = B.serobj.BytesAvailable;
        end
        
        
        function clearResponses(B)
            numberOfBytes = B.serobj.BytesAvailable;
            if numberOfBytes > 0
                fread(B.serobj, numberOfBytes);
            end
        end

       
        function [response, timestamp]= getResponse(B, timeout, return_after_response)
            response = 0;
            % start stopwatch
            tic
            if (B.debugmode)
                while toc < timeout
                    % poll the state of the keyboard
                    [keyisdown, when, keyCode] = KbCheck;
                    
                    % if there wasn't a response before and there is a
                    % keyboard press available
                    if response == 0 && keyisdown
                        timestamp = when;
                        response = keyCode;
                        if return_after_response
                            break;
                        end
                    end
                end
            else
                
                % depending on 'return_after_response' this loop will run
                % for timeout seconds or until a response is given
                while toc < timeout && ( ~return_after_response || response == 0)
                    
                    % if there wasn't a response before and there is a
                    % serial character available
                    if response == 0 && B.serobj.BytesAvailable > 0
                        % capture the time and the response
                        timestamp = GetSecs;
                        response = fread(B.serobj, 1);
                        fprintf('Bitsi: response code %i\n', response);
                    end
                end
                
                % now we waited 'duration' seconds and there might be a
                % button captured, there may be some additional responses
                % in the serial buffer
                B.clearResponses();
            end
        end
        
        
        % close
        function close(B)
            if (not(B.debugmode))
                fclose(B.serobj);
                delete(B.serobj);
            end
        end
    end
end
