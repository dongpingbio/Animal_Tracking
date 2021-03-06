% function [] = camsetup(varargin)

clc; close all; clear;

% thisfile = 'camsetup2.m';
% thisfilepath = fileparts(which(thisfile));
% cd(thisfilepath);
% 
% fprintf('\n\n Current working path set to: \n % s \n', thisfilepath)
%     
% pathdir0 = thisfilepath;
% pathdir1 = [thisfilepath '../'];
% pathdir2 = [thisfilepath '../optotrackmedia'];
% gpath = [pathdir0 ':' pathdir1 ':' pathdir2];
% addpath(gpath)


%% USER-ENTERED PARAMETERS

total_trials = 10;

framesPerTrial = 3;

imageType = 'rgb';      % 'rgb' or 'grayscale'

threshmask = .50;

npixels = 100;  % Number of 'hot' pixels to average to find center


%% PREALLOCATE DATA COLLECTORS

imSizeX = 1280;
imSizeY = 720;


trial_data.tone_start = [];
trial_data.tone_end = [];

FramesTS = [];

Frames = zeros(imSizeY,imSizeX,length(trial_data)*8);
% Frames = zeros(imSizeY,imSizeX,3,length(trial_data)*8);

ff = 1;

%% ACQUIRE IMAGE ACQUISITION DEVICE (THERMAL CAMERA) OBJECT

out = imaqfind;
for nn = 1:length(out)
    stop(out(nn))
    wait(out(nn));
    delete(out(nn));
end

% imaqtool
vidObj = videoinput('macvideo', 1, 'YCbCr422_1280x720'); % CHANGE THIS TO THERMAL DEVICE ID
% vidObj = videoinput('winvideo', 1, 'UYVY_720x480'); % default
src = getselectedsource(vidObj);

vidObj.LoggingMode = 'memory';

vidObj.ReturnedColorspace = imageType;

vidObj.TriggerRepeat = total_trials * framesPerTrial + framesPerTrial;
vidObj.FramesPerTrigger = 1;
triggerconfig(vidObj, 'manual');

start(vidObj);



%% START IMAGE ACQUISITION LOOP

xy=[0 0];

tic
for trial = 1:total_trials
    
    fprintf('\n Starting trial: %d \n', trial);
        
    % Get timing of trial start
    trial_data.tone_start(trial,1) = toc;
    
    for nn = 1:framesPerTrial
        
        pause(.5)
        trigger(vidObj);
        [frame, ts] = getdata(vidObj, vidObj.FramesPerTrigger);
        
        FramesTS(end+1) = ts;
        
        
        IMG = rgb2gray(frame);
        IMG = im2double(IMG);
        
        % Frames(:,:,:,ff) = IMG;
        Frames(:,:,ff) = IMG;
        
        
        % FIND ALL NON-ZERO PIXELS (PIXELS ABOVE THRESHOLD)
        [row,col,val] = find(IMG); 
        RCV = [row,col,val];
        
        % SORT BY PIXEL BRIGHTNESS (HIGH TO LOW)
        [YXv, index] = sortrows(RCV,-3); 
        
        % GET THE COLUMN (X) AND ROW (Y) INDEX OF THE HOTTEST PIXELS
        % MEAN OF THOSE PIXEL COORDINATES IS GEOMETRIC CENTER
        xcol = mean( YXv(1:npixels,2) );
        yrow = mean( imSizeY - YXv(1:npixels,1) );
        xy(ff,:) = [xcol yrow];
        
        ff=ff+1;
    end
    

    % send_to_daq('solenoid_1',.015);

    % Get timing of trial end
    trial_data.tone_end(trial,1) = toc;
    
    fprintf('\n Ending trial: %d \n', trial);
    
end

stop(vidObj); 
wait(vidObj);

out = imaqfind;
for nn = 1:length(out)
    stop(out(nn))
    wait(out(nn));
    delete(out(nn));
end

%% Save data

% outfile=sprintf('FC_Day1_s%s_%s.mat', subject_id, date);
% save([sub_dir, '/' outfile],'trial_data', 'Frames', 'FramesTS', 'FrameOrd');


%% OPTIONAL: Play VIDEO overlaying tracking position over rat to check accuracy
close all

fh1=figure('Units','normalized','OuterPosition',[.1 .1 .6 .7],'Color','w','MenuBar','none');

hax1 = axes('Position',[.05 .05 .9 .9],'Color','none','NextPlot','replacechildren');
hax2 = axes('Position',[.05 .05 .9 .9],'Color','none','XTick',[],'YTick',[],'NextPlot','replacechildren');
hax3 = axes('Position',[.05 .05 .9 .9],'Color','none','XTick',[],'YTick',[],'NextPlot','replacechildren');
axis off; hold on;

axes(hax1)
ph1 = imagesc(Frames(:,:,1));
set(gca,'YDir','reverse')
hax1.XLim = [1 size(IMG,2)];
hax1.YLim = [1 size(IMG,1)];
hold on

