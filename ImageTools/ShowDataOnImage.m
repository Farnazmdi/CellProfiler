function handles = ShowDataOnImage(handles)

% Help for the Show Data on Image tool:
% Category: Image Tools
%
% This allows you to extract measurements from an output file and
% overlay any measurements that you have made on any image. For
% example, you could look at the DNA content (e.g.
% IntegratedIntensityOrigBlue) of each cell on an image of nuclei.
% Or, you could look at cell area on an image of nuclei.  
% 
% First, you are asked to select the measurement you want to be
% displayed on the image.  Next, you are asked to select the X and
% then the Y locations where these measurements should be displayed.
% Typically, your options are the XY locations of the nuclei, or the
% XY locations of the cells, and these are usually named something
% like 'CenterXNuclei'.  If your output file has measurements from
% many images, you then select which sample number to view.
% 
% Then, CellProfilerTM tries to guide you to find the image that
% corresponds to this sample number.  First, it asks which file name
% would be most helpful for you to find the image. CellProfilerTM
% uses whatever you enter here to look up the exact file name you are
% looking for, so that you can browse to find the image. Once the
% image is selected, extraction ensues and eventually the image will
% be shown with the measurements on top.
% 
% You can use the tools at the top to zoom in on this image. If the
% text is overlapping and not easily visible, you can change the
% number of decimal places shown with the 'Fewer significant digits'
% button, or you can change the font size with the 'Text Properties'.
% You can also change the font style, color, and other properties with
% this button.  
% 
% The resulting figure can be saved in Matlab format (.fig) or
% exported in a traditional image file format.
%
% See also SHOWIMAGE, SHOWPIXELDATA.

% CellProfiler is distributed under the GNU General Public License.
% See the accompanying file LICENSE for details.
%
% Developed by the Whitehead Institute for Biomedical Research.
% Copyright 2003,2004,2005.
%
% Authors:
%   Anne Carpenter <carpenter@wi.mit.edu>
%   Thouis Jones   <thouis@csail.mit.edu>
%   In Han Kang    <inthek@mit.edu>
%
% $Revision$

%%% Asks the user to choose the file from which to extract measurements.
[RawFileName, RawPathname] = uigetfile(fullfile(handles.Current.DefaultOutputDirectory,'*.mat'),'Select the raw measurements file');
if RawFileName == 0,return,end

load(fullfile(RawPathname,RawFileName));

%%% Call the function GetFeature(), which opens a series of list dialogs and
%%% lets the user choose a feature. The feature can be identified via 'ObjectTypename',
%%% 'FeatureType' and 'FeatureNo'.
[ObjectTypename,FeatureType,FeatureNo] = GetFeature(handles);
if isempty(ObjectTypename),return,end

%%% Prompts the user to choose a sample number to be displayed.
Answer = inputdlg({'Which sample number do you want to display?'},'Choose sample number',1,{'1'});
if isempty(Answer)
    return
end
SampleNumber = str2double(Answer{1});

%TotalNumberImageSets = length(handles.Measurements.(MeasurementToExtract));
%if SampleNumber > TotalNumberImageSets
%    error(['The number you entered exceeds the number of samples in the file.  You entered ', num2str(SampleNumber), ' but there are only ', num2str(TotalNumberImageSets), ' in the file.'])
%end

%%% Looks up the corresponding image file name.
Fieldnames = fieldnames(handles.Measurements.GeneralInfo);
PotentialImageNames = Fieldnames(strncmp(Fieldnames,'Filename',8)==1);
%%% Error detection.
if isempty(PotentialImageNames)
    errordlg('CellProfiler was not able to look up the image file names used to create these measurements to help you choose the correct image on which to display the results. You may continue, but you are on your own to choose the correct image file.')
end
%%% Allows the user to select a filename from the list.
[Selection, ok] = listdlg('ListString',PotentialImageNames, 'ListSize', [300 300],...
    'Name','Choose the image whose filename you want to display',...
    'PromptString','Choose the image whose filename you want to display','CancelString','Cancel',...
    'SelectionMode','single');
if ok == 0,return,end

SelectedImageName = char(PotentialImageNames(Selection));
ImageFileName = handles.Measurements.GeneralInfo.(SelectedImageName){SampleNumber};
%%% Prompts the user with the image file name.
h = CPmsgbox(['Browse to find the image called ', ImageFileName,'.']);
%%% Opens a user interface window which retrieves a file name and path
%%% name for the image to be displayed.
[FileName,Pathname] = uigetfile(fullfile(handles.Current.DefaultImageDirectory,'*.*'),'Select the image to view');
delete(h)

