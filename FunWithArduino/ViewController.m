//
//  ViewController.m
//  FunWithArduino
//
//  Created by Konrad Feiler on 17/01/16.
//  Copyright © 2016 Konrad Feiler. All rights reserved.
//

#import "ViewController.h"
#import <ORSSerial/ORSSerial.h>

@interface ViewController () <ORSSerialPortDelegate>

@property (nonatomic,strong) ORSSerialPort* serialPort;
@property (weak) IBOutlet NSImageView *arduinoIconView;
@property (weak) IBOutlet NSImageView *lightIconView;
@property (weak) IBOutlet NSTextField *temperatureLabel;
@property (weak) IBOutlet NSTextField *humidityLabel;

@property (nonatomic, strong) ORSSerialPacketDescriptor* potiDescriptor;
@property (nonatomic, strong) ORSSerialPacketDescriptor* lightDescriptor;
@property (nonatomic, strong) ORSSerialPacketDescriptor* humidityDescriptor;
@property (nonatomic, strong) ORSSerialPacketDescriptor* temperatureDescriptor;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    // Do any additional setup after loading the view.
    
    NSLog(@"Available ports: %@", [ORSSerialPortManager sharedSerialPortManager].availablePorts);
    
    self.serialPort = [ORSSerialPort serialPortWithPath:@"/dev/tty.usbmodem1431"];
    
    self.potiDescriptor = [[ORSSerialPacketDescriptor alloc] initWithPrefixString:@"poti =" suffixString:@";" maximumPacketLength:14 userInfo:nil];
    self.lightDescriptor = [[ORSSerialPacketDescriptor alloc] initWithPrefixString:@"light =" suffixString:@";" maximumPacketLength:15 userInfo:nil];
    self.humidityDescriptor = [[ORSSerialPacketDescriptor alloc] initWithPrefixString:@"humi =" suffixString:@";" maximumPacketLength:15 userInfo:nil];
    self.temperatureDescriptor = [[ORSSerialPacketDescriptor alloc] initWithPrefixString:@"temp =" suffixString:@";" maximumPacketLength:15 userInfo:nil];

    self.serialPort.baudRate = @9600; //
    [self.serialPort open];
//    [serialPort sendData:someData]; // someData is an NSData object
    
    [self.serialPort startListeningForPacketsMatchingDescriptor:self.potiDescriptor];
    [self.serialPort startListeningForPacketsMatchingDescriptor:self.lightDescriptor];
    [self.serialPort startListeningForPacketsMatchingDescriptor:self.humidityDescriptor];
    [self.serialPort startListeningForPacketsMatchingDescriptor:self.temperatureDescriptor];

    self.serialPort.delegate = self;
    
    
    NSLog(@"self.serialPort: %@", self.serialPort);

}

- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];

    // Update the view, if already loaded.
}

- (void)viewWillDisappear {
    [super viewWillDisappear];
    
    [self.serialPort close]; // Later, when you're done with the port
}


//- (void)serialPort:(ORSSerialPort *)serialPort didReceiveData:(NSData *)data
//{
//    NSLog(@"data: %@", data);
//    
//    NSString *asciString = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
//
//    
//    NSLog(@"asciString: %@", asciString);
//    
//    
//    NSString *string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
//    
//    NSLog(@"Received string: %@", string);
//    
////    [self.receivedDataTextView.textStorage.mutableString appendString:string];
////    [self.receivedDataTextView setNeedsDisplay:YES];
//}

- (void)serialPort:(ORSSerialPort *)serialPort didReceivePacket:(NSData *)packetData matchingDescriptor:(ORSSerialPacketDescriptor *)descriptor {
    
    NSString *asciString = [[NSString alloc] initWithData:packetData encoding:NSASCIIStringEncoding];
    NSLog(@"package[asci]: %@", asciString);

    if (descriptor == self.potiDescriptor) {
        NSString* numberString = [[asciString substringToIndex:asciString.length-1] substringFromIndex:7];
    
        double pos = [numberString doubleValue]/1023.0;
        
//        NSLog(@"poti as double: %f", pos);
        
        [self moveBoxToFloat:pos];
    }
    else if (descriptor == self.lightDescriptor) {
        NSString* numberString = [[asciString substringToIndex:asciString.length-1] substringFromIndex:8];

        double alpha = [numberString doubleValue]/255.0;

        NSLog(@"light as double: %f", alpha);

        [self changeLightIntensity:alpha];
    }
    else if (descriptor == self.humidityDescriptor) {
        NSString* numberString = [[asciString substringToIndex:asciString.length-1] substringFromIndex:7];
        
        double humidity = [numberString doubleValue];
        
//        NSLog(@"humidity as double: %f", humidity);
        
        [self changeUIHumidity:humidity];
    }
    else if (descriptor == self.temperatureDescriptor) {
        NSString* numberString = [[asciString substringToIndex:asciString.length-1] substringFromIndex:7];
        
        double temperature = [numberString doubleValue];
        
//        NSLog(@"temperature as double: %f", temperature);
        
        [self changeUITemperature:temperature];
    }
}

-(void)serialPort:(ORSSerialPort *)serialPort didEncounterError:(NSError *)error {
    NSLog(@"error: %@", error);
    
}

-(void)serialPortWasRemovedFromSystem:(ORSSerialPort *)serialPort {
    
    NSLog(@"Removed from system: %@", serialPort);
}

#pragma mark UI

- (void)moveBoxToFloat:(double)newPos {

    CGRect f = self.arduinoIconView.frame;

    CGFloat maxY = self.arduinoIconView.superview.frame.size.height - f.size.height;
    
    f.origin.y = maxY*newPos;
    
    self.arduinoIconView.frame = f;
}

- (void)changeLightIntensity:(double)newAlpha {
    
    self.lightIconView.alphaValue = newAlpha;
}

- (void)changeUITemperature:(double)temp {
    [self.temperatureLabel setStringValue:[NSString stringWithFormat:@"%.1f°", temp]];
}

- (void)changeUIHumidity:(double)humi {
    [self.humidityLabel setStringValue:[NSString stringWithFormat:@"%.1f%%", humi]];
    
}


- (IBAction)ledButtonPressed:(id)sender {
    
    NSData *dataToSend = [@"H\n" dataUsingEncoding:NSASCIIStringEncoding];
    [self.serialPort sendData:dataToSend];
}

- (IBAction)servoButtonPressed:(id)sender {
    
    NSData *dataToSend = [@"S\n" dataUsingEncoding:NSASCIIStringEncoding];
    [self.serialPort sendData:dataToSend];
}

- (IBAction)sliderChangedValue:(id)sender {
    NSSlider* slider = (NSSlider*)sender;
    
    NSLog(@"Slider pos: %i", slider.intValue);
    
    int newValue = ((int)slider.maxValue - slider.intValue);
    NSData *dataToSend = [[NSString stringWithFormat:@"S,%i,\n", newValue] dataUsingEncoding:NSASCIIStringEncoding];
    [self.serialPort sendData:dataToSend];
    
}

@end
