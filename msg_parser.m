function out_struct = msg_parser(msg)
% Patrucco, 27/12/2019
% Parses the output of an id request to the Elm 327 device.
% Does NOT support checksum in final message.

out_struct = struct();

msg_s = split(msg, char(13));
out_struct.head = hex2dec(msg_s{1}(3:4));
out_struct.bytes = parse_spaced_hex(msg_s{2});
out_struct.special = false; % to avoid concatenating special requests.

switch out_struct.head
    % TODO: Test this
    case 0
        out_struct.special = true;
        out_struct.descr = 'pid_support_01_32';
        out_struct.val = zeros(1, 32);
        num_enc = 0;
        for i_pow = 0:3
            num_enc = num_enc + out_struct.bytes(end - i_pow) * (2^i_pow);
        end
        for i_pid = 0:31
            out_struct.val(i_pid + 1) = test_bit(num_enc, i_pid);
        end
        
    % TODO: Implement parser.
    case 1
        out_struct.special = true;
        out_struct.descr = 'DTC_status';
        num_enc = 0;
        for i_pow = 0:3
            num_enc = num_enc + out_struct.bytes(end - i_pow) * (2^i_pow);
        end
        out_struct.val = struct();
        out_struct.val.MIL = test_bit(num_enc, 31);
        out_struct.val.DTC_CNT = bitand(bitshift(num_enc, -24), 2^7);
        out_struct.val.RESERVED_0 = test_bit(num_enc, 23);
        out_struct.val.IsDieselEngine = test_bit(num_enc, 19);
        out_struct.val.Components = struct();
        out_struct.val.Components.TestAvailable = test_bit(num_enc, 18);
        out_struct.val.Components.TestIncomplete = test_bit(num_enc, 22);
        out_struct.val.FuelSystem = struct();
        out_struct.val.FuelSystem.TestAvailable = test_bit(num_enc, 17);
        out_struct.val.FuelSystem.TestIncomplete = test_bit(num_enc, 21);
        out_struct.val.Misfire = struct();
        out_struct.val.Misfire.TestAvailable = test_bit(num_enc, 16);
        out_struct.val.Misfire.TestIncomplete = test_bit(num_enc, 20);
        if out_struct.val.IsDieselEngine
            out_struct.val.EGRorVVTSystem = struct();
            out_struct.val.EGRorVVTSystem.TestAvailable = test_bit(num_enc, 15);
            out_struct.val.EGRorVVTSystem.TestIncomplete = test_bit(num_enc, 7);
            out_struct.val.PMFilterMonitoring = struct();
            out_struct.val.PMFilterMonitoring.TestAvailable = test_bit(num_enc, 14);
            out_struct.val.PMFilterMonitoring.TestIncomplete = test_bit(num_enc, 6);
            out_struct.val.ExhaustGasSensor = struct();
            out_struct.val.ExhaustGasSensor.TestAvailable = test_bit(num_enc, 13);
            out_struct.val.ExhaustGasSensor.TestIncomplete = test_bit(num_enc, 5);
            out_struct.val.RESERVED_1 = struct();
            out_struct.val.RESERVED_1.TestAvailable = test_bit(num_enc, 12);
            out_struct.val.RESERVED_1.TestIncomplete = test_bit(num_enc, 4);
            out_struct.val.BoostPressure = struct();
            out_struct.val.BoostPressure.TestAvailable = test_bit(num_enc, 11);
            out_struct.val.BoostPressure.TestIncomplete = test_bit(num_enc, 3);
            out_struct.val.RESERVED_2 = struct();
            out_struct.val.RESERVED_2.TestAvailable = test_bit(num_enc, 10);
            out_struct.val.RESERVED_2.TestIncomplete = test_bit(num_enc, 2);
            out_struct.val.NOxSCRMonitor = struct();
            out_struct.val.NOxSCRMonitor.TestAvailable = test_bit(num_enc, 9);
            out_struct.val.NOxSCRMonitor.TestIncomplete = test_bit(num_enc, 1);
            out_struct.val.NMHCCatalyst = struct();
            out_struct.val.NMHCCatalyst.TestAvailable = test_bit(num_enc, 8);
            out_struct.val.NMHCCatalyst.TestIncomplete = test_bit(num_enc, 0);
        else
            out_struct.val.EGRSystem = struct();
            out_struct.val.EGRSystem.TestAvailable = test_bit(num_enc, 15);
            out_struct.val.EGRSystem.TestIncomplete = test_bit(num_enc, 7);
            out_struct.val.O2SensorHeater = struct();
            out_struct.val.O2SensorHeater.TestAvailable = test_bit(num_enc, 14);
            out_struct.val.O2SensorHeater.TestIncomplete = test_bit(num_enc, 6);
            out_struct.val.O2Sensor = struct();
            out_struct.val.O2Sensor.TestAvailable = test_bit(num_enc, 13);
            out_struct.val.O2Sensor.TestIncomplete = test_bit(num_enc, 5);
            out_struct.val.ACRefrigerant = struct();
            out_struct.val.ACRefrigerant.TestAvailable = test_bit(num_enc, 12);
            out_struct.val.ACRefrigerant.TestIncomplete = test_bit(num_enc, 4);
            out_struct.val.SecondaryAirSystem = struct();
            out_struct.val.SecondaryAirSystem.TestAvailable = test_bit(num_enc, 11);
            out_struct.val.SecondaryAirSystem.TestIncomplete = test_bit(num_enc, 3);
            out_struct.val.EvaporativeSystem = struct();
            out_struct.val.EvaporativeSystem.TestAvailable = test_bit(num_enc, 10);
            out_struct.val.EvaporativeSystem.TestIncomplete = test_bit(num_enc, 2);
            out_struct.val.HeatedCatalyst = struct();
            out_struct.val.HeatedCatalyst.TestAvailable = test_bit(num_enc, 9);
            out_struct.val.HeatedCatalyst.TestIncomplete = test_bit(num_enc, 1);
            out_struct.val.Catalyst = struct();
            out_struct.val.Catalyst.TestAvailable = test_bit(num_enc, 8);
            out_struct.val.Catalyst.TestIncomplete = test_bit(num_enc, 0);
        end
    
    case 2
        out_struct.val = out_struct.bytes;
        out_struct.descr = 'Freeze_DTC';
    
    case 3
        out_struct.special = true;
        out_struct.descr = 'Fuel_system_status';
        fs1 = out_struct.bytes(end - 1);
        fs2 = out_struct.bytes(end);
        out_struct.val = struct();
        out_struct.val.FuelSystem1 = struct();
        out_struct.val.FuelSystem1.num = fs1;
        if fs1 == 1
            out_struct.val.FuelSystem1.status = 'Open loop due to insufficient engine temperature';
        elseif fs1 == 2
            out_struct.val.FuelSystem1.status = 'Closed loop, using oxygen sensor feedback to determine fuel mix';
        elseif fs1 == 4
            out_struct.val.FuelSystem1.status = 'Open loop due to engine load OR fuel cut due to deceleration';
        elseif fs1 == 8
            out_struct.val.FuelSystem1.status = 'Open loop due to system failure';
        elseif fs1 == 16
            out_struct.val.FuelSystem1.status = 'Closed loop, using at least one oxygen sensor but there is a fault in the feedback system';
        end
        out_struct.val.FuelSystem2 = struct();
        out_struct.val.FuelSystem2.num = fs2;
        if fs2 == 1
            out_struct.val.FuelSystem2.status = 'Open loop due to insufficient engine temperature';
        elseif fs2 == 2
            out_struct.val.FuelSystem2.status = 'Closed loop, using oxygen sensor feedback to determine fuel mix';
        elseif fs2 == 4
            out_struct.val.FuelSystem2.status = 'Open loop due to engine load OR fuel cut due to deceleration';
        elseif fs2 == 8
            out_struct.val.FuelSystem2.status = 'Open loop due to system failure';
        elseif fs2 == 16
            out_struct.val.FuelSystem2.status = 'Closed loop, using at least one oxygen sensor but there is a fault in the feedback system';
        end
    
    case 4
        out_struct.val = out_struct.bytes(end) * 100 / 255;
        out_struct.descr = 'calculated_engine_load';
    
    case 5
        out_struct.val = out_struct.bytes(end) - 40;
        out_struct.descr = 'engine_coolant_temperature';
        
    case 6
        out_struct.val = out_struct.bytes(end) * (100 / 128) - 100;
        out_struct.descr = 'short_term_fuel_trim_bank_1';
        
    case 7
        out_struct.val = out_struct.bytes(end) * (100 / 128) - 100;
        out_struct.descr = 'long_term_fuel_trim_bank_1';
        
    case 8
        out_struct.val = out_struct.bytes(end) * (100 / 128) - 100;
        out_struct.descr = 'short_term_fuel_trim_bank_2';
        
    case 9
        out_struct.val = out_struct.bytes(end) * (100 / 128) - 100;
        out_struct.descr = 'long_term_fuel_trim_bank_2';
        
    case 10
        out_struct.val = 3 * out_struct.bytes(end);
        out_struct.descr = 'fuel_pressure_kpa';
        
    case 11
        out_struct.val = out_struct.bytes(end);
        out_struct.descr = 'intake_air_pressure_abs_kpa';
        
    case 12
        out_struct.val = (256*out_struct.bytes(end - 1) + out_struct.bytes(end)) / 4;
        out_struct.descr = 'engine_rpm';
    
    case 13
        out_struct.val = out_struct.bytes(end);
        out_struct.descr = 'speed_kmh';
    
    case 14
        out_struct.val = out_struct.bytes(end) / 2 - 64;
        out_struct.descr = 'timing_advance_deg_tdc';
        
    case 15
        out_struct.val = out_struct.bytes(end) - 40;
        out_struct.descr = 'intake_air_temperature';
        
    case 16
        out_struct.val = (256*out_struct.bytes(end - 1) + out_struct.bytes(end)) / 100;
        out_struct.descr = 'MAF_air_flow';
        
    case 17
        out_struct.val = out_struct.bytes(end) * (100 / 255);
        out_struct.descr = 'throttle_position';
    
end

    function vct = parse_spaced_hex(spc)
        v1 = split(spc, ' ');
        vct = zeros(size(v1));
        for ii = 1:length(v1)-1
            vct(ii) = hex2dec(v1(ii));
        end
        vct(end) = [];
    end

    function test_out = test_bit(num_in, b)
        test_out = logical(bitshift(bitand(num_in, 2^b), - b));
    end

    
end