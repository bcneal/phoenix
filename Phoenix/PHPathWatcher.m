//
//  LVPathWatcher.m
//  Leviathan
//
//  Created by Steven Degutis on 11/6/13.
//  Copyright (c) 2013 Steven Degutis. All rights reserved.
//

#import "PHPathWatcher.h"

@interface PHPathWatcher ()

@property FSEventStreamRef stream;
@property (copy) void(^handler)();
@property NSString *path;

@end

@implementation PHPathWatcher

void fsEventsCallback(ConstFSEventStreamRef streamRef, void *clientCallBackInfo, size_t numEvents, void *eventPaths, const FSEventStreamEventFlags eventFlags[], const FSEventStreamEventId eventIds[])
{
    PHPathWatcher* watcher = (__bridge PHPathWatcher*)clientCallBackInfo;
    [watcher fileChanged];
}

- (void) dealloc {
    if (self.stream) {
        FSEventStreamStop(self.stream);
        FSEventStreamInvalidate(self.stream);
        FSEventStreamRelease(self.stream);
    }
}

+ (PHPathWatcher*) watcherFor:(NSString*)path handler:(void(^)())handler {
    PHPathWatcher* watcher = [[PHPathWatcher alloc] init];
    watcher.handler = handler;
    watcher.path = path;
    [watcher setup];
    return watcher;
}

- (void) setup {
    FSEventStreamContext context;
    context.info = (__bridge void*)self;
    context.version = 0;
    context.retain = NULL;
    context.release = NULL;
    context.copyDescription = NULL;
    self.stream = FSEventStreamCreate(NULL,
                                      fsEventsCallback,
                                      &context,
                                      (__bridge CFArrayRef)@[[self.path stringByStandardizingPath]],
                                      kFSEventStreamEventIdSinceNow,
                                      0.4,
                                      kFSEventStreamCreateFlagWatchRoot | kFSEventStreamCreateFlagNoDefer | kFSEventStreamCreateFlagFileEvents);
    FSEventStreamScheduleWithRunLoop(self.stream, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
    FSEventStreamStart(self.stream);
}

- (void) fileChanged {
    self.handler();
}

@end
