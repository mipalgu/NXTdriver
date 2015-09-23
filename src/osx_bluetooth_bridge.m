#import <Foundation/Foundation.h>
#import <Foundation/NSObject.h>
#import <IOBluetooth/objc/IOBluetoothDevice.h>
#import <IOBluetooth/objc/IOBluetoothDeviceInquiry.h>
#import <IOBluetooth/objc/IOBluetoothRFCOMMChannel.h>
#import "osx_bluetooth_bridge.h"

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wobjc-interface-ivars"

@interface Discoverer: NSObject {
void (*func)(const BluetoothDeviceAddress *, void *);
void *context;
}
-(Discoverer*) initWithCallback: (void (*)(const BluetoothDeviceAddress *, void*)) f context: (void *) ctx;

-(void) deviceInquiryComplete: (IOBluetoothDeviceInquiry*) sender 
                            error: (IOReturn) error
                            aborted: (BOOL) aborted;
-(void) deviceInquiryDeviceFound: (IOBluetoothDeviceInquiry*) sender
                            device: (IOBluetoothDevice*) device;
@end


@implementation Discoverer
-(Discoverer*) initWithCallback: (void (*)(const BluetoothDeviceAddress *, void*)) f context: (void *) ctx {
    self = [super init];

    if (self) {
        self->func = f;
        self->context = ctx;
    }

    return self;
}

-(void) deviceInquiryComplete: (IOBluetoothDeviceInquiry*) sender
                            error: (IOReturn) error
                            aborted: (BOOL) aborted
{
    (void) sender;
    (void) aborted;
    (void) error;
    CFRunLoopStop( CFRunLoopGetCurrent() );
}


#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdirect-ivar-access"

-(void) deviceInquiryDeviceFound: (IOBluetoothDeviceInquiry*) sender
                            device: (IOBluetoothDevice*) device
{
    (void) sender;

    const BluetoothDeviceAddress *addr = [device getAddress];

    if (addr->data[0] == 0x00 && addr->data[1] == 0x16 && addr->data[2] == 0x53) {
        // Lego NXT found
        func(addr, self->context);
    }
}

@end


@interface TrafficHandler : NSObject {
BOOL response;
}
- (TrafficHandler*) initWithResponse: (BOOL)r;
- (void)rfcommChannelData:(IOBluetoothRFCOMMChannel*)channel 
                     data:(void *)dataPointer 
                   length:(size_t)dataLength;
- (void)rfcommChannelWriteComplete:(IOBluetoothRFCOMMChannel*) channel
                            refcon:(void*)refcon
                            status:(IOReturn) error;
@property (readonly, nonatomic) NSData *message;
@end


@implementation TrafficHandler {
NSMutableData *receivedData;
BOOL processingMessage;
size_t messageLength;
}

@synthesize message=_message;

-(TrafficHandler*) initWithResponse: (BOOL)r {
    self = [super init];

    if (self) {
        self->response = r;
        self->processingMessage = FALSE;
        self->receivedData = [[NSMutableData alloc] init];
    }
    return self;
}

- (void)saveBuffer:(char *)dataPointer
            length:(size_t)dataLength  {
    if (!processingMessage) {
        messageLength = dataPointer[0];
        processingMessage = TRUE;

        NSData *data = [NSData dataWithBytes: dataPointer length: dataLength];
        [receivedData appendData:[data subdataWithRange:NSMakeRange(2, [data length] - 2)]];
    } else {
        NSData *data = [NSData dataWithBytes: dataPointer length: dataLength];
        [receivedData appendData:data];
    }

    if (messageLength == [receivedData length]) {

        //_message = [NSData dataWithData:receivedData];
        _message = [receivedData copy];
        CFRunLoopStop( CFRunLoopGetCurrent() );
    }
}

- (void)rfcommChannelWriteComplete:(IOBluetoothRFCOMMChannel*) channel
                            refcon:(void*)refcon
                            status:(IOReturn) error
{
    (void)channel;
    (void)refcon;
    (void)error;

    if(!(self->response)) {
        // Not waiting for a response, stop loop
        CFRunLoopStop( CFRunLoopGetCurrent() );
    }
}

- (void)rfcommChannelData:(IOBluetoothRFCOMMChannel*)channel 
                     data:(void *)dataPointer 
                   length:(size_t)dataLength
{
    (void)channel;
    [self saveBuffer:dataPointer length:dataLength];
}
@end


@interface ConnectionHandler : NSObject {
}
- (void)rfcommChannelOpenComplete:(IOBluetoothRFCOMMChannel*)chan 
                           status:(IOReturn)status;
@end


@implementation ConnectionHandler
- (void)rfcommChannelOpenComplete:(IOBluetoothRFCOMMChannel*)chan 
                           status:(IOReturn)status
{
    (void)chan;
    (void)status;
/*
    if( kIOReturnSuccess == status ) {
        [self setChannel: channel];
    }
*/
    CFRunLoopStop( CFRunLoopGetCurrent() );
}
@end


void r2d2_bt_scan(void (*f)(const BluetoothDeviceAddress *, void *), void *arg)
{
    @autoreleasepool
    {
        Discoverer *d = [[Discoverer alloc] initWithCallback: f context: arg];
        
        IOBluetoothDeviceInquiry *bdi = [[IOBluetoothDeviceInquiry alloc] init];
        [bdi setDelegate: d];
        
        [bdi start];
        
        CFRunLoopRun();
    }
}

IOBluetoothRFCOMMChannelRef r2d2_bt_open_channel(const BluetoothDeviceAddress *addr)
{
    @autoreleasepool
    {
        IOBluetoothDevice *remote_device =
        [IOBluetoothDevice deviceWithAddress:addr];
        IOBluetoothRFCOMMChannel *chan;
        ConnectionHandler *handler = [[ConnectionHandler alloc] init];
        
        [remote_device openRFCOMMChannelAsync:&chan withChannelID:1
                                     delegate: handler];
        
        CFRunLoopRun();
        
        IOBluetoothRFCOMMChannelRef refchan = [chan getRFCOMMChannelRef];
        //    [handler release];
        return refchan;
    }
}

void r2d2_bt_write(IOBluetoothRFCOMMChannelRef refchan, void *datain, size_t length, void *responseBuffer, size_t *responseLength)
{
    @autoreleasepool
    {
        char *data = datain;
        
        BOOL response = (data[2] == 0x00 || data[2] == 0x01);
        
        TrafficHandler *handler =
        [[TrafficHandler alloc] initWithResponse: response];
        
        IOBluetoothRFCOMMChannel *channel = [IOBluetoothRFCOMMChannel withRFCOMMChannelRef: refchan];
        
        [channel setDelegate: handler];
        
        [channel writeAsync: data length: (unsigned short) length refcon: NULL];
        
        CFRunLoopRun();
        
        size_t messageLength = [handler.message length];
        //unsigned char str[messageLength];
        
        [handler.message getBytes:responseBuffer length:messageLength];
        
        *responseLength = messageLength;
    }
}

#pragma clang diagnostic pop
#pragma clang diagnostic pop

