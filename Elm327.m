classdef Elm327 < handle
    % Patrucco, 27/12/2019
    % General-purpose class for interfacing with an ELM327 or compatible
    % serial device through Matlab
    
    properties
        LogFile = 'Log.txt';
        LogMatFile = 'Log.mat';
        LogMatEnabled = true;
        RecHistory = [];
        Serial = [];
        SerialPort = 'COM33';
        BaudRate = 38400;
        Terminator = 'CR/LF';
        PollList = [];
        PollTimeoutSeconds = 30;
        ReadTimeoutSeconds = 5;
        PollingEnabled = false;
        DatetimeLogFormat = 'YYYY-mm-dd HH:MM:SS.fff';
        LastReceived = '';
        LastDecoded = [];
    end
    
    methods
        
        % Add new log entry and directly write to log file.
        function add_log(obj, logtype, data)
            log_f = fopen(obj.LogFile, 'a');
            str2p = [datestr(now, obj.DatetimeLogFormat), '\t', logtype, '\t', data, '\n'];
            fprintf(log_f, str2p);
            fclose(log_f);
        end
        
        % Add a new id to poll list. It should be possible to do this
        % externally in a dynamic way.
        function add_to_poll_list(obj, id_add)
            already_in_list = false;
            for i_id = 1:length(obj.PollList)
                if (obj.PollList(i_id) == id_add)
                    already_in_list = true;
                    break;
                end
            end
            if ~already_in_list
                obj.PollList = [obj.PollList, id_add];
                add_log(obj, 'POLL_MNG', ['Added id ', num2str(id_add) ' to Poll List']);
            else
                warning('Tried to add ID which already was in Poll List');
            end
        end
        
        function remove_from_poll_list(obj, id_rm)
            already_in_list = false;
            for i_id = 1:length(obj.PollList)
                if (obj.PollList(i_id) == id_rm)
                    already_in_list = true;
                    break;
                end
            end
            if already_in_list
                obj.PollList(obj.PollList == id_rm) = [];
                add_log(obj, 'POLL_MNG', ['Removed id ', num2str(id_rm) ' from Poll List']);
            else
                warning('Tried to remove ID which was not in Poll List');
            end
        end
        
        % Open serial port
        function open(obj)
            obj.Serial = serial(obj.SerialPort, 'BaudRate', obj.BaudRate, 'Terminator', obj.Terminator);
            fopen(obj.Serial);
            add_log(obj, 'SERIAL', ['Serial Port ', obj.SerialPort, ' opened at ', num2str(obj.BaudRate) ' baud.']);
        end
        
        % Send basic commands to the device in order to ensure proper
        % format is respected.
        function initialize(obj)
            if ~isempty(obj.Serial)
                c0 = write_and_read(obj, 'ATZ', false); % reset device.
                c1 = write_and_read(obj, 'ATSP0', false); % set protocol to 0
                c2 = write_and_read(obj, 'ATH0', false); % disable headers.
                if (c0 && c1 && c2)
                    add_log(obj, 'INIT', 'Elm327 initialized with ATZ - ATSP0 - ATH0 sequence.');
                else
                    warning('Initialization did not complete correctly');
                    add_log(obj, 'INIT', 'Elm327 was not correctly initialized.');
                end
            else
                error('Attempt to initialize Elm327 before Serial object was created');
            end
        end
        
        % Writes any command and locally saves the answer.
        % This approach is possible because Elm327 devices, at least when
        % operating in a diagnostic mode, parse a command and immediately
        % return output.
        function out = write_and_read(obj, data, decode_output)
            if ~isempty(obj.Serial)
                fprintf(obj.Serial, data);
                add_log(obj, 'TX', data);
                lastchar = ' ';
                response = '';
                start_time = now;
                out = false;
                while ((lastchar ~= '>') && (now < start_time + obj.ReadTimeoutSeconds/(24*3600)))
                    if obj.Serial.BytesAvailable > 0
                        raw_bytes = fread(obj.Serial, obj.Serial.BytesAvailable);
                        response_string = char(raw_bytes');
                        response = [response, response_string];
                        lastchar = response(end);
                    end
                end
                resp_to_print = response;
                % TODO: handle this in a more flexible way.
                resp_to_print(resp_to_print == char(13)) = '_';
                add_log(obj, 'RX', resp_to_print);
                obj.LastReceived = response;
                notify(obj, 'NewReceived');
                if ~isempty(response)
                    out = response(end) == '>';
                    % TODO: Move decoding into "poll_id"
                    if decode_output
                        try
                            obj.LastDecoded = msg_parser(response);
                            disp(obj.LastDecoded);
                            notify(obj, 'NewDecoded');
                        catch
                            warning('Could not decode packet');
                        end
                    end
                else
                    out = false;
                end
            else
                error('Attempt to write on device before Serial object was created');
            end
        end
        
        % Poll the value of a single message id
        function out = poll_id(obj, obd_id)
            hex_id = upper(dec2hex(obd_id, 2));
            % "01" to ask for code "hex_id", final "1" to specify we are
            % waiting a single output.
            str2send = ['01', hex_id, '1'];
            out = write_and_read(obj, str2send, true);
            obj.RecHistory = [obj.RecHistory; obj.LastDecoded];
            if obj.LogMatEnabled
                elm_log = obj.RecHistory;
                save(obj.LogMatFile, 'elm_log', '-v6');
            end
        end
        
        % Poll all the signals in PollList
        function poll(obj)
            obj.PollingEnabled = true;
            start_time = now;
            add_log(obj, 'POLL', 'Start of Polling operation');
            % double check is useless. It gets instantly "busy"
            while ((now - start_time < obj.PollTimeoutSeconds/(24*3600)) && obj.PollingEnabled)
                for i_id = 1:length(obj.PollList)
                    poll_out = poll_id(obj, obj.PollList(i_id));
                    if ~poll_out
                        warning(['Polling id ', num2str(obj.PollList(i_id)), ' returned false.']);
                    end
                end
            end
            add_log(obj, 'POLL', 'End of Polling operation due to reached timeout/interruption.');
        end
        
        % Close port
        function close(obj)
            fclose(obj.Serial);
            add_log(obj, 'SERIAL', 'Serial Port closed.');
        end
        
        
    end
    
    events
        NewReceived;
        NewDecoded;
    end
end