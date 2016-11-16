//
//  EncoderViewController.m
//  TagIt
//
//  Created by Tim.Milne on 11/11/16.
//  Copyright (c) 2016 Tim.Milne. All rights reserved.
//
//  Barcode scanner code from:
//  http://www.infragistics.com/community/blogs/torrey-betts/archive/2013/10/10/scanning-barcodes-with-ios-7-objective-c.aspx
//
//  Zebra RFID scanner code from:
//  http://compass.motorolasolutions.com

#import "EncoderViewController.h"
#import <AVFoundation/AVFoundation.h> // Barcode capture tools
#import <EPCEncoder/EPCEncoder.h>     // To encode the scanned barcode for comparison
#import <EPCEncoder/Converter.h>      // To convert to binary for comparison
#import "RfidSdkFactory.h"            // Zebra reader

@interface EncoderViewController ()<AVCaptureMetadataOutputObjectsDelegate, srfidISdkApiDelegate>
{
    __weak IBOutlet UILabel         *_upcLbl;
    __weak IBOutlet UILabel         *_serLbl;
    __weak IBOutlet UITextField     *_upcFld;
    __weak IBOutlet UITextField     *_serFld;
    __weak IBOutlet UIBarButtonItem *_resetBtn;
    __weak IBOutlet UIBarButtonItem *_encodeBtn;
    __weak IBOutlet UIImageView     *_successImg;
    __weak IBOutlet UIImageView     *_failImg;
    __weak IBOutlet UISwitch        *_scanScanEncodeSwt;
    __weak IBOutlet UILabel         *_versionLbl;
    
    BOOL                            _barcodeFound;
    BOOL                            _rfidFound;
    BOOL                            _encoding;
    BOOL                            _tagEncoded;
    NSMutableString                 *_oldEPC;
    NSMutableString                 *_newEPC;
    NSMutableString                 *_lastDetectionString;
    UIColor                         *_defaultBackgroundColor;
    
    AVCaptureSession                *_session;
    AVCaptureDevice                 *_device;
    AVCaptureDeviceInput            *_input;
    AVCaptureMetadataOutput         *_output;
    AVCaptureVideoPreviewLayer      *_prevLayer;
    
    UIView                          *_highlightView;
    UILabel                         *_barcodeLbl;
    UILabel                         *_rfidLbl;
    UILabel                         *_batteryLifeLbl;
    UIProgressView                  *_batteryLifeView;
    
    EPCEncoder                      *_encode;
    Converter                       *_convert;
    
    id <srfidISdkApi>               _rfidSdkApi;
    int                             _zebraReaderID;
    srfidStartTriggerConfig         *_startTriggerConfig;
    srfidStopTriggerConfig          *_stopTriggerConfig;
    srfidReportConfig               *_reportConfig;
    srfidAccessConfig               *_accessConfig;
    srfidDynamicPowerConfig         *_dpoConfig;            // Only for writing tags
}
@end

@implementation EncoderViewController

#define UIColorFromRGB(rgbValue) [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 green:((float)((rgbValue & 0xFF00) >> 8))/255.0 blue:((float)(rgbValue & 0xFF))/255.0 alpha:0.65]

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    // Set the status bar to white (iOS bug)
    // Also had to add the statusBarStyle entry to info.plist
    self.navigationController.navigationBar.barStyle = UIStatusBarStyleLightContent;
    
    // Initialize variables
    _encode = [EPCEncoder alloc];
    _convert = [Converter alloc];
    _oldEPC = [[NSMutableString alloc] init];
    _newEPC = [[NSMutableString alloc] init];
    _lastDetectionString = [[NSMutableString alloc] init];
    _barcodeFound = FALSE;
    _rfidFound = FALSE;
    _defaultBackgroundColor = UIColorFromRGB(0x000000);
    
    // Set the label background colors
    _upcLbl.backgroundColor = [UIColor colorWithWhite:0.15 alpha:0.65];
    _serLbl.backgroundColor = [UIColor colorWithWhite:0.15 alpha:0.65];
    