axLims = axis;

axes(hax2)
ph2 = scatter(xy(1,1),xy(1,2),100,'filled','MarkerFaceColor',[.9 .1 .1]);
axis(axLims)
hold on


axes(hax3)
ph3 = plot(xy(1,1),xy(1,2),'r');
axis(axLims)
hold on
    

t = (1:size(xy,1));
ts = linspace(1, size(xy,1), size(xy,1)*100 );
xys = spline(t,xy',ts)';

mm=1;
for nn=1:size(Frames,3)

    ph1.CData = Frames(:,:,nn);
    ph2.XData = xy(nn,1);
    ph2.YData = xy(nn,2);
    % ph3.XData = xy(1:nn,1);
    % ph3.YData = xy(1:nn,2);
    ph3.XData = xys(1:mm,1);
    ph3.YData = xys(1:mm,2);
    
    pause(.2)

    mm = nn*100-1;
end

axes(hax3)
ph3 = plot(xys(:,1)+2,xys(:,2)+.5,'Color',[.99 .6 .90],'LineWidth',5);
ph3 = plot(xys(:,1),xys(:,2),'Color',[.99 .1 .75],'LineWidth',2);

axis(axLims)

%%
% end
% SAVE IMAGE ACQUISITION NOTES
%{

% imaqtool
vidObj = videoinput('macvideo', 1, 'YCbCr422_1280x720'); % CHANGE THIS TO THERMAL DEVICE ID
% vidObj = videoinput('winvideo', 1, 'UYVY_720x480'); % default
src = getselectedsource(vidObj);
% src.AnalogVideoFormat = 'ntsc_m_j';

% vidObj.FramesPerTrigger = 1;
% preview(vidObj);
% start(vidObj);
% pause(5)
% stop(vidObj);
% stoppreview(vidObj);
% delete(vidObj);
% clear vid src
% vidsrc = getselectedsource(vidObj);
% diskLogger = VideoWriter([thisFolder '/thermalVid1.avi'],'Uncompressed AVI');
vidObj.LoggingMode = 'memory';
% vidObj.DiskLogger = file;
% vidObj.ROIPosition = [488 95 397 507];
vidObj.ReturnedColorspace = 'rgb';
% vidObjSource = vidObj.Source;
% preview(vidObj);    pause(3);   stoppreview(vidObj);
% TriggerRepeat is zero-based
vidObj.TriggerRepeat = total_trials * framesPerTrial + framesPerTrial;
vidObj.FramesPerTrigger = 1;
triggerconfig(vidObj, 'manual');

start(vidObj);
% stop(vidObj);
% stoppreview(vidObj);
% delete(vidObj);
% clear vidObj

% Once a key is pressed, the experiment will begin
% main_keyboard_index = input_device_by_prompt('Please press any key on the main keyboard\n', 'keyboard');
disp('Starting experiment now...');












% imaqtool
% vidObj = videoinput('macvideo', 1, 'YCbCr422_1280x720'); % CHANGE THIS TO THERMAL DEVICE ID

utilpath = fullfile(matlabroot, 'toolbox', 'imaq', 'imaqdemos', 'helper');
addpath(utilpath);
% vidObj = videoinput('macvideo', 1, 'YCbCr422_1280x720');
vidObj = videoinput('winvideo', 1, 'UYVY_720x480'); % default
src = getselectedsource(vidObj);
% src.AnalogVideoFormat = 'ntsc_m_j';

% vidObj.FramesPerTrigger = 1;
% preview(vidObj);
% start(vidObj);
% pause(5)
% stop(vidObj);
% stoppreview(vidObj);
% delete(vidObj);
% clear vid src
% vidsrc = getselectedsource(vidObj);
% diskLogger = VideoWriter([thisFolder '/thermalVid1.avi'],'Uncompressed AVI');
vidObj.LoggingMode = 'memory';
% vidObj.DiskLogger = file;
% vidObj.ROIPosition = [488 95 397 507];
vidObj.ReturnedColorspace = 'rgb';
% vidObjSource = vidObj.Source;
% preview(vidObj);    pause(3);   stoppreview(vidObj);
% TriggerRepeat is zero-based
vidObj.TriggerRepeat = total_trials * 6 + 6;
vidObj.FramesPerTrigger = 1;
triggerconfig(vidObj, 'manual');

start(vidObj);
% stop(vidObj);
% stoppreview(vidObj);
% delete(vidObj);
% clear vidObj

% Once a key is pressed, the experiment will begin
% main_keyboard_index = input_device_by_prompt('Please press any key on the main keyboard\n', 'keyboard');
disp('Starting experiment now...');


Frames{1} = uint8(zeros(480,720,3));
for nn = 1:length(trial_data)*8
    Frames{nn} = uint8(zeros(480,720,3));
end

Frames = {};            % create thermal vid frame container
FramesTS = {};          % create thermal vid timestamp container
startTime = GetSecs;
ff=1;

%}























