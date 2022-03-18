function arduino_operate(command, delay_s, stim_ms, port)
    DEFAULT_COM = 'COM4';
    STIM_DUR = 300; % ms
    
    if nargin<4; port = DEFAULT_COM; end
    if nargin<3; stim_ms = STIM_DUR; end
    if nargin<2; delay_s = 0; end

    switch(lower(command))
        case 'start'
            send_serial('E 1000 1000');
        case 'end'
            send_serial('X 1000 1000');
        case 'stim_left'
            delay = num2str(ceil(delay_s)*1000); %convert s to ms
            send_serial(['L ' delay ' ' num2str(stim_ms)]);
        case 'stim_right'
            delay = num2str(ceil(delay_s)*1000); %convert s to ms
            send_serial(['R ' delay ' ' num2str(stim_ms)]);
        case 'reset'
            try
                s = serial(port,'DataTerminalReady','on');%Assert DTR to reset arduino
                fopen(s); fclose(s); delete(s);
                pause(2);%block for the arduino to reboot
            catch ME
                disp(ME.message);
            end
        otherwise
            error(['Not a recognized command: "' command '"']);
    end

    %%
    function send_serial(cmd)
        try
            s = serial(port,'DataTerminalReady','off',...
                'Terminator','CR/LF');%DTR is hard-wired to arduino reset so keep it off
            fopen(s);
            fwrite(s,cmd);
            while s.BytesAvailable==0; end
            ack = fgetl(s);
            if ~strcmp(ack,cmd)
                warning(['For cmd <' cmd '> , diff ack : <' char(ack) '>'])
            end
        catch ME
            disp(ME.message);
        end
        try fclose(s); delete(s); catch ME; disp(ME.message); end
    end
end