// TPM: The barcode scanner example built the UI from scratch.  This made it easier to deal with all
// the settings programatically, so I've continued with that here...
    
    // Barcode highlight view
    _highlightView = [[UIView alloc] init];
    _highlightView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin|UIViewAutoresizingFlexibleBottomMargin;
    _highlightView.layer.borderColor = [UIColor redColor].CGColor;
    _highlightView.layer.borderWidth = 3;
    [self.view addSubview:_highlightView];
    
    // Barcode label view
    _barcodeLbl = [[UILabel alloc] init];
    _barcodeLbl.frame = CGRectMake(0, self.view.bounds.size.height - 120, self.view.bounds.size.width, 40);
    _barcodeLbl.autoresizingMask = UIViewAutoresizingFlexibleTopMargin;
    _barcodeLbl.textColor = [UIColor whiteColor];
    _barcodeLbl.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:_barcodeLbl];
    
    // RFID label view
    _rfidLbl = [[UILabel alloc] init];
    _rfidLbl.frame = CGRectMake(0, self.view.bounds.size.height - 80, self.view.bounds.size.width, 40);
    _rfidLbl.autoresizingMask = UIViewAutoresizingFlexibleTopMargin;
    _rfidLbl.textColor = [UIColor whiteColor];
    _rfidLbl.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:_rfidLbl];
    
    // Battery life label
    _batteryLifeLbl = [[UILabel alloc] init];
    _batteryLifeLbl.frame = CGRectMake(0, self.view.bounds.size.height - 40, self.view.bounds.size.width, 40);
    _batteryLifeLbl.autoresizingMask = UIViewAutoresizingFlexibleTopMargin;
    _batteryLifeLbl.textColor = [UIColor whiteColor];
    _batteryLifeLbl.textAlignment = NSTextAlignmentCenter;
    _batteryLifeLbl.backgroundColor = [UIColor colorWithWhite:0.15 alpha:0.65];
    [self.view addSubview:_batteryLifeLbl];
    
    // Battery life view
    _batteryLifeView = [[UIProgressView alloc] init];
    _batteryLifeView.frame = CGRectMake(0, self.view.bounds.size.height - 8, self.view.bounds.size.width, 40);
    _batteryLifeView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin;
    _batteryLifeView.backgroundColor = [UIColor colorWithWhite:0.15 alpha:0.65];
    [self.view addSubview:_batteryLifeView];
    
    // Version label
    _versionLbl.text = [NSString stringWithFormat:@"Version: %@",
                        [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"]];
    
    // Initialize the bar code scanner session, device, input, output, and preview layer
    _session = [[AVCaptureSession alloc] init];
    _device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    NSError *error = nil;
    _input = [AVCaptureDeviceInput deviceInputWithDevice:_device error:&error];
    if (_input) {
        [_session addInput:_input];
    } else {
        NSLog(@"Error: %@\n", error);
    }
    _output = [[AVCaptureMetadataOutput alloc] init];
    [_output setMetadataObjectsDelegate:self queue:dispatch_get_main_queue()];
    [_session addOutput:_output];
    _output.metadataObjectTypes = [_output availableMetadataObjectTypes];
    _prevLayer = [AVCaptureVideoPreviewLayer layerWithSession:_session];
    _prevLayer.frame = self.view.bounds;
    _prevLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    [self.view.layer addSublayer:_prevLayer];
    
    // Bring the input views to the front
    [self.view bringSubviewToFront:_upcLbl];
    [self.view bringSubviewToFront:_serLbl];
    [self.view bringSubviewToFront:_upcFld];
    [self.view bringSubviewToFront:_serFld];
    
    // Pop the subviews to the front of the preview view
    [self.view bringSubviewToFront:_highlightView];
    [self.view bringSubviewToFront:_barcodeLbl];
    [self.view bringSubviewToFront:_rfidLbl];
    [self.view bringSubviewToFront:_batteryLifeLbl];
    [self.view bringSubviewToFront:_batteryLifeView];
    [self.view bringSubviewToFront:_successImg];
    [self.view bringSubviewToFront:_failImg];
    
    // Reset initializes all the variables and colors and pops the remaining views
    [self reset:_resetBtn];
    
    // Update the encoder
    [self updateAll];
    
    // Start scanning for barcodes
    [_session startRunning];
    
    // Set Zebra scanner configurations used in srfidStartRapidRead
    _zebraReaderID = -1;
    [self zebraInitializeRfidSdkWithAppSettings];
}

/*!
 * @discussion Adjust the preview layer on orientation changes
 */
- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
    switch ((int)orientation) {
        case UIInterfaceOrientationPortrait:
            [_prevLayer.connection setVideoOrientation:AVCaptureVideoOrientationPortrait];
            break;
        case UIInterfaceOrientationPortraitUpsideDown:
            [_prevLayer.connection setVideoOrientation:AVCaptureVideoOrientationPortraitUpsideDown];
            break;
        case UIInterfaceOrientationLandscapeLeft:
            [_prevLayer.connection setVideoOrientation:AVCaptureVideoOrientationLandscapeLeft];
            break;
        case UIInterfaceOrientationLandscapeRight:
            [_prevLayer.connection setVideoOrientation:AVCaptureVideoOrientationLandscapeRight];
            break;
    }
}

/*!
 * @discussion Press reset button to reset the interface and reader and begin reading.
 * @param sender The ID of the sender object (not used)
 */
