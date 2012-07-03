//
//  glue.cpp
//  Artnestopia
//
//  Created by arthur on 20/01/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#include <sys/stat.h>
#include <sys/types.h>
#include <errno.h>

#import <AudioToolbox/AudioQueue.h>
#import <AudioToolbox/AudioToolbox.h>

#import <UIKit/UIKit.h>
#import "ScreenView.h"
#import "SlotInputView.h"
#import "Helper.h"
#import "RootViewController.h"
#import "glue.h"

void audio_open(void);
void audio_close(void);

NSArray *loaded = nil;
int running = 0;

#define AUDIO_BUFFERS 3

typedef struct AQCallbackStruct {
    AudioQueueRef queue;
    UInt32 frameCount;
    AudioQueueBufferRef mBuffers[AUDIO_BUFFERS];
    AudioStreamBasicDescription mDataFormat;
} AQCallbackStruct;

AQCallbackStruct in;

int audio_is_initialized = 0;
int audio_do_not_initialize = 0;

pthread_t peplus_thread;
pthread_mutex_t peplus_mutex = PTHREAD_MUTEX_INITIALIZER;
pthread_cond_t peplus_cond = PTHREAD_COND_INITIALIZER;

static void audio_queue_callback(void *userdata,
                                 AudioQueueRef outQ,
                                 AudioQueueBufferRef outQB)
{
    outQB->mAudioDataByteSize = in.mDataFormat.mBytesPerFrame * in.frameCount;
    pthread_mutex_lock(&peplus_mutex);
    extern UINT16 samplebuffer[];
    extern int sampleindex;
    if (sampleindex <= 0) {
        memset(outQB->mAudioData, 0, outQB->mAudioDataByteSize);
    } else if (sampleindex >= 1600) {
        memcpy(outQB->mAudioData, samplebuffer, outQB->mAudioDataByteSize);
        for(int i=0; i<sampleindex-1600; i++) {
            samplebuffer[i] = samplebuffer[i+1600];
        }
        sampleindex -= 1600;
    } else {
        memset(outQB->mAudioData, 0, outQB->mAudioDataByteSize);
        memcpy(outQB->mAudioData, samplebuffer, sampleindex*2);
        sampleindex = 0;
    }
    pthread_mutex_unlock(&peplus_mutex);
    AudioQueueEnqueueBuffer(outQ, outQB, 0, NULL);
}


void audio_close()
{
    if(audio_is_initialized) {
        AudioQueueDispose(in.queue, true);
        audio_is_initialized = 0;
    }
}


void audio_open()
{
    if (audio_do_not_initialize)
        return;
    
    if (audio_is_initialized)
        return;
    
    memset (&in.mDataFormat, 0, sizeof (in.mDataFormat));
    in.mDataFormat.mSampleRate = 96000;
    in.mDataFormat.mFormatID = kAudioFormatLinearPCM;
    in.mDataFormat.mFormatFlags = kLinearPCMFormatFlagIsSignedInteger|kAudioFormatFlagIsPacked;
    in.mDataFormat.mBytesPerPacket = 2;
    in.mDataFormat.mFramesPerPacket = 1;
    in.mDataFormat.mBytesPerFrame = 2;
    in.mDataFormat.mChannelsPerFrame = 1;
    in.mDataFormat.mBitsPerChannel = 16;
    in.frameCount = 1600; // 44100.0 / 60.0;
    UInt32 err;
    err = AudioQueueNewOutput(&in.mDataFormat,
                              audio_queue_callback,
                              NULL,
                              CFRunLoopGetMain(),
                              kCFRunLoopDefaultMode,
                              0,
                              &in.queue);
    
    unsigned long bufsize;
    bufsize = in.frameCount * in.mDataFormat.mBytesPerFrame;
    
    for (int i=0; i<AUDIO_BUFFERS; i++) {
        err = AudioQueueAllocateBuffer(in.queue, bufsize, &in.mBuffers[i]);
        in.mBuffers[i]->mAudioDataByteSize = bufsize;
        AudioQueueEnqueueBuffer(in.queue, in.mBuffers[i], 0, NULL);
    }
    
    audio_is_initialized = 1;
    extern int sampleindex;
    sampleindex = 0;
    err = AudioQueueStart(in.queue, NULL);
}

void peplus_stop()
{
    if (!running)
        return;
    
    running = 0;
    if (pthread_join(peplus_thread, NULL)) {
        NSLog(@"error while waiting for pthread");
    }
    audio_close();
    save_nvram();
}

void *peplus_thread_main(void *ptr);
void *peplus_thread_main(void *ptr)
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    extern ScreenView *screenView;
    while (running) {
        extern void emu_execute_frame(void);
        emu_execute_frame();
        [screenView performSelectorOnMainThread:@selector(setNeedsDisplay) withObject:nil waitUntilDone:NO];
    }
    [pool drain];
    return NULL;
}

void peplus_continue()
{
    if (!loaded)
        return;
    if (running)
        return;
    audio_open();
    running = 1;
    pthread_create(&peplus_thread, NULL, peplus_thread_main, NULL);
}

void peplus_load(NSArray *game)
{
    load_game_roms(game);
    emu_init();
    load_nvram();
    audio_open();
    running = 1;
    pthread_create(&peplus_thread, NULL, peplus_thread_main, NULL);
}
