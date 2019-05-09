% Basic script that analyzes robot data
% Experiment type: by conditions (ex. speed)

% Version 1. HJH

% statedata
% 1 viewmenu    5 movingout     9  intertrial     13 exitgame
% 2 startgame   6 attarget      10 warning
% 3 home        7 finishmvt     11 game_message
% 4 wait4mvt    8 movingback    12 rest

%%%### Figures have been excluded and have been commented out using '%%%###'
clear all
global plot_graphs
plot_graphs = 0;
%% Experiment specific details
projpath = 'd:\Users\Gary\Desktop\Neuromech Functions';
addpath(projpath);

expname = 'Example';

datafolder_names = [projpath '\Data'];
expfolder= [projpath];

filename = 'Example';
fprintf('%s \n',filename);

%Pulls the names of the data from the data folder and stores in an array
cd(datafolder_names);
[status,list]=system('dir /B');
list=textscan(list,'%s','delimiter','/n');

subjarray = list{1}(1:2);
subjtoload = 1:2;
nsubj=length(subjtoload);
cd(expfolder);
conditions={'fml' '0' '3' '5' '8'};
% If you want unordered need to create conditions for each subject:
% conditions{1}={'fml' '0' '3' '5' '8'};
nc=length(conditions);

ColorSet = parula(nsubj);

% end threshold for movement end, one for each condition
endthres = 0.015*ones(1,nc);
% Threshold for target distance
tarthres = 0.10*ones(1,nc);
% vthres for movement onsets, one for each condition
vthres = 0.01*ones(1,nc);

% protocol details
popts.practicetrials = 0; % # familiarization trials, without metabolic data
popts.totaltrials = 400;  % # total trials

fsR=200; tsR=1/fsR; % robot sampling frequency

ropts.rotate = 0;
ropts.switchhometar = 0;
ropts.longtrialtime_frames = 5*fsR; %4 seconds

scrsz = get(0,'ScreenSize');
color2use = {'k' 'b' 'r' 'g' 'm' 'c' 'k' 'b' 'r' 'g' 'm' 'c'};

%% Load Robot Data
%  Get robot info
[ropts.statenames, ropts.avstatenames, ropts.robotvars] = get_robotinfo(expname);

T{nc,nsubj} = []; Ev{nc,nsubj} = []; Data{nc,nsubj} = []; MT{nc,nsubj} = [];
% datafolder = cell(1,nsubj);

for subj = 1:nsubj
    subjid = subjarray{subjtoload(subj)};
    for c = 1:nc
        condition{c,subj} = conditions{c};
        
        datafolder{c,subj} = [datafolder_names filesep subjid filesep subjid '_' condition{c,subj}];
        
        num_trials{c,subj} = 400;
    end
end

for subj = 1:nsubj
    subjid = subjarray{subjtoload(subj)};
    for c = 1:nc
        cd(datafolder{c,subj})
    end
    for c = 1:nc
        % read robot .dat files
        T{c,subj}=dataread_robot(subjid,datafolder{c,subj});
    end
    for c = 1:nc
        
        % Get robot events
        Ev{c,subj} = get_robotevents(T{c,subj}.framedata, ropts.statenames, ropts.avstatenames);

        % Data is structure of matrices concatenated from T.framedata
        % Then remove framedata field from T
        [Data{c,subj}, Ev{c,subj}] = analyze_robot_basic(T{c,subj}, Ev{c,subj}, ropts,c,subj);

        % Get movement position and velocity
        Data{c,subj}.v = (Data{c,subj}.vx.^2+Data{c,subj}.vy.^2).^0.5;
        Data{c,subj}.p = ((Data{c,subj}.x).^2 + (Data{c,subj}.y).^2).^0.5;

        % Get velocity by differentiating position (Data.v is bumpy)
        Data{c,subj} = get_vsign(Data{c,subj},num_trials{c,subj});
                
    end
    for c = 1:nc
        % Get movement times
        [MT{c,subj},Data{c,subj}] = get_mvttimes_2018(Data{c,subj}, Data{c,subj}.v_sign, Data{c,subj}.p, Ev{c,subj}, vthres(c), endthres(c), tarthres(c),c,subj);
        fprintf('Subject %g %s Condition %s Processed\n',subj,subjid,condition{c,subj});
    end
end