- (IBAction)reset:(id)sender {
    // Reset all controls and variables
    _barcodeFound = FALSE;
    _rfidFound = FALSE;
    _encodeBtn.enabled = FALSE;
    _encoding = FALSE;
    [_oldEPC setString:@""];
    [_newEPC setString:@""];
    [self.view setBackgroundColor:_defaultBackgroundColor];
    
    _upcFld.text = @"";
    
    _barcodeLbl.text = @"Barcode: (scanning for barcodes)";
    _barcodeLbl.backgroundColor = [UIColor colorWithWhite:0.15 alpha:0.65];
    _rfidLbl.backgroundColor = [UIColor colorWithWhite:0.15 alpha:0.65];
    _batteryLifeLbl.backgroundColor = [UIColor colorWithWhite:0.15 alpha:0.65];
    _batteryLifeLbl.text = @"RFID Battery Life";
    _batteryLifeView.progress = 0.;
    
    // Hide the result images (treat these different for landscape mode)
    _successImg.hidden = TRUE;
    _failImg.hidden = TRUE;
    
    // If scanScanEncode is enabled, reset these differently
    if (_scanScanEncodeSwt.on == TRUE) {
        // DON'T reset these controls and variables
//        _tagEncoded = FALSE;                  // Set only in endEncode
//        [_lastDetectionString setString:@""]; // Read a barcode only once in captureOutput - must read a different barcode each time
//        _serFld.text = @"04000000001";                  // Incremented after successful tag write
        
        // Scanning for labels
        _rfidLbl.text = @"RFID: (scanning for labels)";
        
        // We don't read tags in scan scan encode mode
        
        // Update the battery life
        if (_zebraReaderID > 0) {
            [_rfidSdkApi srfidRequestBatteryStatus:_zebraReaderID];
        }
    }
    
    // Regular reset, scan for a tag
    else {
        // Reset these additional controls and variables
        _tagEncoded = FALSE;
        [_lastDetectionString setString:@""];
        _serFld.text = @"04000000001";
        
        // Scanning for tags
        _rfidLbl.text = @"RFID: (connecting to reader)";
        
        // If no connection open, open it now and start scanning for RFID tags
        [_rfidSdkApi srfidStopRapidRead:_zebraReaderID aStatusMessage:nil];
        [_rfidSdkApi srfidTerminateCommunicationSession:_zebraReaderID];
        _zebraReaderID = -1;
        [self zebraRapidRead];
        
        // Asking for RFID scans triggers battery life updates, so no need to do that here
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

// Zebra RFID Reader
#pragma mark - Zebra Reader Support

/*!
 * @discussion Initialize the Zebra reader and start a rapid read.
 */
- (void)zebraInitializeRfidSdkWithAppSettings
{
    _rfidSdkApi = [srfidSdkFactory createRfidSdkApiInstance];
    [_rfidSdkApi srfidSetDelegate:self];
    
    int notifications_mask = SRFID_EVENT_READER_APPEARANCE |
    SRFID_EVENT_READER_DISAPPEARANCE | // Not really needed
    SRFID_EVENT_SESSION_ESTABLISHMENT |
    SRFID_EVENT_SESSION_TERMINATION; // Not really needed
    [_rfidSdkApi srfidSetOperationalMode:SRFID_OPMODE_MFI];
    [_rfidSdkApi srfidSubsribeForEvents:notifications_mask];
    [_rfidSdkApi srfidSubsribeForEvents:(SRFID_EVENT_MASK_READ | SRFID_EVENT_MASK_STATUS)]; // Event mask not needed
    [_rfidSdkApi srfidSubsribeForEvents:(SRFID_EVENT_MASK_PROXIMITY)]; // Not really needed
    [_rfidSdkApi srfidSubsribeForEvents:(SRFID_EVENT_MASK_TRIGGER)]; // Not really needed
    [_rfidSdkApi srfidSubsribeForEvents:(SRFID_EVENT_MASK_BATTERY)];
    [_rfidSdkApi srfidEnableAvailableReadersDetection:YES];
    [_rfidSdkApi srfidEnableAutomaticSessionReestablishment:YES];
    
    _startTriggerConfig = [[srfidStartTriggerConfig alloc] init];
    _stopTriggerConfig  = [[srfidStopTriggerConfig alloc] init];
    _reportConfig       = [[srfidReportConfig alloc] init];
    _accessConfig       = [[srfidAccessConfig alloc] init];
    _dpoConfig          = [[srfidDynamicPowerConfig alloc] init]; // Only for writing tags
    
    // Configure start and stop triggers parameters to start and stop actual
    // operation immediately on a corresponding response
    [_startTriggerConfig setStartOnHandheldTrigger:NO];
    [_startTriggerConfig setStartDelay:0];
    [_startTriggerConfig setRepeatMonitoring:NO];
    [_stopTriggerConfig setStopOnHandheldTrigger:NO];
    [_stopTriggerConfig setStopOnTimeout:NO];
    [_stopTriggerConfig setStopOnTagCount:YES];
    [_stopTriggerConfig setStopOnInventoryCount:YES];
    [_stopTriggerConfig setStopTagCount:1];
    [_stopTriggerConfig setStopOnAccessCount:NO];
    
    // Configure report parameters to report RSSI, Channel Index, Phase and PC fields
    [_reportConfig setIncPC:YES];
    [_reportConfig setIncPhase:YES];
    [_reportConfig setIncChannelIndex:YES];
    [_reportConfig setIncRSSI:YES];
    [_reportConfig setIncTagSeenCount:NO];
    [_reportConfig setIncFirstSeenTime:NO];
    [_reportConfig setIncLastSeenTime:NO];
    
    // Configure access parameters to perform the operation with 12.0 dbm antenna
    // power level without application of pre-filters for close proximity
    [_accessConfig setPower:120];
    [_accessConfig setDoSelect:NO];
    
    // Configure dynamic power options (must be off for writing)
    [_dpoConfig setDynamicPowerOptimizationEnabled:FALSE];
    
    // See if a reader is already connected and try and read a tag
    [self zebraRapidRead];
}

/*!
 * @discussion Kick off a Zebra Rapid Read.
 */
- (void)zebraRapidRead
{
    if (_zebraReaderID < 0) {
        // Get an available reader (must connect with bluetooth settings outside of app)
        NSMutableArray *readers = [[NSMutableArray alloc] init];
        [_rfidSdkApi srfidGetAvailableReadersList:&readers];
        
        for (srfidReaderInfo *reader in readers)
        {
            SRFID_RESULT result = [_rfidSdkApi srfidEstablishCommunicationSession:[reader getReaderID]];
            if (result == SRFID_RESULT_SUCCESS) {
                break;
            }
        }
    }
    else if (_scanScanEncodeSwt.on == TRUE) {
        [_rfidSdkApi srfidRequestBatteryStatus:_zebraReaderID];
        
        // Don't read RFID tags in scan scan encode mode, set the label and scan for barcode labels
        _rfidLbl.text = @"RFID: (scanning for labels)";
        _rfidLbl.backgroundColor = [UIColor colorWithWhite:0.15 alpha:0.65];
    }
    else {
        [_rfidSdkApi srfidRequestBatteryStatus:_zebraReaderID];
        
        NSString *error_response = nil;
        
        do {
            // Set start trigger parameters
            SRFID_RESULT result = [_rfidSdkApi srfidSetStartTriggerConfiguration:_zebraReaderID
                                                              aStartTriggeConfig:_startTriggerConfig
                                                                  aStatusMessage:&error_response];
            if (SRFID_RESULT_SUCCESS == result) {
                // Start trigger configuration applied
                NSLog(@"Zebra Start trigger configuration has been set\n");
            } else {
                NSLog(@"Zebra Failed to set start trigger parameters\n");
                break;
            }
            
            // Set stop trigger parameters
            result = [_rfidSdkApi srfidSetStopTriggerConfiguration:_zebraReaderID
                                                 aStopTriggeConfig:_stopTriggerConfig
                                                    aStatusMessage:&error_response];
            if (SRFID_RESULT_SUCCESS == result) {
                // Stop trigger configuration applied
                NSLog(@"Zebra Stop trigger configuration has been set\n");
            } else {
                NSLog(@"Zebra Failed to set stop trigger parameters\n");
                break;
            }
            
            // Set dynamice power options parameters (must be off for writing tags)
            result  = [_rfidSdkApi srfidSetDpoConfiguration:_zebraReaderID
                                          aDpoConfiguration:_dpoConfig
                                             aStatusMessage:&error_response];
            
            if (SRFID_RESULT_SUCCESS == result ) {
                // Dynamic power options configuration applied
                NSLog(@"Zebra dynamic power options configuration has been set\n");
            } else {
                NSLog(@"Zebra Failed to set dynamic power options parameters\n");
                break;
            }
            
            // Start and stop triggers and DPO have been configured
            error_response = nil;
            
            // Request performing of rapid read operation
            result = [_rfidSdkApi srfidStartRapidRead:_zebraReaderID
                                        aReportConfig:_reportConfig
                                        aAccessConfig:_accessConfig
                                       aStatusMessage:&error_response];
            if (SRFID_RESULT_SUCCESS == result) {
                NSLog(@"Zebra Request succeeded\n");
                
                _rfidLbl.text = @"RFID: (scanning for tags)";
                _rfidLbl.backgroundColor = [UIColor colorWithWhite:0.15 alpha:0.65];
                
                // Stop an operation after 1 minute
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(60 *
                                                                          NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [_rfidSdkApi srfidStopRapidRead:_zebraReaderID aStatusMessage:nil];
                });
            }
            else if (SRFID_RESULT_RESPONSE_ERROR == result) {
                NSLog(@"Zebra Error response from RFID reader: %@\n", error_response);
            }
            else {
                NSLog(@"Zebra Request failed\n");
            }
        } while (0); // Only do this once, but break on any errors (Objective-C GO TO :)
    }
}

// Barcode scanner
#pragma mark - Barcode Scanner Delegates

/*!
 * @discussion Check for a valid scanned barcode, only proceed if a valid barcode found.  Check for ready to encode.
 */
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection
{
    CGRect highlightViewRect = CGRectZero;
    AVMetadataMachineReadableCodeObject *barCodeObject;
    NSString *detectionString = nil;
    NSString *type;
    
// TPM don't check all barcode types, but these are the ones iOS supports.
    NSArray *barCodeTypes = @[AVMetadataObjectTypeUPCECode,
//                              AVMetadataObjectTypeCode39Code,
//                              AVMetadataObjectTypeCode39Mod43Code,
                              AVMetadataObjectTypeEAN13Code,
                              AVMetadataObjectTypeEAN8Code,
//                              AVMetadataObjectTypeCode93Code,
                              AVMetadataObjectTypeCode128Code, // Checkpoint tags 3x1 tags
//                              AVMetadataObjectTypePDF417Code,
//                              AVMetadataObjectTypeQRCode,
//                              AVMetadataObjectTypeAztecCode,
//                              AVMetadataObjectTypeInterleaved2of5Code,
//                              AVMetadataObjectTypeITF14Code,
                              AVMetadataObjectTypeDataMatrixCode // Avery and Checkpoint tags 2x1 and 1x1
                              ];
    
    for (AVMetadataObject *metadata in metadataObjects) {
        for (type in barCodeTypes) {
            if ([metadata.type isEqualToString:type])
            {
                barCodeObject = (AVMetadataMachineReadableCodeObject *)[_prevLayer transformedMetadataObjectForMetadataObject:(AVMetadataMachineReadableCodeObject *)metadata];
                highlightViewRect = barCodeObject.bounds;
                detectionString = [(AVMetadataMachineReadableCodeObject *)metadata stringValue];
                break;
            }
        }
        
        // Update before returning
        _highlightView.frame = highlightViewRect;
        
        if (detectionString != nil) {
            // Don't keep processing the same barcode
            if ([_lastDetectionString isEqualToString:detectionString]) return;
            [_lastDetectionString setString:detectionString];
            
            // Scan scan barcodes (might not need to check for length)
            if ((type == AVMetadataObjectTypeDataMatrixCode && detectionString.length == 24) ||
                (type == AVMetadataObjectTypeCode128Code    && detectionString.length == 24) ){

                // New input data
                
                // Set the old EPC
                [_oldEPC setString:detectionString];
                
                // Get the RFID tag
                _rfidLbl.text = [NSString stringWithFormat:@"RFID: %@", _oldEPC];
                _rfidLbl.backgroundColor = UIColorFromRGB(0xA4CD39);
                _rfidFound = TRUE;
                
                // With a Data Matrix barcode scan, stop the RFID reader
                [_rfidSdkApi srfidStopRapidRead:_zebraReaderID aStatusMessage:nil];
                
                // Log the read barcode
                NSLog(@"\nData Matrix label read: %@\n", _oldEPC);
            }
                
            // All the rest are UPC or EAN barcodes
            else {
                // Assume false until verified
                _barcodeFound = FALSE;
                
                // Grab the barcode
                NSString *barcode;
                barcode = detectionString;
                
                // Quick length checks, chop to 12 for now (remove leading zeros)
                if (barcode.length == 13) barcode = [barcode substringFromIndex:1];
                if (barcode.length == 14) barcode = [barcode substringFromIndex:2];
                
                // Set the interface
                _barcodeLbl.text = [NSString stringWithFormat:@"Barcode: %@", barcode];
                _barcodeLbl.backgroundColor = UIColorFromRGB(0xA4CD39);
                
                // All T2 backroom tags will be encoded as replacement tags in GID format (even owned brand products).
                // The serial numbers will all start with '04' (11 digits) to indicate the Commissioning Authority.
                if ((barcode.length == 12) || (barcode.length == 14)) {

                    // This is a replacement tag, set the commissioning authority to '04'
// TBD - Need a random number generator for the last 9 digits of the serial number
                    NSString *ser  = ([_serFld.text length])?[_serFld text]:@"04000000001";
                    [_serFld setText:ser];
                    
                    // Take the UPC and encode a reference
                    [_encode gidWithGTIN:barcode ser:ser];
                    
                    // Set the interface
                    [_upcFld setText:barcode];
                    
                    _barcodeFound = TRUE;
                    
                    // Log the read barcode
                    NSLog(@"\nBar code read read: %@\n", barcode);
                }
                
                // Unsupported barcode
                else {
                    
                    _barcodeLbl.text = @"Barcode: unsupported barcode";
                    _barcodeLbl.backgroundColor = UIColorFromRGB(0xCC0000);
                    _barcodeFound = FALSE;
                    
                    // Log the unsupported barcode
                    NSLog(@"\nUnsupported barcode: %@\n", barcode);
                }
            }
        }
        
        // Still scanning for barcodes
        else {
            _barcodeLbl.text = @"Barcode: (scanning for barcodes)";
            _barcodeLbl.backgroundColor = [UIColor colorWithWhite:0.15 alpha:0.65];
            _barcodeFound = FALSE;
        }
    }
    
    // This clears the scan rectangle if empty
    _highlightView.frame = highlightViewRect;
    
    // Check to see if ready to encode
    [self readyToEncode];
}

// Text field delegates
#pragma mark - Text Fields

/*!
 * @discussion Delegate to dimiss keyboard after return.
 * Set the delegate of any input text field to the ViewController class
 */
- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return NO;
}