%%% If the user presses "Cancel", the FileName will = 0 and nothing will happen.
if FileName == 0,return,end

%%% Opens and displays the image, with pixval shown.
ImageToDisplay = CPimread(fullfile(Pathname,FileName));

%%% Allows underscores to be displayed properly.
ImageFileName = strrep(ImageFileName,'_','\_');
FigureHandle = figure; imagesc(ImageToDisplay), colormap(gray)
title([ObjectTypename,', ',handles.Measurements.(ObjectTypename).([FeatureType,'Features']){FeatureNo} ' on ', ImageFileName])

%%% Extracts the measurement values.
global StringListOfMeasurements
tmp = handles.Measurements.(ObjectTypename).(FeatureType){SampleNumber};
ListOfMeasurements = tmp(:,FeatureNo);
StringListOfMeasurements = cellstr(num2str(ListOfMeasurements));

%%% Extracts the XY locations. This is temporarily hard-coded
if ~isfield(handles.Measurements.(ObjectTypename),'Shape')
    errordlg('Currently the MeasureShape module must be used to extract X and Y locations. It seems as if this was not done.')
    return
end
tmp = handles.Measurements.(ObjectTypename).Shape{SampleNumber};
Xlocations = tmp(:,10);
Ylocations = tmp(:,11);

%%% A button is created in the display window which
%%% allows altering the properties of the text.
StdUnit = 'point';
StdColor = get(0,'DefaultUIcontrolBackgroundColor');
PointsPerPixel = 72/get(0,'ScreenPixelsPerInch');
DisplayButtonCallback1 = 'global TextHandles, FigureHandle = gcf; CurrentTextHandles = TextHandles{FigureHandle}; try, propedit(CurrentTextHandles,''v6''); catch, CPmsgbox(''A bug in Matlab is preventing this function from working. Service Request #1-RR6M1''), end; drawnow, clear TextHandles';
uicontrol('Parent',FigureHandle, ...
    'Unit',StdUnit, ...
    'BackgroundColor',StdColor, ...
    'CallBack',DisplayButtonCallback1, ...
    'Position',PointsPerPixel*[2 2 90 22], ...
    'Units','Normalized',...
    'String','Text Properties', ...
    'Style','pushbutton');
DisplayButtonCallback2 = 'global TextHandles StringListOfMeasurements, FigureHandle = gcf; NumberOfDecimals = inputdlg(''Enter the number of decimal places to display'',''Enter the number of decimal places'',1,{''0''}); CurrentTextHandles = TextHandles{FigureHandle}; NumberValues = str2num(cell2mat(StringListOfMeasurements)); Command = [''%.'',num2str(NumberOfDecimals{1}),''f'']; NewNumberValues = num2str(NumberValues,Command); CellNumberValues = cellstr(NewNumberValues); PropName(1) = {''string''}; set(CurrentTextHandles,PropName, CellNumberValues); drawnow, clear TextHandles StringListOfMeasurements';
uicontrol('Parent',FigureHandle, ...
    'Unit',StdUnit, ...
    'BackgroundColor',StdColor, ...
    'CallBack',DisplayButtonCallback2, ...
    'Position',PointsPerPixel*[100 2 135 22], ...
    'Units','Normalized',...
    'String','Fewer significant digits', ...
    'Style','pushbutton');
DisplayButtonCallback3 = 'global TextHandles StringListOfMeasurements, FigureHandle = gcf; CurrentTextHandles = TextHandles{FigureHandle}; PropName(1) = {''string''}; set(CurrentTextHandles,PropName, StringListOfMeasurements); drawnow, clear TextHandles StringListOfMeasurements';
uicontrol('Parent',FigureHandle, ...
    'Unit',StdUnit, ...
    'BackgroundColor',StdColor, ...
    'CallBack',DisplayButtonCallback3, ...
    'Position',PointsPerPixel*[240 2 135 22], ...
    'Units','Normalized',...
    'String','Restore labels', ...
    'Style','pushbutton');
