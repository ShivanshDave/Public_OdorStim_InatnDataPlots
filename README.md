# Public_OdorStim_InatnDataPlots
Used in EAG recordings from M.sexta antennae 

1. Odor-delivery ( Matlab --Serial-->> Arduino -->> 3-way valves )
    - arduino_code_odor_delivery (upload to arduino)
    - run : `odor_stim`
1. Intan Data Read-Plot Matlab 
    - Read & Plot EAG : `read_raw_data`
1. gui-settings : EAG recording settings
1. Simple `.RHD` data read from Matlab ( RHD_MATLAB_functions (from Intan) > read_Intan_RHD2000_file.m )


Note :
  - RHD matlab toolbox not used. That can be useful (Intan > Software > Legacy Codes)
  - New RHX software not used, that can do live-stream of signals