/*!
 * @discussion Update the interface - All the edit fields point here, after you end the edit and hit return.
 */
- (IBAction)update:(id)sender {
    // New input data
    _successImg.hidden = TRUE;
    _failImg.hidden = TRUE;
    
    [self updateAll];
}

/*!
 * @discussion Update all elements for any input change.  Check input and check ready to encode.
 */
- (void)updateAll {
    NSString *upc = [_upcFld text];
    NSString *ser = [_serFld text];
    
    // Make sure the inputs are not too long (especially the Serial Number)
    if ([upc length] > 14) {
        upc = [upc substringToIndex:14];
        [_upcFld setText:upc];
    }
    if ([ser length] > 11) {
        // GID serial number max = 11
        ser = [ser substringToIndex:11];
        [_serFld setText:ser];
    }
    
    // All T2 backroom tags will be encoded as replacement tags in GID format (even owned brand products).
    // The serial numbers will all start with '04' (11 digits) to indicate the Commissioning Authority.
    if ([ser length] > 0 && [upc length] > 0) {
        
        // This is a replacement tag, check the commissioning authority
        // GID serial numbers are 11 digits long
        for (int i=(int)[ser length]; i<11; i++) {
            ser = [NSString stringWithFormat:@"0%@", ser];
        }
        
        // Make sure it starts with 04
        if (!([[ser substringToIndex:2] isEqualToString:@"04"])) {
            ser = [NSString stringWithFormat:@"04%@", [ser substringFromIndex:2]];
        }
        [_serFld setText:ser];
        
        // Update the EPCEncoder object
        [_encode gidWithGTIN:upc ser:ser];
        
        if ([upc length] == 14 || [upc length] == 12) {
            _barcodeLbl.text = [NSString stringWithFormat:@"Barcode: %@", upc];
            _barcodeLbl.backgroundColor = UIColorFromRGB(0xA4CD39);
            _barcodeFound = TRUE;
        }
        else {
            _barcodeLbl.text = [NSString stringWithFormat:@"Barcode: (invalid UPC)"];
            _barcodeLbl.backgroundColor = UIColorFromRGB(0xCC0000);
            _barcodeFound = FALSE;
        }
        
        _barcodeFound = TRUE;
    }
    
    else {
        _barcodeLbl.text = [NSString stringWithFormat:@"Barcode: (scanning for barcodes)"];
        _barcodeLbl.backgroundColor = [UIColor colorWithWhite:0.15 alpha:0.65];
        _barcodeFound = FALSE;
    }
    
    // Set the background color
    [self.view setBackgroundColor:_defaultBackgroundColor];
    
    // Check to see if ready to encode
    if (_scanScanEncodeSwt.on == FALSE) [self readyToEncode];
}

