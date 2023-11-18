unit unitresourcestring;

{$mode ObjFPC}{$H+}

interface

 resourcestring
  Caption1 = 'Some text';
  HelloWorld1 = 'Hello World';
  WaitingTaskNum = 'Waiting task:';

  //Settings
  RequireDefaultDownloadPath = 'An available default path is required';

  //General
  TextError = 'Error';
  PleaseRestartApplication = 'You probably need to restart this application manually';

  //download task status
  DownloadStopped = 'Stopped';
  DownloadActive = 'Downloading';
  DownloadWaiting = 'Waiting';

  //Tracker Management
  AddTrackerSourceInput = 'Add source';
  AddTrackerSourceInputPrompt = 'Please input your tracker source URL';
  EditTrackerSourceInput = 'Edit source';
  EditTrackerSourceInputPrompt = 'Please input your new tracker source URL';
implementation

end.