DisplayButtonCallback4 = 'global TextHandles StringListOfMeasurements, FigureHandle = gcf; CurrentTextHandles = TextHandles{FigureHandle}; set(CurrentTextHandles, ''visible'', ''off''); drawnow, clear TextHandles StringListOfMeasurements';
uicontrol('Parent',FigureHandle, ...
    'Unit',StdUnit, ...
    'BackgroundColor',StdColor, ...
    'CallBack',DisplayButtonCallback4, ...
    'Position',PointsPerPixel*[380 2 85 22], ...
    'Units','Normalized',...
    'String','Hide labels', ...
    'Style','pushbutton');
DisplayButtonCallback5 = 'global TextHandles StringListOfMeasurements, FigureHandle = gcf; CurrentTextHandles = TextHandles{FigureHandle}; set(CurrentTextHandles, ''visible'', ''on''); drawnow, clear TextHandles StringListOfMeasurements';
uicontrol('Parent',FigureHandle, ...
    'Unit',StdUnit, ...
    'BackgroundColor',StdColor, ...
    'CallBack',DisplayButtonCallback5, ...
    'Position',PointsPerPixel*[470 2 85 22], ...
    'Units','Normalized',...
    'String','Show labels', ...
    'Style','pushbutton');
%%% Overlays the values in the proper location in the
%%% image.
global TextHandles
TextHandles{FigureHandle} = text(Xlocations(:,FigureHandle) , Ylocations(:,FigureHandle) , StringListOfMeasurements,...
    'HorizontalAlignment','center', 'color', 'white');
%%% Puts the menu and tool bar in the figure window.
set(FigureHandle,'toolbar', 'figure')


function [ObjectTypename,FeatureType,FeatureNo] = GetFeature(handles)
%
%   This function takes the user through three list dialogs where a
%   specific feature is chosen. It is possible to go back and forth
%   between the list dialogs. The chosen feature can be identified
%   via the output variables
%


%%% Extract the fieldnames of measurements from the handles structure.
MeasFieldnames = fieldnames(handles.Measurements);

% Remove the 'GeneralInfo' field
index = setdiff(1:length(MeasFieldnames),strmatch('GeneralInfo',MeasFieldnames));
MeasFieldnames = MeasFieldnames(index);

%%% Error detection.
if isempty(MeasFieldnames)
    errordlg('No measurements were found.')
    ObjectTypename = [];FeatureType = [];FeatureNo = [];
    return
end

dlgno = 1;                            % This variable keeps track of which list dialog is shown
while dlgno < 4
    switch dlgno
        case 1
            [Selection, ok] = listdlg('ListString',MeasFieldnames, 'ListSize', [300 400],...
                'Name','Select measurement',...
                'PromptString','Choose an object type',...
                'CancelString','Cancel',...
                'SelectionMode','single');
            if ok == 0
                ObjectTypename = [];FeatureType = [];FeatureNo = [];
                return
            end
            ObjectTypename = MeasFieldnames{Selection};

            % Get the feature types, remove all fields that contain
            % 'Features' in the name
            FeatureTypes = fieldnames(handles.Measurements.(ObjectTypename));
            tmp = {};
            for k = 1:length(FeatureTypes)
                if isempty(strfind(FeatureTypes{k},'Features'))
                    tmp = cat(1,tmp,FeatureTypes(k));
                end
            end
            FeatureTypes = tmp;
            dlgno = 2;                      % Indicates that the next dialog box is to be shown next
        case 2
            [Selection, ok] = listdlg('ListString',FeatureTypes, 'ListSize', [300 400],...
                'Name','Select measurement',...
                'PromptString',['Choose a feature type for ', ObjectTypename],...
                'CancelString','Back',...
                'SelectionMode','single');
            if ok == 0
                dlgno = 1;                  % Back button pressed, go back one step in the menu system
            else
                FeatureType = FeatureTypes{Selection};
                Features = handles.Measurements.(ObjectTypename).([FeatureType 'Features']);
                dlgno = 3;                  % Indicates that the next dialog box is to be shown next
            end
        case 3
            [Selection, ok] = listdlg('ListString',Features, 'ListSize', [300 400],...
                'Name','Select measurement',...
                'PromptString',['Choose a ',FeatureType,' feature for ', ObjectTypename],...
                'CancelString','Back',...
                'SelectionMode','single');
            if ok == 0
                dlgno = 2;                  % Back button pressed, go back one step in the menu system
            else
                FeatureNo = Selection;
                dlgno = 4;                  % dlgno = 4 will exit the while-loop
            end
    end
end