// Encode
#pragma mark - Encode

/*!
 * @discussion Check for ready to encode - Enable the encode button if all input ready.
 */
- (void)readyToEncode {
    // If we have a valid barcode, an RFID tag, and a reader is connected, we are ready to encode
    BOOL conditionsMet = (_barcodeFound && _rfidFound && ([_oldEPC length] > 0));
    
    // If scanScanEncode is enabled, automatically encode the tag now
    if (_scanScanEncodeSwt.on == TRUE && conditionsMet) {
        [self encode:_scanScanEncodeSwt];
        
        if (_tagEncoded) {
            [self reset:_scanScanEncodeSwt];
            
            // Adjust the result images after reset
            dispatch_async(dispatch_get_main_queue(),
                           ^{
                               _successImg.hidden = !(_tagEncoded);
                               _failImg.hidden = _tagEncoded;
                           });
        }
    }
    
    // Otherwise, enable or disable the manual encode button based on the conditions
    else {
        _encodeBtn.enabled = conditionsMet;
    }
}

/*!
 * @discussion Encode handler - Prepare to encode.
 * @param sender The ID of the sender object (not used)
 */
- (IBAction)encode:(id)sender {
    _encoding = TRUE;
    
    // New encoding attempt
    _successImg.hidden = TRUE;
    _failImg.hidden = TRUE;
    
    [self beginEncode:[_encode gid_hex]];
}

/*!
 * @discussion Begin the encoding process.
 * @param hex The new tag number to encode (hex)
 */
- (void)beginEncode:(NSString *)hex {
    [_newEPC setString:hex];
    
    if ([_oldEPC length] == 0) {
        // The only way we got here is after a successful tag read, otherwise the encode button wouldn't be active
        // so this code block really should never be hit.
        [self zebraRapidRead];
    }
    else {
        [self endEncode:_oldEPC];
    }
}

/*!
 * @discussion End the encoding process.
 * @param hex The Old EPC (will be replaced)
 */
-(void)endEncode:(NSString *)hex {
    [_oldEPC setString:hex];
    
    if ([_newEPC length] == 0) return;
    
    // Test tag reset: check for one of the special reset barcodes, if found, encode with the reset value
    if ([[_upcFld text] isEqual:@"999999999917"]){
        [_newEPC setString:@"30304035A880C84000366A25"];
    }
    else if ([[_upcFld text] isEqual:@"999999999924"]){
        [_newEPC setString:@"30304035A880C84000366A26"];
    }
    else if ([[_upcFld text] isEqual:@"999999999931"]){
        [_newEPC setString:@"30304035A880C84000366A27"];
    }
    
    // Assume failure (many ways to fail)
    _tagEncoded = FALSE;
    
    // Allocate object for storing results of access operation
    srfidTagData *access_result = [[srfidTagData alloc] init];
    
    // An object for storage of error response received from RFID reader
    NSString *error_response = nil;
    
    // Write _newEPC to the EPC memory bank of a tag specified by _oldEPC
    SRFID_RESULT result = [_rfidSdkApi srfidWriteTag:_zebraReaderID
                                              aTagID:_oldEPC
                                      aAccessTagData:&access_result
                                         aMemoryBank:SRFID_MEMORYBANK_EPC
                                             aOffset:2                      // Not sure where 2 came from....
                                               aData:_newEPC
                                           aPassword:0x00
                                       aDoBlockWrite:NO
                                      aStatusMessage:&error_response];
    
    if (SRFID_RESULT_SUCCESS == result) {
        // Check result code of access operation
        if (NO == [access_result getOperationSucceed]) {
            NSLog(@"Tag programming UNSUCCESSFUL with error: %@\n", [access_result getOperationStatus]);
            [self.view setBackgroundColor:UIColorFromRGB(0xCC0000)];
            _failImg.hidden = FALSE;
        }
        else {
            NSLog(@"Tag programmed successfully\n");
            [self.view setBackgroundColor:UIColorFromRGB(0xA4CD39)];
            _rfidLbl.text = [NSString stringWithFormat:@"RFID: %@", _newEPC];
            _rfidLbl.backgroundColor = UIColorFromRGB(0xA4CD39);
            
            // Increment the serial number for another run and update
            long long serLong = [[_serFld text] longLongValue];
            [_serFld setText:[NSString stringWithFormat:@"%lld", (long long)(++serLong)]];
            [self updateAll];
            _successImg.hidden = FALSE;
            _tagEncoded = TRUE;
        }
    }
    else if (SRFID_RESULT_RESPONSE_ERROR == result) {
        NSLog(@"Tag programming UNSUCCESSFUL with error response from RFID reader: %@\n", error_response);
        [self.view setBackgroundColor:UIColorFromRGB(0xCC0000)];
        _failImg.hidden = FALSE;
    }
    else if (SRFID_RESULT_RESPONSE_TIMEOUT == result) {
        NSLog(@"Tag programming UNSUCCESSFUL: Timeout occurred\n");
        [self.view setBackgroundColor:UIColorFromRGB(0xCC0000)];
        _failImg.hidden = FALSE;
    }
    else {
        NSLog(@"Tag programming UNSUCCESSFUL: Request failed\n");
        [self.view setBackgroundColor:UIColorFromRGB(0xCC0000)];
        _failImg.hidden = FALSE;
    }
    
    // If our work is done
    if (_tagEncoded) [_oldEPC setString:@""];
}

// Zebra RFID Reader
#pragma mark - Zebra Delegates

/*!
 * @discussion Zebra reader appeared - Adjust to the new state.
 * @param availableReader Reader info about the newly appeared reader
 */
- (void)srfidEventReaderAppeared:(srfidReaderInfo*)availableReader
{
    NSLog(@"Zebra Reader Appeared - Name: %@", [availableReader getReaderName]);
    
    [_rfidSdkApi srfidEstablishCommunicationSession:[availableReader getReaderID]];
}

/*!
 * @discussion Zebra reader communication established - Start reading
 * @param activeReader Reader info for the active reader
 */
- (void)srfidEventCommunicationSessionEstablished:(srfidReaderInfo*)activeReader
{
    NSLog(@"Zebra Communication Established - Name: %@", [activeReader getReaderName]);
    
    // Set the reader
    _zebraReaderID = [activeReader getReaderID];
    
    // Establish ASCII connection
    if ([_rfidSdkApi srfidEstablishAsciiConnection:_zebraReaderID aPassword:nil] == SRFID_RESULT_SUCCESS)
    {
        // Set the volume
        NSString *statusMessage = nil;
        [_rfidSdkApi srfidSetBeeperConfig:_zebraReaderID
                            aBeeperConfig:SRFID_BEEPERCONFIG_LOW
                           aStatusMessage:&statusMessage];
        
        // Success, now read tags
        [self zebraRapidRead];
    }
    else
    {
        // Error, alert
        UIAlertView *alert = [[UIAlertView alloc]
                              initWithTitle:@"Zebra Error"
                              message:@"Failed to establish connection with Zebra RFID reader"
                              delegate:nil
                              cancelButtonTitle:@"OK"
                              otherButtonTitles:nil];
        
        dispatch_async(dispatch_get_main_queue(),
                       ^{
                           [alert show];
                       });
        
        // Terminate sesssion
        [_rfidSdkApi srfidTerminateCommunicationSession:_zebraReaderID];
        _zebraReaderID = -1;
        _rfidLbl.text = @"RFID: Zebra connection failed";
        _rfidLbl.backgroundColor = UIColorFromRGB(0xCC0000);
    }
}

/*!
 * @discussion New tag found with Zebra reader
 * Display the tag, stop the reader, disable the other readers, and check for a match.
 * @param readerID The ID of the reader
 * @param aTagData The data in the RFID tag
 */
- (void)srfidEventReadNotify:(int)readerID aTagData:(srfidTagData*)tagData
{
    dispatch_async(dispatch_get_main_queue(),
                   ^{
                       // tag was found for the first time

                       // Stop the RFID reader
                       [_rfidSdkApi srfidStopRapidRead:readerID aStatusMessage:nil];
                       
                       // New input data
                       _successImg.hidden = TRUE;
                       _failImg.hidden = TRUE;
                       
                       // Set the old EPC
                       [_oldEPC setString:[tagData getTagId]];
                       
                       // Get the RFID tag
                       _rfidLbl.text = [NSString stringWithFormat:@"RFID: %@", _oldEPC];
                       _rfidLbl.backgroundColor = UIColorFromRGB(0xA4CD39);
                       
                       // We've found a tag
                       _rfidFound = TRUE;
                       
                       if (_encoding) {
                           [self endEncode:_oldEPC];
                           _encoding = FALSE;
                       }
                       else {
                           _rfidFound = TRUE;
                           
                           // Check to see if ready to encode
                           [self readyToEncode];
                       }
                       
                       // Log the read tag
                       NSLog(@"\nRFID tag read: %@\n", _oldEPC);
                   });
}

/*!
 * @discussion Set the battery life of the Zebra reader.
 * @warning This delegate is called at random intervals (Stochastic baby!), or can be prompted by the SDK
 */
- (void)srfidEventBatteryNotity:(int)readerID aBatteryEvent:(srfidBatteryEvent*)batteryEvent
{
    // Thread is unknown
    NSLog(@"\nbatteryEvent: level = [%d] charging = [%d] cause = (%@)\n", [batteryEvent getPowerLevel], [batteryEvent getIsCharging], [batteryEvent getEventCause]);
    
    int battery = [batteryEvent getPowerLevel];
    
    if(battery > 100) battery = 100;
    else if(battery < 0) battery = 0;
    
    dispatch_async(dispatch_get_main_queue(),
                   ^{
                       _batteryLifeView.progress = battery/100.;
                       _batteryLifeLbl.backgroundColor =
                       (battery > 20)?UIColorFromRGB(0xA4CD39):
                       (battery > 5 )?UIColorFromRGB(0xCC9900):
                       UIColorFromRGB(0xCC0000);
                       
                       _batteryLifeLbl.text = [NSString stringWithFormat:@"RFID Battery Life: %d%%\n", battery];
                   });
}

/**
 None of these are really needed
 */
- (void)srfidEventReaderDisappeared:(int)readerID
{
    NSLog(@"Zebra Reader Disappeared - ID: %d\n", readerID);
}
- (void)srfidEventCommunicationSessionTerminated:(int)readerID
{
    NSLog(@"Zebra Reader Session Terminated - ID: %d\n", readerID);
}
- (void)srfidEventStatusNotify:(int)readerID aEvent:(SRFID_EVENT_STATUS)event aNotification:(id)notificationData
{
    NSLog(@"Zebra Reader - Event status notify: %d\n", event);
}
- (void)srfidEventProximityNotify:(int)readerID aProximityPercent:(int)proximityPercent
{
    NSLog(@"Zebra Reader - Event proximity nofity percent: %d\n", proximityPercent);
}
- (void)srfidEventTriggerNotify:(int)readerID aTriggerEvent:(SRFID_TRIGGEREVENT)triggerEvent
{
    NSLog(@"Zebra Reader - Event trigger notify: %@\n", ((triggerEvent == SRFID_TRIGGEREVENT_PRESSED)?@"Pressed":@"Released"));
}

/*
 #pragma mark - Navigation
 
 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
 }
 */

@end
